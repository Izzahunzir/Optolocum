import 'package:flutter/material.dart';

import '../../widgets/advertisement_strip.dart';
import '../../widgets/logout_dialog.dart';
import '../intro/intro_page.dart';

import 'L_jobstatus.dart';
import 'L_notifications.dart';
import 'L_profile.dart';
import 'L_contactUs.dart';
import 'L_savedJob.dart';
import 'L_profile_data.dart';

enum LocumVerificationStatus { unverified, pending, verified }

/// Set verified only from the account service after document review.
final locumVerificationStatus = ValueNotifier(
  LocumVerificationStatus.unverified,
);

class LMainPage extends StatefulWidget {
  const LMainPage({super.key});

  @override
  State<LMainPage> createState() => _LMainPageState();
}

class _LMainPageState extends State<LMainPage> {
  int _tab = 0;
  bool _showContactUs = false;
  bool _showSavedJobs = false;
  bool _searching = false;
  String _filter = 'All jobs';
  static const _tabs = [
    'Home',
    'Job Status',
    'Notifications',
    'Payment History',
    'Account',
  ];

  void _closeAccountPage() => setState(() {
    _showContactUs = false;
    _showSavedJobs = false;
  });

  Future<void> _logout() async {
    final confirmed = await showLogoutDialog(context);
    if (confirmed != true || !mounted) return;
    locumVerificationStatus.value = LocumVerificationStatus.unverified;
    locumSavedJobs.clear();
    locumProfileData.value = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const IntroPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FCFB),
    body: SafeArea(
      child: _tab == 1
          ? const LJobStatus()
          : _tab == 2
          ? const LNotifications()
          : _tab == 4
          ? _showContactUs || _showSavedJobs
                ? PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (!didPop) _closeAccountPage();
                    },
                    child: _showSavedJobs
                        ? LSavedJob(onBack: _closeAccountPage)
                        : LContactUs(onBack: _closeAccountPage),
                  )
                : LProfile(
                    onLogout: _logout,
                    onContactUs: () => setState(() => _showContactUs = true),
                    onSavedJobs: () => setState(() => _showSavedJobs = true),
                  )
          : ValueListenableBuilder<LocumVerificationStatus>(
              valueListenable: locumVerificationStatus,
              builder: (context, status, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: _tab == 0
                    ? [
                        const Text(
                          'My Applications',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const AdvertisementStrip(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Job Recommendations',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Search jobs',
                              onPressed: () =>
                                  setState(() => _searching = !_searching),
                              icon: const Icon(Icons.search),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Filter jobs',
                              initialValue: _filter,
                              onSelected: (value) =>
                                  setState(() => _filter = value),
                              itemBuilder: (_) =>
                                  ['All jobs', 'Nearby', 'Part time']
                                      .map(
                                        (value) => PopupMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                              icon: const Icon(Icons.filter_alt),
                            ),
                          ],
                        ),
                        if (_searching)
                          const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search jobs',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        if (_filter != 'All jobs') Chip(label: Text(_filter)),
                        if (status == LocumVerificationStatus.pending)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'Your account verification is pending review.',
                            ),
                          ),
                      ]
                    : [
                        Text(
                          _tabs[_tab],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Track your earnings and payments updates'),
                      ],
              ),
            ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF237F7D),
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color(0xFF052F2E),
      selectedFontSize: 10,
      unselectedFontSize: 10,
      currentIndex: _tab,
      onTap: (index) => setState(() {
        _tab = index;
        _showContactUs = false;
        _showSavedJobs = false;
      }),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          label: 'Job Status',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payments_outlined),
          label: 'Payments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          label: 'Account',
        ),
      ],
    ),
  );
}
