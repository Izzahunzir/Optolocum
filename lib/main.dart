import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'features/intro/intro_page.dart';
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
      // Persisted Firebase identity is not proof of current trusted access.
      await FirebaseAuth.instanceFor(app: app).signOut();
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const IntroPage(),
    );
  }
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
