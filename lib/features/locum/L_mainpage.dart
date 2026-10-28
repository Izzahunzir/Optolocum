import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:optolocum/services/job_service.dart';
import 'package:optolocum/services/locum_profile_service.dart';

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

export 'L_profile_data.dart'
    show LocumVerificationStatus, locumVerificationStatus;

class LMainPage extends StatefulWidget {
  const LMainPage({super.key, this.jobsStream});

  final Stream<QuerySnapshot<Map<String, dynamic>>>? jobsStream;

  @override
  State<LMainPage> createState() => _LMainPageState();
}

class _LMainPageState extends State<LMainPage> {
  int _tab = 0;
  bool _showContactUs = false;
  bool _showSavedJobs = false;
  bool _searching = false;
  String _filter = 'All jobs';
  final _search = TextEditingController();
  late final _jobsStream = widget.jobsStream ?? JobService().getAvailableJobs();
  List<String> _locations = const [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    try {
      await LocumProfileService.instance.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
      return;
    }
    if (!mounted) return;
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
                              onPressed: () => setState(() {
                                _searching = !_searching;
                                if (!_searching) {
                                  _search.clear();
                                  FocusScope.of(context).unfocus();
                                }
                              }),
                              icon: const Icon(Icons.search),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Filter jobs',
                              initialValue: _filter,
                              onSelected: (value) =>
                                  setState(() => _filter = value),
                              itemBuilder: (_) => ['All jobs', ..._locations]
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
                          TextField(
                            controller: _search,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search jobs',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(_search.clear),
                              ),
                            ),
                          ),
                        if (_filter != 'All jobs')
                          Chip(
                            label: Text(_filter),
                            onDeleted: () =>
                                setState(() => _filter = 'All jobs'),
                          ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          key: const ValueKey('locum-job-results'),
                          stream: _jobsStream,
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
                            final allJobs = snapshot.data!.docs;
                            _locations =
                                allJobs
                                    .map(
                                      (doc) => (doc.data()['location'] ?? '')
                                          .toString()
                                          .trim(),
                                    )
                                    .where(
                                      (location) =>
                                          location.isNotEmpty &&
                                          location != 'All jobs',
                                    )
                                    .toSet()
                                    .toList()
                                  ..sort();
                            final query = _search.text.trim().toLowerCase();
                            final jobs = allJobs.where((doc) {
                              final job = doc.data();
                              return (_filter == 'All jobs' ||
                                      (job['location'] ?? '')
                                              .toString()
                                              .trim() ==
                                          _filter) &&
                                  [
                                    'role',
                                    'placeName',
                                    'location',
                                    'jobDescription',
                                  ].any(
                                    (key) => (job[key] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(query),
                                  );
                            }).toList();
                            if (jobs.isEmpty) {
                              return Text(
                                allJobs.isEmpty
                                    ? 'No jobs available'
                                    : 'No matching jobs',
                              );
                            }
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
