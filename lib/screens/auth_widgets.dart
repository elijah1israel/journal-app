import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Uppercase field label shared by the auth screens.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.gray500,
          ),
        ),
      );
}

/// Clean underline ("line") field used across the auth screens.
InputDecoration authInput(IconData icon, {Widget? suffixIcon, String? hint}) {
  const enabled =
      UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border));
  const focused = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.teal, width: 2));
  const error =
      UnderlineInputBorder(borderSide: BorderSide(color: AppColors.danger));
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 19, color: AppColors.gray400),
    suffixIcon: suffixIcon,
    filled: false,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    border: enabled,
    enabledBorder: enabled,
    focusedBorder: focused,
    errorBorder: error,
    focusedErrorBorder: error,
  );
}

/// Centered, scrollable layout with the Journal lockup. Shared chrome
/// for login / register.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.showBack = false});

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: const BackButton(color: AppColors.gray700),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/branding/wickbook-icon.svg',
                        width: 48,
                        height: 48,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Wickbook',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain rounded card used by the login / register screens.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900)),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.gray500)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

/// Email-format check shared by the auth forms.
String? validateEmail(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Required';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  return ok ? null : 'Enter a valid email';
}
