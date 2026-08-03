import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// The single source of light/dark [ThemeData] for the app.
///
/// Everything here is derived from [ColorScheme.fromSeed] plus the token
/// scales in `tokens.dart`. This matters specifically because the audit of
/// the old app found dark mode silently broken on most screens: individual
/// screens hardcoded `Colors.white`, `Colors.grey.shadeNNN` and 12 different
/// hand-picked pastel gradients on the dashboard cards, none of which
/// respond to `ThemeMode.dark`. As of M1, screens must read every colour
/// from `Theme.of(context).colorScheme` — component styling lives here,
/// once, so it is consistent and dark-mode-correct by construction.
abstract final class AppTheme {
  static const _seed = Color(0xFF0F766E); // teal, matches the old brand mark

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = GoogleFonts.notoSansTextTheme(baseTextTheme).copyWith(
      // Bengali script needs a font with full Bengali coverage; Noto Sans
      // covers both scripts so we don't need to switch fonts per locale.
      displayLarge: GoogleFonts.notoSans(
        textStyle: baseTextTheme.displayLarge,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.notoSans(
        textStyle: baseTextTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.notoSans(
        textStyle: baseTextTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: GoogleFonts.notoSans(
        textStyle: baseTextTheme.labelLarge,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: AppElevation.flat,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: AppElevation.card,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
