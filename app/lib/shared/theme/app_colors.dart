import 'package:flutter/material.dart';

/// Industrial Precision System — Color Constants
/// Based on the ElektraLog design system for DGUV V3 electrical testing.
abstract final class AppColors {
  // ---- Primary (Slate / Navy) ----
  static const Color primary = Color(0xFF091426);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1E293B);
  static const Color onPrimaryContainer = Color(0xFF8590A6);
  static const Color inversePrimary = Color(0xFFBCC7DE);

  // ---- Secondary (Steel Blue) ----
  static const Color secondary = Color(0xFF505F76);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD0E1FB);
  static const Color onSecondaryContainer = Color(0xFF54647A);

  // ---- Tertiary (Warm Brown) ----
  static const Color tertiary = Color(0xFF1E1200);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF35260C);
  static const Color onTertiaryContainer = Color(0xFFA38C6A);

  // ---- Error ----
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ---- Surface ----
  static const Color surface = Color(0xFFFBF8FA);
  static const Color surfaceDim = Color(0xFFDCD9DB);
  static const Color surfaceBright = Color(0xFFFBF8FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3F4);
  static const Color surfaceContainer = Color(0xFFF0EDEF);
  static const Color surfaceContainerHigh = Color(0xFFEAE7E9);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E3);
  static const Color onSurface = Color(0xFF1B1B1D);
  static const Color onSurfaceVariant = Color(0xFF45474C);
  static const Color inverseSurface = Color(0xFF303032);
  static const Color inverseOnSurface = Color(0xFFF3F0F2);

  // ---- Outline ----
  static const Color outline = Color(0xFF75777D);
  static const Color outlineVariant = Color(0xFFC5C6CD);

  // ---- Background ----
  static const Color background = Color(0xFFFBF8FA);
  static const Color onBackground = Color(0xFF1B1B1D);

  // ---- Surface Variant ----
  static const Color surfaceVariant = Color(0xFFE4E2E3);
  static const Color surfaceTint = Color(0xFF545F73);

  // ---- Fixed Colors ----
  static const Color primaryFixed = Color(0xFFD8E3FB);
  static const Color primaryFixedDim = Color(0xFFBCC7DE);
  static const Color onPrimaryFixed = Color(0xFF111C2D);
  static const Color onPrimaryFixedVariant = Color(0xFF3C475A);

  static const Color secondaryFixed = Color(0xFFD3E4FE);
  static const Color secondaryFixedDim = Color(0xFFB7C8E1);
  static const Color onSecondaryFixed = Color(0xFF0B1C30);
  static const Color onSecondaryFixedVariant = Color(0xFF38485D);

  static const Color tertiaryFixed = Color(0xFFFADFB8);
  static const Color tertiaryFixedDim = Color(0xFFDDC39D);
  static const Color onTertiaryFixed = Color(0xFF271902);
  static const Color onTertiaryFixedVariant = Color(0xFF564427);

  // ---- Semantic Status Colors ----
  static const Color success = Color(0xFF1A6B2E);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFB7F0CB);
  static const Color onSuccessContainer = Color(0xFF002109);

  static const Color warning = Color(0xFF7A5700);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFDEA0);
  static const Color onWarningContainer = Color(0xFF261900);
}
