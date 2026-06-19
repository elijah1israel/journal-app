import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/branding/wickbook-icon.svg',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 16),
            // Bearish red wick, bullish green body — the same two-candle
            // colour cue the brand icon uses, so the wordmark reads as
            // the logo even when the icon isn't beside it.
            const Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(text: 'Wick', style: TextStyle(color: AppColors.danger)),
                  TextSpan(text: 'book', style: TextStyle(color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.teal),
          ],
        ),
      ),
    );
  }
}
