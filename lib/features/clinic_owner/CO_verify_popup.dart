import 'package:flutter/material.dart';

import 'CO_mainpage.dart';
import 'CO_verification_form.dart';
import 'CO_verification_status.dart';

/// Unverified homepage. Verification status must come from the account service.
class COVerifyPopup extends StatefulWidget {
  const COVerifyPopup({
    super.key,
    this.displayName = 'Clinic Owner',
    this.onCompleteProfile,
  });
  final String displayName;
  final VoidCallback? onCompleteProfile;

  @override
  State<COVerifyPopup> createState() => _COVerifyPopupState();
}

class _COVerifyPopupState extends State<COVerifyPopup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          coVerificationStatus.value == COVerificationStatus.verified)
        return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.12),
        builder: (_) => _VerificationDialog(
          displayName: widget.displayName,
          onCompleteProfile:
              widget.onCompleteProfile ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const COVerificationForm(),
                  ),
                );
              },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const COMainPage();
}

class _VerificationDialog extends StatefulWidget {
  const _VerificationDialog({
    required this.displayName,
    this.onCompleteProfile,
  });
  final String displayName;
  final VoidCallback? onCompleteProfile;

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  bool _showPendingMessage = false;

  @override
  void initState() {
    super.initState();
    coVerificationStatus.addListener(_onVerificationChanged);
  }

  void _onVerificationChanged() {
    if (mounted &&
        coVerificationStatus.value == COVerificationStatus.verified &&
        ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    coVerificationStatus.removeListener(_onVerificationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 140,
              height: 130,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.shield_outlined,
                      size: 130,
                      color: Color(0xFFDDF7F4),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 38,
                    child: Icon(
                      Icons.badge_outlined,
                      size: 88,
                      color: Color(0xFF9591BC),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 8,
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 52,
                      color: Color(0xFF8EDBD5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Hi, ${widget.displayName.toUpperCase()}! 👋',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please complete your profile information\nand verify your account for security\nand full access purposes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            if (_showPendingMessage) ...[
              const SizedBox(height: 14),
              const Text(
                'Profile completion is coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF263C80)),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onCompleteProfile != null) {
                    Navigator.of(context).pop();
                    widget.onCompleteProfile!();
                  } else {
                    setState(() => _showPendingMessage = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF263C80),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Complete Your Profile'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
