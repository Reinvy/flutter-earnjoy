class LevelSystem {
  static const int maxLevel = 100;

  // Level structure based on feature-recommendations.md
  // Level 1  → 2   :    500 XP   — Novice
  // Level 2  → 3   :  1.500 XP   — Apprentice
  // Level 3  → 4   :  3.000 XP   — Practitioner
  // Level 4  → 5   :  5.000 XP   — Achiever
  // Level 5  → 10  :  +3.000/lvl — Expert tier
  // Level 10 → 20  :  +8.000/lvl — Master tier
  // Level 20+      :  +15.000/lvl — Legend tier

  /// Calculates the current level based on total XP
  static int currentLevel(double xp) {
    if (xp < 500) return 1;
    if (xp < 1500) return 2;
    if (xp < 3000) return 3;
    if (xp < 5000) return 4;
    
    // Level 5 to 10 (Expert)
    if (xp < 20000) { // 5000 + (5 * 3000) = 20000 (XP required to reach level 10)
      return 5 + ((xp - 5000) ~/ 3000);
    }
    
    // Level 10 to 20 (Master)
    if (xp < 100000) { // 20000 + (10 * 8000) = 100000 (XP required to reach level 20)
      return 10 + ((xp - 20000) ~/ 8000);
    }
    
    // Level 20+ (Legend)
    final int level = 20 + ((xp - 100000) ~/ 15000);
    return level > maxLevel ? maxLevel : level;
  }

  /// Returns the name of the Tier for the given level
  static String getTierName(int level) {
    if (level < 2) return 'Novice';
    if (level < 3) return 'Apprentice';
    if (level < 4) return 'Practitioner';
    if (level < 5) return 'Achiever';
    if (level < 10) return 'Expert';
    if (level < 20) return 'Master';
    return 'Legend';
  }

  /// Calculates the total XP required to reach the NEXT level
  static double xpForNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return double.infinity;
    if (currentLevel == 1) return 500;
    if (currentLevel == 2) return 1500;
    if (currentLevel == 3) return 3000;
    if (currentLevel == 4) return 5000;
    
    if (currentLevel >= 5 && currentLevel < 10) {
      return 5000 + ((currentLevel - 4) * 3000).toDouble();
    }
    
    if (currentLevel >= 10 && currentLevel < 20) {
      return 20000 + ((currentLevel - 9) * 8000).toDouble();
    }
    
    // Level 20+
    return 100000 + ((currentLevel - 19) * 15000).toDouble();
  }

  /// Calculates the total XP required to reach the CURRENT level
  static double xpForCurrentLevel(int currentLevel) {
    if (currentLevel <= 1) return 0;
    return xpForNextLevel(currentLevel - 1);
  }

  /// Returns progress percentage (0.0 to 1.0) towards the next level
  static double getProgress(double xp) {
    final int level = currentLevel(xp);
    if (level >= maxLevel) return 1.0;

    final double currentLevelXp = xpForCurrentLevel(level);
    final double nextLevelXp = xpForNextLevel(level);
    
    final double xpInCurrentLevel = xp - currentLevelXp;
    final double requiredXpForNext = nextLevelXp - currentLevelXp;

    return (xpInCurrentLevel / requiredXpForNext).clamp(0.0, 1.0);
  }

  /// Returns the point multiplier based on the current level
  static double getPointMultiplier(int level) {
    if (level >= 25) return 1.10;
    if (level >= 15) return 1.05;
    return 1.00;
  }
}
