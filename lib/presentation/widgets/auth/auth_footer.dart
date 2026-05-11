import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final String prompt;
  final String cta;
  final VoidCallback onCtaTap;
  final bool showTerms;

  const AuthFooter({
    super.key,
    required this.prompt,
    required this.cta,
    required this.onCtaTap,
    this.showTerms = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              prompt,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onCtaTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                cta,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        if (showTerms) ...[
          const SizedBox(height: 10),
          Text(
            'By continuing, you agree to our Terms & Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.42),
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
