import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Splash — displayed while the auth session is restored from secure
/// storage. The router redirects from here once the status resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.balance_outlined,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Legal Metrology',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Legal Metrology Act, 2011 — Digital Enforcement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl + 16),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
