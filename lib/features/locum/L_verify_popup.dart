import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'L_mainpage.dart';
import 'L_verification_form.dart';

class LVerifyPopup extends StatefulWidget {
  const LVerifyPopup({super.key, this.displayName = 'Locum'});
  final String displayName;

  @override
  State<LVerifyPopup> createState() => _LVerifyPopupState();
}

class _LVerifyPopupState extends State<LVerifyPopup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          locumVerificationStatus.value != LocumVerificationStatus.unverified) {
        return;
      }
      showDialog<void>(
        context: context,
        // Allow testers to continue to the homepage without completing the form.
        barrierDismissible: kDebugMode,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 110,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.shield, size: 110, color: Color(0xFFDDF7F4)),
                        Icon(
                          Icons.badge_outlined,
                          size: 76,
                          color: Color(0xFF9591BC),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.verified_user_outlined,
                            size: 42,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please complete your profile information\nand verify your account for security\nand full access purposes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF237F7D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => LVerificationForm(
                              displayName: widget.displayName,
                            ),
                          ),
                        );
                      },
                      child: const Text('Complete Your Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const LMainPage();
}
