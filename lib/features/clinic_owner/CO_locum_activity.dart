import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/application_service.dart';

import 'CO_mainpage.dart';
import 'CO_navigation.dart';
import 'CO_profile.dart';

enum COLocumActivityStatus { pending, current, completed }

/// An application joined with its applicant and clinic-owned job posting.
class COLocumApplication {
  const COLocumApplication({
    required this.id,
    required this.jobId,
    required this.clinicOwnerId,
    required this.status,
    required this.name,
    required this.qualification,
    required this.jobDate,
    required this.time,
    required this.location,
    required this.position,
    this.timestamp = '',
    this.locumId = '',
    this.appliedAt,
    this.rating,
    this.reviewCount = 0,
    this.avatarUrl,
  });
  final String id,
      jobId,
      clinicOwnerId,
      name,
      qualification,
      jobDate,
      time,
      location,
      position,
      timestamp;
  final COLocumActivityStatus status;
  final String locumId;
  final DateTime? appliedAt;
  final double? rating;
  final int reviewCount;
  final String? avatarUrl;
}

class COLocumActivity extends StatelessWidget {
  const COLocumActivity({
    super.key,
    this.clinicOwnerId,
    this.applications = const [],
    this.onApprove,
    this.onReject,
    this.onMessage,
  });
  // Retained for source compatibility. Live data always uses the authenticated
  // owner; supplied applications and action callbacks are not used.
  final String? clinicOwnerId;
  final List<COLocumApplication> applications;

  /// Reserved for future backend integration; all actions remain disabled.
  final ValueChanged<COLocumApplication>? onApprove, onReject, onMessage;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.hasError) {
        return _page(context, error: 'Unable to verify your session.');
      }
      if (auth.connectionState == ConnectionState.waiting) {
        return _page(context, loading: true);
      }
      final user = auth.data;
      if (user == null) {
        return _page(context, error: 'Please sign in to view applications.');
      }
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        key: ValueKey(user.uid),
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('clinicOwnerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) => _page(
          context,
          documents: snapshot.data?.docs ?? const [],
          loading: snapshot.connectionState == ConnectionState.waiting,
          error: snapshot.hasError
              ? 'Unable to load applications. Please try again later.'
              : null,
        ),
      );
    },
  );

  Widget _page(
    BuildContext context, {
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents = const [],
    bool loading = false,
    String? error,
  }) => DefaultTabController(
    length: 3,
    child: Scaffold(
      backgroundColor: const Color(0xFFF2FAFE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Locum Activity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B4E92),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Material(
            color: Color(0xFFF2FAFE),
            child: TabBar(
              labelColor: Color(0xFF263C80),
              unselectedLabelColor: Color(0xFF263C80),
              indicatorColor: Color(0xFFFFAD45),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Current'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: COLocumActivityStatus.values.map((status) {
                if (error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error, textAlign: TextAlign.center),
                    ),
                  );
                }
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final storedStatus = switch (status) {
                  COLocumActivityStatus.pending => 'pending',
                  COLocumActivityStatus.current => 'hired',
                  COLocumActivityStatus.completed => 'completed',
                };
                final items = documents
                    .where((doc) => doc.data()['status'] == storedStatus)
                    .toList();
                if (items.isEmpty) {
                  final message = switch (status) {
                    COLocumActivityStatus.pending =>
                      'No pending applications yet',
                    COLocumActivityStatus.current =>
                      'No current locum jobs yet',
                    COLocumActivityStatus.completed =>
                      'No completed locum jobs yet',
                  };
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.person_rounded,
                              size: 96,
                              color: Color(0xFF262261),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF777777)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _FirestoreApplicationCard(
                        key: ValueKey(items[index].id),
                        document: items[index],
                        status: status,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CONavigation(
        locumSelected: true,
        onLocum: () {},
        onHome: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const COMainPage()),
          (route) => route.isFirst,
        ),
        onProfile: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const COProfile()),
        ),
      ),
    ),
  );
}

String _text(dynamic value, String fallback) =>
    value is String && value.trim().isNotEmpty ? value : fallback;

