import 'package:flutter/material.dart';

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
  bool _searching = false;
  String _filter = 'All jobs';
  static const _tabs = [
    'Home',
    'Job Status',
    'Notifications',
    'Payments',
    'Account',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FCFB),
    body: SafeArea(
      child: ValueListenableBuilder<LocumVerificationStatus>(
        valueListenable: locumVerificationStatus,
        builder: (context, status, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: _tab == 0
              ? [
                  const Text(
                    'My Applications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 115,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _Promotion(
                          title: 'OPTOLOCUM\nALL IN ONE.',
                          subtitle: 'Find your next opportunity',
                          color: Color(0xFFFFD936),
                          icon: Icons.phone_android,
                        ),
                        _Promotion(
                          title: 'PERFECT COFFEE.\nPERFECT BREAK.',
                          subtitle: 'Take a moment to recharge',
                          color: Color(0xFFFFE1B9),
                          icon: Icons.coffee,
                        ),
                        _Promotion(
                          title: 'CONNECT.\nSHARE.\nLEARN.',
                          subtitle: 'Grow your professional network',
                          color: Color(0xFFE4D9FA),
                          icon: Icons.groups,
                        ),
                      ],
                    ),
                  ),
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
                        onSelected: (value) => setState(() => _filter = value),
                        itemBuilder: (_) => ['All jobs', 'Nearby', 'Part time']
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
                  Text(
                    _tab == 4
                        ? 'Verification: ${status.name}'
                        : 'No ${_tabs[_tab].toLowerCase()} yet.',
                  ),
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
      onTap: (index) => setState(() => _tab = index),
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

class _Promotion extends StatelessWidget {
  const _Promotion({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
  final String title, subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(subtitle, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
        Icon(icon, size: 40),
      ],
    ),
  );
}
