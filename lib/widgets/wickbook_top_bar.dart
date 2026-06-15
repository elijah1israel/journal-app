import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Branded top bar: the morning-star glyph + "Wickbook" wordmark on
/// the left, then the screen-specific section label, then optional
/// per-screen actions on the right.
///
/// Used by every top-level tab so the brand stays anchored as the user
/// jumps around the shell — instead of each screen rendering its own
/// generic text title.
class WickbookTopBar extends StatelessWidget implements PreferredSizeWidget {
  const WickbookTopBar({
    super.key,
    this.section,
    this.actions,
  });

  /// Optional small "you are here" label rendered next to the wordmark,
  /// e.g. "Dashboard", "Trades". Skip it on screens that read better
  /// without one (the splash / auth flows).
  final String? section;

  /// Right-aligned action icons — same slot as a normal `AppBar.actions`.
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 14),
              SvgPicture.asset(
                'assets/branding/wickbook-icon.svg',
                width: 26,
                height: 26,
              ),
              const SizedBox(width: 8),
              const Text(
                'Wickbook',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                  letterSpacing: -0.3,
                ),
              ),
              if (section != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 14,
                  color: AppColors.border,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    section!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (actions != null) ...[
                for (final a in actions!) a,
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
