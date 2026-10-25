import 'package:flutter/material.dart';

import '../../services/application_service.dart';

Future<void> showApplyJobDialog({
  required BuildContext context,
  required String jobId,
  required String jobTitle,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Are you sure you want to apply for "$jobTitle"?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 48),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF237F7D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Show loading while saving to Firebase
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await ApplicationService().applyForJob(jobId);

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Application Submitted'),
        content: const Text(
          'Your application has been submitted successfully.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Failed to apply: $e')));
  }
}
