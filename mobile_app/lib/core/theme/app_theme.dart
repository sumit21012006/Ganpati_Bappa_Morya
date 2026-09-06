import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// GovTech light theme — professional blue/green/neutral palette.
///
/// Design principles: light theme, clean cards, rounded-but-not-excessive
/// corners, strong typography hierarchy, large readable text, clear CTAs.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B4B8F); // Deep institutional blue
  static const Color primaryDark = Color(0xFF123566);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFDCE7F7);
  static const Color onPrimaryContainer = Color(0xFF12325C);

  // Secondary — compliance green
  static const Color secondary = Color(0xFF1B7F5A);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFD8F0E5);
  static const Color onSecondaryContainer = Color(0xFF0E5138);

  // Tertiary — attention amber
  static const Color tertiary = Color(0xFF9A6B00);
  static const Color tertiaryContainer = Color(0xFFFFEFCC);
  static const Color onTertiaryContainer = Color(0xFF5C4000);

  // Neutrals
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEDF1F6);
  static const Color outline = Color(0xFFC6CFDA);
  static const Color outlineVariant = Color(0xFFE1E7EF);

  // Text
  static const Color textPrimary = Color(0xFF16202B);
  static const Color textSecondary = Color(0xFF4A5866);
  static const Color textHint = Color(0xFF7C8B9A);

  // Semantic
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFFCE8E6);
  static const Color onErrorContainer = Color(0xFF7A1611);
  static const Color success = Color(0xFF1B7F5A);
  static const Color successContainer = Color(0xFFD8F0E5);
  static const Color warning = Color(0xFF9A6B00);
  static const Color warningContainer = Color(0xFFFFEFCC);
  static const Color info = Color(0xFF1B4B8F);
  static const Color infoContainer = Color(0xFFDCE7F7);

  // AI branding
  static const Color aiAccent = Color(0xFF5B4BC4);
  static const Color aiContainer = Color(0xFFEAE7FA);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const long = Duration(milliseconds: 420);
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    // Strong typography hierarchy, large readable text.
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.outline),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceVariant,
      side: BorderSide.none,
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14.5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      elevation: 0,
      height: 66,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      showDragHandle: true,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.outlineVariant,
    ),
  );
}
