import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Journal brand palette — slate ink + emerald.
///
/// We picked an emerald accent (financial green) over the Tranquee teal
/// because "P&L green" reads as canonical to a trader audience. The
/// rest of the palette mirrors the Pable structure so widget code stays
/// portable between the two apps.
class AppColors {
  static const ink = Color(0xFF0F1B2D); // brand slate ink
  static const inkDeep = Color(0xFF091221);

  static const teal = Color(0xFF10B981); // brand emerald (gains)
  static const tealDark = Color(0xFF0E9A6B);
  static const tealDarker = Color(0xFF0B7A55);
  static const teal50 = Color(0xFFE6F7F0);
  static const teal100 = Color(0xFFBFE6D3);

  static const bg = Color(0xFFFBFBF9); // brand soft white
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const borderSoft = Color(0xFFF1F3F5);

  static const gray900 = Color(0xFF111827);
  static const gray700 = Color(0xFF374151);
  static const gray600 = Color(0xFF4B5563);
  static const gray500 = Color(0xFF6B7280);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray300 = Color(0xFFD1D5DB);

  static const success = Color(0xFF10B981);
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444); // losses
  static const info = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);

  /// Tint a P&L value — green for profit, red for loss, grey for zero.
  static Color pnl(num value) {
    if (value > 0) return success;
    if (value < 0) return danger;
    return gray500;
  }
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.ink,
        secondary: AppColors.teal,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.gray900,
        displayColor: AppColors.gray900,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSoft,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: AppColors.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
