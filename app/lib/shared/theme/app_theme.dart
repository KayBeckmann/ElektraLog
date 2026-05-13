import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Industrial Precision System — Material Theme
/// Engineered for high-stakes DGUV V3 electrical testing environments.
/// Prioritizes utility over decoration: reliability, precision, efficiency.
abstract final class AppTheme {
  /// Light theme — the primary theme for ElektraLog.
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    );

    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.outlineVariant.withValues(alpha: 0.5),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.outline.withValues(alpha: 0.08),
        indicatorColor: AppColors.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onSecondaryContainer);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall?.copyWith(
            letterSpacing: 0.05 * 12,
            fontWeight: FontWeight.w700,
          );
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: AppColors.onSecondaryContainer);
          }
          return base?.copyWith(color: AppColors.onSurfaceVariant);
        }),
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        elevation: 4,
        width: 320,
        shadowColor: Colors.black26,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05 * 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.outline),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        labelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05 * 12,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
          side: BorderSide(color: AppColors.outlineVariant),
        ),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text Theme — Inter + JetBrains Mono
  // ---------------------------------------------------------------------------
  static TextTheme _buildTextTheme() {
    final inter = GoogleFonts.interTextTheme();
    final mono = GoogleFonts.jetBrainsMonoTextTheme();

    return TextTheme(
      // Display — display-lg (32px, 700, -0.02em)
      displayLarge: inter.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        height: 1.2,
        color: AppColors.onBackground,
      ),
      displayMedium: inter.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onBackground,
      ),
      displaySmall: inter.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.onBackground,
      ),

      // Headline — headline-md (24px, 600)
      headlineLarge: inter.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.onBackground,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.onBackground,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onBackground,
      ),

      // Title — title-sm (18px, 600)
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onBackground,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.onBackground,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.onBackground,
      ),

      // Body — body-base (16px, 400) / body-sm (14px, 400)
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.onBackground,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onBackground,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurfaceVariant,
      ),

      // Label — label-caps (12px, 700, 0.05em)
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.02 * 14,
        color: AppColors.onBackground,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05 * 12,
        height: 1.0,
        color: AppColors.onBackground,
      ),
      labelSmall: mono.labelSmall?.copyWith(
        // data-mono: 14px, 500 — JetBrains Mono for technical data
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  /// Returns the JetBrains Mono TextStyle for technical/numeric data display.
  static TextStyle dataMono({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.4,
      color: color ?? AppColors.onSurface,
    );
  }
}
