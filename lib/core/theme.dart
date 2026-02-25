import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const background = Color(0xFF0D0D12);
  static const surface = Color(0xFF16161E);
  static const surfaceHigh = Color(0xFF1F1F2C);

  // Primary
  static const primary = Color(0xFF8B7FF5);
  static const primaryLight = Color(0xFFB8B0FF);
  static const primaryDim = Color(0x288B7FF5);

  // Accent pair untuk gradient - hanya dipakai via AppGradients
  static const gradientStart = Color(0xFF8B7FF5);
  static const gradientEnd = Color(0xFF5EC4F0);

  // Text
  static const textPrimary = Color(0xFFF2F2F7);
  static const textSecondary = Color(0xFF8E8EA0);
  static const textDisabled = Color(0xFF3D3D50);

  // Semantic
  static const success = Color(0xFF4ECFA0);
  static const warning = Color(0xFFFFB547);
  static const error = Color(0xFFFF6B6B);

  // Glass border
  static const glassBorder = Color(0x1AFFFFFF);
}

class AppGradients {
  // Hero gradient — point balance, CTA button utama
  static const primary = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle glow background - di belakang angka besar
  static const heroGlow = RadialGradient(
    colors: [Color(0x338B7FF5), Color(0x00000000)],
    radius: 0.85,
  );

  // Progress bar fill
  static const progressFill = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Card glassmorphism overlay
  static const glassOverlay = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppText {
  static const displayLarge = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -2.0,
  );

  static const displaySmall = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenH = 20;
  static const double sectionGap = 28;
}

class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double full = 999;
}

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      displayLarge: AppText.displayLarge,
      displaySmall: AppText.displaySmall,
      titleMedium: AppText.title,
      bodyMedium: AppText.body,
      bodySmall: AppText.caption,
    ),
    useMaterial3: true,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      indicatorColor: AppColors.primaryDim,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.textSecondary);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppText.caption.copyWith(color: AppColors.primary);
        }
        return AppText.caption;
      }),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
