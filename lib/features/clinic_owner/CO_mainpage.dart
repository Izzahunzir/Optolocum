import 'package:flutter/material.dart';

import 'CO_verification_status.dart';
import 'CO_profile.dart';
import 'CO_locum_activity.dart';
import 'CO_notifications.dart';
import 'CO_postingjob.dart';

/// Homepage for verified clinic owners. Pass false behind the verification prompt.
class COMainPage extends StatefulWidget {
  const COMainPage({super.key, this.isVerified});

  /// Optional preview override. Live pages follow account verification status.
  final bool? isVerified;

  @override
  State<COMainPage> createState() => _COMainPageState();
}

class _COMainPageState extends State<COMainPage> {
  final _search = TextEditingController();
  bool _searchOpen = false;
  bool _newestFirst = true;

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
      builder: (context, status, _) =>
          ValueListenableBuilder<List<COJobPosting>>(
            valueListenable: coJobPostings,
            builder: (context, jobs, _) => _buildPage(
              context,
              widget.isVerified ?? status == COVerificationStatus.verified,
              jobs,
            ),
          ),
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
            Padding(
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
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          )
                        : const Text(
                            'Posted Jobs',
                            style: TextStyle(
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
                    icon: const Icon(Icons.search, color: Colors.black),
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
                    icon: const Icon(Icons.filter_alt, color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140 * MediaQuery.textScalerOf(context).scale(1),
              child: ListView(
                key: const Key('clinic-owner-ads'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: const [
                  _AdCard(
                    color: Color(0xFF263C80),
                    title: 'BUY 1 FREE 1',
                    subtitle: 'COFFEE BREAK',
                    footer: 'A little boost for your busy day',
                    icon: Icons.local_cafe_outlined,
                  ),
                  SizedBox(width: 14),
                  _AdCard(
                    color: Color(0xFFFFD600),
                    title: 'FRESH PICKS',
                    subtitle: 'FOR YOUR NEXT BREAK',
                    footer: 'BROWSE OUR TREATS',
                    icon: Icons.fastfood_outlined,
                    darkText: true,
                  ),
                  SizedBox(width: 14),
                  _AdCard(
                    color: Color(0xFF237F7D),
                    title: 'YOUR NEXT SHIFT',
                    subtitle: 'STARTS HERE',
                    footer: 'Discover Optolocum',
                    icon: Icons.visibility_outlined,
                  ),
                ],
              ),
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
    final ordered = _newestFirst ? jobs.reversed : jobs;
    final results = ordered
        .where(
          (job) => [
            job.role,
            job.placeName,
            job.location,
            job.description,
            job.contactPerson,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList();
    if (results.isEmpty)
      return const Center(child: Text('No matching job posts'));
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

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.icon,
    this.darkText = false,
  });
  final Color color;
  final String title, subtitle, footer;
  final IconData icon;
  final bool darkText;

  @override
  Widget build(BuildContext context) => Container(
    width: 230,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -4,
          bottom: -8,
          child: Icon(
            icon,
            size: 72,
            color: (darkText ? Colors.black : Colors.white).withValues(
              alpha: 0.2,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: darkText ? const Color(0xFF263C80) : Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: darkText
                    ? const Color(0xFF263C80)
                    : const Color(0xFFFFD778),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              footer,
              style: TextStyle(
                fontSize: 10,
                color: darkText ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
