import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:optolocum/services/job_service.dart';

import '../../widgets/advertisement_strip.dart';
import '../../widgets/logout_dialog.dart';
import '../intro/intro_page.dart';

import 'L_jobstatus.dart';
import 'L_jobDetails.dart';
import 'L_applyJobDialog.dart';
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
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: JobService().getAvailableJobs(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Failed to load jobs: ${snapshot.error}',
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final jobs = snapshot.data!.docs;
                            return Column(
                              children: jobs.map((doc) {
                                return LocumJobCard(
                                  jobId: doc.id,
                                  job: doc.data(),
                                );
                              }).toList(),
                            );
                          },
                        ),
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

class LocumJobCard extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> job;

  const LocumJobCard({super.key, required this.jobId, required this.job});

  @override
  Widget build(BuildContext context) {
    final rawDate = job['jobDate'];
    final date = rawDate is Timestamp ? rawDate.toDate() : null;
    final formattedDate = date == null
        ? 'Date not available'
        : '${date.day}/${date.month}/${date.year}';
    final startTime = job['startTime'] ?? '-';
    final endTime = job['endTime'] ?? '-';
    final payUnit = job['payRateUnit'] == 'per_hour'
        ? '/hour'
        : job['payRateUnit'] == 'per_day'
        ? '/day'
        : '/shift';

    const iconColor = Color(0xFF17213D);
    const greenColor = Color(0xFF248783);

    Widget infoRow(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 23),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF6F4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job['role'] ?? 'Optometrist',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Connect Saved Jobs functionality
                },
                icon: const Icon(
                  Icons.bookmark_border,
                  size: 30,
                  color: iconColor,
                ),
              ),
            ],
          ),
          infoRow(Icons.store, job['placeName'] ?? 'Unknown Clinic'),
          infoRow(
            Icons.location_on_outlined,
            job['location'] ?? 'Location not available',
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: iconColor,
                  size: 23,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.access_time, color: iconColor, size: 23),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$startTime - $endTime',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          infoRow(
            Icons.account_balance_wallet_outlined,
            'RM ${job['payRate'] ?? 0}$payUnit',
          ),
          const SizedBox(height: 8),
          infoRow(
            Icons.person_outline,
            job['contactPerson'] ?? 'Contact person unavailable',
          ),
          infoRow(
            Icons.phone_outlined,
            job['contactNumber'] ?? 'Contact unavailable',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LJobDetails(jobId: jobId, job: job),
                      ),
                    );
                  },
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: greenColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showApplyJobDialog(
                      context: context,
                      jobId: jobId,
                      jobTitle: job['role'] ?? 'Optometrist',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