class _FirestoreApplicationCard extends StatelessWidget {
  const _FirestoreApplicationCard({
    super.key,
    required this.document,
    required this.status,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final COLocumActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final jobId = _text(data['jobId'], '');
    if (jobId.isEmpty) return _card(context, data, null, 'Job unavailable');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('job_postings')
          .doc(jobId)
          .snapshots(),
      builder: (context, snapshot) {
        final job = snapshot.data?.data();
        final ownedJob =
            job != null && job['clinicOwnerId'] == data['clinicOwnerId']
            ? job
            : null;
        final fallback = snapshot.hasError
            ? 'Unable to load job'
            : snapshot.connectionState == ConnectionState.waiting
            ? 'Loading job…'
            : 'Job unavailable';
        return _card(
          context,
          data,
          snapshot.hasError ? null : ownedJob,
          fallback,
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic>? job,
    String fallback,
  ) {
    final locumId = _text(data['locumId'], '');
    if (locumId.isEmpty) {
      return _applicantCard(
        context,
        data,
        job,
        fallback,
        ApplicantSummary.fromFirestore(null),
      );
    }
    return StreamBuilder<ApplicantSummary>(
      key: ValueKey('${document.id}:$locumId'),
      stream: ApplicationService().watchApplicantSummary(
        applicationId: document.id,
        locumId: locumId,
      ),
      builder: (context, snapshot) => _applicantCard(
        context,
        data,
        job,
        fallback,
        snapshot.hasError
            ? ApplicantSummary.fromFirestore(null)
            : snapshot.data ?? ApplicantSummary.fromFirestore(null),
        profileError: snapshot.hasError,
        profileLoading: snapshot.connectionState == ConnectionState.waiting,
      ),
    );
  }

  Widget _applicantCard(
    BuildContext context,
    Map<String, dynamic> data,
    Map<String, dynamic>? job,
    String fallback,
    ApplicantSummary applicant, {
    bool profileError = false,
    bool profileLoading = false,
  }) {
    final localizations = MaterialLocalizations.of(context);
    final appliedAt = data['appliedAt'];
    final date = job?['jobDate'];
    final start = _text(job?['startTime'], '');
    final end = _text(job?['endTime'], '');
    return _ApplicationCard(
      application: COLocumApplication(
        id: document.id,
        jobId: _text(data['jobId'], ''),
        clinicOwnerId: _text(data['clinicOwnerId'], ''),
        locumId: _text(data['locumId'], ''),
        status: status,
        appliedAt: appliedAt is Timestamp ? appliedAt.toDate() : null,
        timestamp: appliedAt is Timestamp
            ? 'Applied on ${localizations.formatMediumDate(appliedAt.toDate())}'
            : 'Application date unavailable',
        name: profileError
            ? 'Applicant profile unavailable'
            : profileLoading
            ? 'Loading applicant...'
            : applicant.displayName,
        qualification: applicant.selfReportedQualification,
        jobDate: date is Timestamp
            ? localizations.formatMediumDate(date.toDate())
            : fallback,
        time: start.isNotEmpty && end.isNotEmpty ? '$start - $end' : fallback,
        location: _text(job?['location'], fallback),
        position: _text(job?['role'], fallback),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final COLocumApplication application;

  @override
  Widget build(BuildContext context) {
    final applicant = application;
    Widget detail(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
    Widget action(
      String label,
      IconData icon,
      Color color,
      ValueChanged<COLocumApplication>? callback,
    ) => OutlinedButton.icon(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: callback == null ? Colors.grey.shade300 : color,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (applicant.timestamp.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  applicant.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ClipOval(
                    child: applicant.avatarUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFECEDF6),
                            child: Icon(
                              Icons.person,
                              size: 36,
                              color: Color(0xFF263C80),
                            ),
                          )
                        : Image.network(
                            applicant.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                const Icon(Icons.person, size: 36),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        applicant.qualification,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (applicant.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 15,
                              color: Color(0xFFFFBC00),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${applicant.rating!.toStringAsFixed(1)} (${applicant.reviewCount} reviews)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            detail(
              Icons.calendar_today_outlined,
              'Job Date',
              applicant.jobDate,
            ),
            detail(Icons.access_time, 'Time', applicant.time),
            detail(Icons.location_on_outlined, 'Location', applicant.location),
            detail(Icons.description_outlined, 'Position', applicant.position),
            const SizedBox(height: 8),
            if (applicant.status == COLocumActivityStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: action('Reject', Icons.close, Colors.red, null),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: action(
                      'Approve',
                      Icons.check,
                      const Color(0xFF00A83B),
                      null,
                    ),
                  ),
                ],
              )
            else
              action(
                'Message',
                Icons.chat_bubble_outline,
                const Color(0xFF263C80),
                null,
              ),
          ],
        ),
      ),
    );
  }
}
