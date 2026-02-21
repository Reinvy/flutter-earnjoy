// Category weights
const Map<String, double> categoryWeights = {
  'Work': 1.3,
  'Study': 1.2,
  'Health': 1.1,
  'Hobby': 0.8,
  'Fun': 0.5,
};

// Point rules
const double maxPointsPerDay = 500.0;
const double diminishingReturnFactor = 0.8;

// Cooldown duration per category (in minutes)
const int cooldownMinutes = 30;

// Motivation messages (placeholder {points} will be replaced at runtime)
const List<String> motivationMessages = [
  'Mantap! Kamu makin dekat ke reward 🎁',
  'Kerja keras terbayar. +{points} poin! 🔥',
  'Streak kamu bertambah. Jaga terus! ⚡',
  'Konsisten adalah kunci. Terus semangat! 💪',
  'Setiap langkah kecil membawa kamu lebih jauh! 🚀',
];

// Default monthly budget cap
const double defaultMonthlyBudget = 10000.0;

// Preset activities for quick-add bottom sheet
const List<Map<String, dynamic>> presetActivities = [
  {'title': 'Study', 'category': 'Study', 'durationMinutes': 30},
  {'title': 'Work', 'category': 'Work', 'durationMinutes': 60},
  {'title': 'Gym', 'category': 'Health', 'durationMinutes': 45},
  {'title': 'Reading', 'category': 'Hobby', 'durationMinutes': 30},
  {'title': 'Running', 'category': 'Health', 'durationMinutes': 30},
];
