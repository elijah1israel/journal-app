import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wickbook brand palette — charcoal ink + morning-star greens & reds.
///
/// The brand mark is a three-candle morning-star reversal: a bearish red
/// candle, a doji, and a bullish green candle. Those exact colours
/// (`#00D964`, `#FF3B47`) double as the app's gain / loss tints so
/// every P&L surface reads as "the green-and-red of the logo".
///
/// We ship a dark theme: the brand icon already sits on `#0E1116`, so
/// surrounding the UI with the same charcoal makes the icon read as
/// part of the chrome rather than an applied sticker, and the candles'
/// colour saturation pops against the dark backdrop the way it does on
/// a trading terminal.
class AppColors {
  static const ink = Color(0xFF1F2630); // elevated chrome (buttons, headers)
  static const inkDeep = Color(0xFF0A0D11);

  // Brand emerald — kept under the `teal*` prefix so the widget code
  // (PrimaryButton, StatusPill, FilterChip…) can stay portable from
  // pable-mobile without rename churn.
  static const teal = Color(0xFF00D964);
  static const tealDark = Color(0xFF00B554);
  static const tealDarker = Color(0xFF00F076); // brighter on dark
  static const teal50 = Color(0x2200D964); // 13% green tint for pill bgs
  static const teal100 = Color(0x4400D964);

  static const bg = Color(0xFF0E1116); // brand charcoal (matches icon bg)
  static const surface = Color(0xFF16191F); // cards, inputs, sheets
  static const border = Color(0xFF262B33); // subtle dividers
  static const borderSoft = Color(0xFF1B1F26); // softer dividers

  // Text scale flipped for dark mode. `gray900` is the highest-contrast
  // foreground (was near-black in light mode) — now matches the white
  // candle wick `#F5F7FA` from the brand icon.
  static const gray900 = Color(0xFFF5F7FA);
  static const gray700 = Color(0xFFC7CCD3);
  static const gray600 = Color(0xFF9BA3AE); // matches the doji body grey
  static const gray500 = Color(0xFF7A828C);
  static const gray400 = Color(0xFF5A6068);
  static const gray300 = Color(0xFF3E4249);

  static const success = Color(0xFF00D964); // brand bullish candle
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFFF3B47); // brand bearish candle
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
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        brightness: Brightness.dark,
        primary: AppColors.teal,
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
        backgroundColor: AppColors.bg,
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
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
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
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.gray900, fontSize: 13),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
