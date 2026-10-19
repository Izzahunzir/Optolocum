import 'package:flutter/material.dart';

Future<void> showLJobProcessGuide(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierColor: Colors.black54,
  builder: (_) => const LJobProcessGuide(),
);

class LJobProcessGuide extends StatelessWidget {
  const LJobProcessGuide({super.key});

  static const _steps = [
    (
      '1. ✅ Apply for the Job',
      'Tap “Apply” to let the clinic know you\'re interested. You\'ll be notified once your application is reviewed and accepted!',
    ),
    (
      '2. ⏳ Wait for Clinic to Accept',
      'The clinic/employer will review your application and accept if you\'re a match.',
    ),
    (
      '3. 📅 Get Ready to Work',
      'Once accepted, mark your calendar and be prepared for the job.',
    ),
    (
      '4. 📲 Clock In via the App',
      'On the job day, open the app and clock in once you arrive.',
    ),
    (
      '5. 🕘 Clock Out When Done',
      'After your shift ends, remember to clock out via the app.',
    ),
    (
      '6. 🌟 Leave a Review',
      'Share feedback about the clinic/employer after your session.',
    ),
    (
      '7. 💰 Wait for Payment',
      'Our OptoLocum team will process and transfer your payment shortly.',
    ),
    (
      '8. 🚀 Grow Your Profile',
      'The more you work and review, the stronger your profile becomes.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '📝 What You Need to Do',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < _steps.length; index++) ...[
              Text(
                _steps[index].$1,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                _steps[index].$2,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black,
                ),
              ),
              if (index < _steps.length - 1) const SizedBox(height: 22),
            ],
          ],
        ),
      ),
    ),
  );
}
