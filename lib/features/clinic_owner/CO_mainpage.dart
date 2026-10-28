import 'package:flutter/material.dart';

import 'package:optolocum/services/job_service.dart';

import '../../widgets/advertisement_strip.dart';

import 'CO_verification_status.dart';

import 'CO_profile.dart';
import 'CO_locum_activity.dart';
import 'CO_notifications.dart';
import 'CO_postingjob.dart';

/// Homepage for verified clinic owners. Pass false behind the verification prompt.
class COMainPage extends StatefulWidget {
  const COMainPage({super.key, this.isVerified, this.jobsStream});

  final Stream<List<COJobPosting>>? jobsStream;

  /// Optional preview override. Live pages follow account verification status.
  final bool? isVerified;

  @override
  State<COMainPage> createState() => _COMainPageState();
}

class _COMainPageState extends State<COMainPage> {
  final _search = TextEditingController();
  bool _searchOpen = false;
  bool _newestFirst = true;
  late final _jobsStream =
      widget.jobsStream ??
      JobService().getMyJobs().map(
        (snapshot) => snapshot.docs
            .map((doc) => jobFromFirestore(doc.data(), jobId: doc.id))
            .toList(),
      );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _blue = Color(0xFF3B4E92);

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<COVerificationStatus>(
      valueListenable: coVerificationStatus,
      builder: (context, status, _) {
        return StreamBuilder<List<COJobPosting>>(
          stream: _jobsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Failed to load jobs: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final jobs = snapshot.data!;

            return _buildPage(
              context,
              widget.isVerified ?? status == COVerificationStatus.verified,
              jobs,
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    bool verified,
    List<COJobPosting> jobs,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFE),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _blue,
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _search,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search your job posts',
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              suffixIcon: IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _search.clear();
                                  FocusScope.of(context).unfocus();
                                  setState(() => _searchOpen = false);
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          )
                        : const Text(
                            'Posted Jobs',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  IconButton(
                    tooltip: 'Search jobs',
                    onPressed: () => setState(() {
                      _searchOpen = !_searchOpen;
                      if (!_searchOpen) {
                        _search.clear();
                        FocusScope.of(context).unfocus();
                      }
                    }),
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  PopupMenuButton<bool>(
                    tooltip: 'Filter jobs',
                    initialValue: _newestFirst,
                    onSelected: (value) => setState(() => _newestFirst = value),
                    itemBuilder: (_) => [
                      CheckedPopupMenuItem(
                        value: true,
                        checked: _newestFirst,
                        child: const Text('Recent to Oldest'),
                      ),
                      CheckedPopupMenuItem(
                        value: false,
                        checked: !_newestFirst,
                        child: const Text('Oldest to Recent'),
                      ),
                    ],
                    icon: const Icon(Icons.filter_alt, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const AdvertisementStrip(
              key: Key('clinic-owner-ads'),
              horizontalPadding: 12,
            ),
            Expanded(
              child: jobs.isNotEmpty
                  ? _postedJobs(jobs)
                  : _search.text.trim().isNotEmpty
                  ? const Center(child: Text('No matching job posts'))
                  : verified
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Stack(
                                      children: [
                                        const Align(
                                          alignment: Alignment.topCenter,
                                          child: Icon(
                                            Icons.description_rounded,
                                            size: 112,
                                            color: Color(0xFF9B89ED),
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          bottom: 10,
                                          child: Transform.rotate(
                                            angle: -0.2,
                                            child: const Icon(
                                              Icons.search,
                                              size: 48,
                                              color: Color(0xFF263C80),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  const Text(
                                    'You haven’t posted any locum jobs yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Find qualified optometrists and staff by\ncreating your first job posting',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.expand(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: _blue,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selected: true,
                  onTap: () {},
                ),
                _NavItem(
                  label: 'Notifications',
                  icon: Icons.notifications_none,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CONotifications(),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    heightFactor: 1,
                    child: IconButton.outlined(
                      tooltip: 'Post a job',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const COPostingJob(),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFF071B3C),
                        side: const BorderSide(color: Color(0xFF071B3C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
                _NavItem(
                  label: 'Locum',
                  icon: Icons.groups_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const COLocumActivity(),
                    ),
                  ),
                ),
                _NavItem(
                  label: 'Profile',
                  icon: Icons.account_circle_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const COProfile()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _postedJobs(List<COJobPosting> jobs) {
    final query = _search.text.trim().toLowerCase();
    final chronological = jobs.toList()
      ..sort(
        (a, b) => (a.createdAt ?? a.date).compareTo(b.createdAt ?? b.date),
      );
    final ordered = _newestFirst ? chronological.reversed : chronological;
    final results = ordered
        .where(
          (job) => [
            job.role,
            job.placeName,
            job.location,
            job.description,
            job.contactPerson,
            job.contactNumber,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList();
    if (results.isEmpty) {
      return const Center(child: Text('No matching job posts'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      children: [
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _newestFirst ? 'Latest' : 'Oldest first',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...results.map((job) => COPostedJobCard(job: job)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF071B3C),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Colors.white : const Color(0xFF071B3C),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
