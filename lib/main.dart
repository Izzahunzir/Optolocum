import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'firebase_options.dart';
import 'features/intro/intro_page.dart';
import 'features/locum/L_verify_popup.dart';
import 'features/locum/L_savedJob.dart';
import 'features/locum/L_profile_data.dart';
import 'features/clinic_owner/CO_verify_popup.dart';
import 'features/clinic_owner/CO_verification_status.dart';
import 'services/verification_status_sync.dart';
import 'services/demo_enrollment.dart';
import 'services/real_backend_client.dart';
import 'services/real_backend_workflows.dart';
import 'services/backend_http_platform.dart';

import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (demoEnrollmentEnabled && realBackendEnabled) {
    throw StateError(
      'Real backend and isolated demo cannot be enabled together.',
    );
  }

  if (demoEnrollmentEnabled) {
    if (!kIsWeb || Uri.base.origin != 'http://localhost:5174') {
      throw StateError(
        'Isolated demo requires Chrome at http://localhost:5174.',
      );
    }
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: 'demo-app',
        messagingSenderId: '123456789',
        projectId: demoProjectId,
      ),
    );
    await FirebaseAuth.instanceFor(app: app)
        .useAuthEmulator('127.0.0.1', 19099);
    FirebaseFirestore.instanceFor(app: app)
        .useFirestoreEmulator('127.0.0.1', 18080);
    DemoEnrollment.configure(app);
  } else {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (realBackendEnabled) {
      const url = String.fromEnvironment('OPT_BACKEND_URL');
      final config = RealBackendConfig(
        baseUrl: url,
        projectId: app.options.projectId,
        emulatorEnabled: demoEnrollmentEnabled,
      );
      realBackendWorkflows = RealBackendWorkflows(
        RealBackendClient(config, client: createBackendHttpClient()),
        FirebaseAuth.instanceFor(app: app),
        FirebaseFirestore.instanceFor(app: app),
      );
    }
  }
  VerificationStatusSync(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  ).start();

  runApp(MyApp(workflows: realBackendWorkflows));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.workflows});
  final RealBackendWorkflows? workflows;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optolocum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237F7D)),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const _DirectPageTransitionBuilder(),
          },
        ),
      ),
      home: workflows == null
          ? const IntroPage()
          : RealSessionStartup(workflows: workflows!),
    );
  }
}

/// Waits for Firebase persistence and trusted validation before choosing a home.
class RealSessionStartup extends StatefulWidget {
  const RealSessionStartup({
    super.key,
    required this.workflows,
    this.homeBuilder,
    this.introBuilder,
  });
  final RealBackendWorkflows workflows;
  final Widget Function(BuildContext, String)? homeBuilder;
  final WidgetBuilder? introBuilder;

  @override
  State<RealSessionStartup> createState() => _RealSessionStartupState();
}

class _RealSessionStartupState extends State<RealSessionStartup> {
  late final Future<({String uid, String accountType})?> _restoration;
  StreamSubscription<User?>? _accountWatcher;
  bool _errorShown = false;
  bool _restoredInvalidated = false;

  @override
  void initState() {
    super.initState();
    _restoration = _restore();
  }

  Future<({String uid, String accountType})?> _restore() async {
    await widget.workflows.auth.authStateChanges().first;
    if (!mounted) return null;
    _accountWatcher = widget.workflows.watchAccountChanges(
      onValidatedAccountChanged: () {
        _restoredInvalidated = true;
        locumSavedJobs.clear();
        locumProfileData.value = null;
        locumVerificationStatus.value = LocumVerificationStatus.unverified;
        coVerificationStatus.value = COVerificationStatus.unverified;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        });
      },
    );
    return widget.workflows.restoreSession();
  }

  @override
  void dispose() {
    _accountWatcher?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<({String uid, String accountType})?>(
        future: _restoration,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError && !_errorShown) {
            _errorShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final error = snapshot.error;
              final message = error is BackendException
                  ? error.message
                  : 'Session could not be restored. Please sign in again.';
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
            });
          }
          final restored = snapshot.data;
          if (restored == null) {
            return widget.introBuilder?.call(context) ?? const IntroPage();
          }
          return StreamBuilder<User?>(
            stream: widget.workflows.auth.authStateChanges(),
            builder: (context, authSnapshot) {
              if (_restoredInvalidated ||
                  widget.workflows.auth.currentUser?.uid != restored.uid) {
                return widget.introBuilder?.call(context) ?? const IntroPage();
              }
              return widget.homeBuilder?.call(context, restored.accountType) ??
                  (restored.accountType == 'locum'
                      ? const LVerifyPopup()
                      : const COVerifyPopup());
            },
          );
        },
      );
}

class _DirectPageTransitionBuilder extends PageTransitionsBuilder {
  const _DirectPageTransitionBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
