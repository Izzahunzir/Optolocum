import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/CO_signin.dart';

/// Initial role selection. Connect callbacks when the next screens exist.
class IntroPage extends StatelessWidget {
  const IntroPage({
    super.key,
    this.onLocumSelected,
    this.onClinicOwnerSelected,
  });

  final VoidCallback? onLocumSelected;
  final VoidCallback? onClinicOwnerSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / 390).clamp(0.85, 1.3);
            final horizontalPadding = constraints.maxWidth >= 600
                ? (constraints.maxWidth -
                          math.min(constraints.maxWidth * 0.8, 960)) /
                      2
                : 29 * scale;
            // Adapt spacing to available height while allowing scrolling
            // for compact windows and larger accessibility text.
            final spacing = ((constraints.maxHeight - 350 * scale) / 538).clamp(
              0.08,
              1.0,
            );
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 160 * spacing),
                          Text(
                            'Welcome to\nOptolocum',
                            style: TextStyle(
                              fontSize: 34 * scale,
                              height: 1.22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8 * scale,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          Text(
                            'Connecting optometrists\nwith opportunities',
                            style: TextStyle(
                              fontSize: 18 * scale,
                              height: 1.2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 212 * spacing),
                          Center(
                            child: Text(
                              'See better careers ahead',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22 * scale,
                                height: 1.3,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: 40 * spacing),
                          IntroRoleButton(
                            label: 'Locum',
                            description: 'Locum looking for vacancies',
                            color: const Color(0xFF237F7D),
                            scale: scale,
                            onPressed:
                                onLocumSelected ??
                                () => _showSelection(context, 'Locum'),
                          ),
                          SizedBox(height: 39 * spacing),
                          IntroRoleButton(
                            label: 'Clinic Owner',
                            description: 'Clinic owner looking for Locums',
                            color: const Color(0xFF263C80),
                            scale: scale,
                            onPressed:
                                onClinicOwnerSelected ??
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const CompanyOwnerSigninPage(),
                                  ),
                                ),
                          ),
                          SizedBox(height: 87 * spacing),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSelection(BuildContext context, String role) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$role selected. Registration is coming soon.')),
      );
  }
}

/// Shared appearance and accessible tap target for both entry points.
class IntroRoleButton extends StatelessWidget {
  const IntroRoleButton({
    super.key,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
    this.scale = 1,
  });

  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 250 * scale,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: Size(250 * scale, math.max(48, 45 * scale)),
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 9 * scale,
                ),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9 * scale),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                ),
                textStyle: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
          SizedBox(height: 17 * scale),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16 * scale,
              height: 1.25,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
