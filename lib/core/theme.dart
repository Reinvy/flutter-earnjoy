import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background
  static const background = Color(0xFF0A0E1A); // deep navy
  static const surface = Color(0xFF111827);
  static const surfaceHigh = Color(0xFF1C2030);

  // Primary — Amber-Orange sunrise
  static const primary = Color(0xFFF97316);
  static const primaryLight = Color(0xFFFBBF24);
  static const primaryDim = Color(0x1FF97316); // 12% opacity

  // Accent pair — hanya dipakai via AppGradients
  static const gradientStart = Color(0xFFF97316); // amber-orange
  static const gradientEnd = Color(0xFFFBBF24);   // amber-gold

  // Text
  static const textPrimary = Color(0xFFF5F6FA);
  static const textSecondary = Color(0xFF8C8FA6);
  static const textDisabled = Color(0xFF4E5169);

  // Semantic
  static const success = Color(0xFF3EC193);
  static const warning = Color(0xFFF5A623);
  static const error = Color(0xFFEC5B5B);

  // Glass border
  static const glassBorder = Color(0x0DFFFFFF);

  // Centralized Reward Category Colors — disesuaikan lebih warm & harmonis
  static const rewardFood = Color(0xFFFF8C42);
  static const rewardEntertainment = Color(0xFFF97316);
  static const rewardShopping = Color(0xFFFF6B9D);
  static const rewardExperience = Color(0xFF56CFE1);
  static const rewardSelfGrowth = Color(0xFF3EC193);
  static const rewardRest = Color(0xFFB5838D);

  // Centralized Badge Rarity Colors
  static const rarityCommon = Color(0xFF8E92A8);
  static const rarityRare = Color(0xFF56CFE1);
  static const rarityEpic = Color(0xFFF97316);
  static const rarityLegendary = Color(0xFFFBBF24);

  // Centralized level/tier colors
  static const tierNovice = Color(0xFF8E92A8);
  static const tierApprentice = Color(0xFF56CFE1);
  static const tierPractitioner = Color(0xFF3EC193);
  static const tierAchiever = Color(0xFFF97316);
  static const tierExpert = Color(0xFFFBBF24);
  static const tierMaster = Color(0xFFFF6B6B);
  static const tierLegend = Color(0xFFFFD700);

  static Color rewardColorForCategory(String category) {
    return switch (category) {
      'food' => rewardFood,
      'entertainment' => rewardEntertainment,
      'shopping' => rewardShopping,
      'experience' => rewardExperience,
      'self_growth' => rewardSelfGrowth,
      'rest' => rewardRest,
      _ => textSecondary,
    };
  }

  static Color tierColorFor(String tier) {
    return switch (tier) {
      'Novice' => tierNovice,
      'Apprentice' => tierApprentice,
      'Practitioner' => tierPractitioner,
      'Achiever' => tierAchiever,
      'Expert' => tierExpert,
      'Master' => tierMaster,
      'Legend' => tierLegend,
      _ => tierApprentice,
    };
  }
}

class AppGradients {
  // Hero gradient — soft diagonal amber ke gold, 75% opacity
  static const primary = LinearGradient(
    colors: [Color(0xBFF97316), Color(0xBFFBBF24)], // 75% opacity
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle gradient for chips/card backgrounds
  static const subtle = LinearGradient(
    colors: [Color(0x14F97316), Color(0x08FBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle warm glow — di belakang angka besar
  static const heroGlow = RadialGradient(
    colors: [Color(0x18F97316), Color(0x00000000)],
    radius: 0.85,
  );

  // Progress bar fill — amber left-to-right
  static const progressFill = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Card glassmorphism overlay
  static const glassOverlay = LinearGradient(
    colors: [Color(0x0AFFFFFF), Color(0x02FFFFFF)],
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
  final fontFamily = GoogleFonts.plusJakartaSans().fontFamily;
  return ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      error: AppColors.error,
    ),
    fontFamily: fontFamily,
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
