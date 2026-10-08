import 'package:flutter/material.dart';

import 'CO_locum_activity.dart';
import 'CO_notifications.dart';
import 'CO_postingjob.dart';

class CONavigation extends StatelessWidget {
  const CONavigation({
    super.key,
    required this.onHome,
    required this.onProfile,
    this.profileSelected = false,
    this.locumSelected = false,
    this.onLocum,
    this.notificationsSelected = false,
    this.onNotifications,
    this.postingSelected = false,
    this.onPosting,
  });
  final VoidCallback onHome, onProfile;
  final bool profileSelected;
  final bool locumSelected;
  final VoidCallback? onLocum;
  final bool notificationsSelected;
  final VoidCallback? onNotifications;
  final bool postingSelected;
  final VoidCallback? onPosting;

  @override
  Widget build(BuildContext context) {
    Widget item(
      String label,
      IconData icon,
      VoidCallback action,
      bool selected,
    ) => Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: action,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected ? Colors.white : const Color(0xFF071B3C),
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
    return ColoredBox(
      color: const Color(0xFF3B4E92),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              item(
                'Home',
                Icons.home_outlined,
                onHome,
                !profileSelected &&
                    !locumSelected &&
                    !notificationsSelected &&
                    !postingSelected,
              ),
              item(
                'Notifications',
                Icons.notifications_none,
                onNotifications ??
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CONotifications(),
                      ),
                    ),
                notificationsSelected,
              ),
              Expanded(
                child: Center(
                  heightFactor: 1,
                  child: IconButton.outlined(
                    tooltip: 'Post a job',
                    onPressed:
                        onPosting ??
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const COPostingJob(),
                          ),
                        ),
                    style: IconButton.styleFrom(
                      foregroundColor: postingSelected
                          ? Colors.white
                          : const Color(0xFF071B3C),
                      side: const BorderSide(color: Color(0xFF071B3C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
              item(
                'Locum',
                Icons.groups_outlined,
                onLocum ??
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const COLocumActivity(),
                      ),
                    ),
                locumSelected,
              ),
              item(
                'Profile',
                Icons.account_circle_outlined,
                onProfile,
                profileSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
