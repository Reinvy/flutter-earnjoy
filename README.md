# EarnJoy

> **"You must earn your reward."**

EarnJoy is an offline-first Flutter mobile app that implements a **gamified personal economy**: log your activities, earn points, and unlock self-rewards. Built for Android & iOS.

---

## Overview

Most people give themselves rewards impulsively — without effort or consistency. EarnJoy fixes that by turning your daily activities into a personal currency system:

```
Do activity → Earn points → Unlock reward → Repeat
```

Every reward stays locked until you've accumulated enough points to deserve it, turning self-discipline into something that actually feels rewarding.

---

## Features

### Activity System

- Quick-add preset activities (Study 30m, Work 1h, Gym 45m) in one tap
- Manual activity input with title, duration, and category
- Activity categories: Work, Study, Health, Hobby, Fun — each with a different point weight

### Point System

- Points calculated using a formula:
  ```
  points = base × duration × categoryWeight × streakBonus × adjustmentFactor
  ```
- Streak bonus: `1 + (streakDays × 0.05)` — rewards consistency
- Daily point cap to prevent abuse
- Diminishing returns for repeated same-category activities
- Cooldown between identical activity logs

### Reward System

- Create a personal wishlist with custom point costs
- Per-reward progress bar — see exactly how close you are
- Reward redeem only unlocks when balance ≥ point cost
- Monthly budget cap to prevent overspending

### Smart Engine

- Adjustment factor based on activity history
- Burnout detection via discipline score tracking
- Streak reset if no activity logged the previous day

### Emotional Feedback

- Haptic feedback on every point earn (`mediumImpact`) and redeem (`heavyImpact`)
- Counter animation on point balance
- Micro scale animation on activity cards (1.0 → 1.03 → 1.0)
- Random motivational snackbar after each activity

---

## Screens

| Screen      | Purpose                                                                                      |
| ----------- | -------------------------------------------------------------------------------------------- |
| **Home**    | Point balance, streak counter, quick-add activity, daily progress bar, today's activity list |
| **Reward**  | Wishlist management, per-reward progress, redeem action with celebration overlay             |
| **Profile** | User settings, monthly budget control, weekly summary, JSON data export                      |

Every core action is reachable in ≤ 2 taps.

---

## Tech Stack

| Layer            | Technology                                  |
| ---------------- | ------------------------------------------- |
| Framework        | Flutter 3.x (Dart)                          |
| State Management | `provider` — `ChangeNotifier`               |
| Local Storage    | ObjectBox (offline-first, NoSQL)            |
| Architecture     | Services + Providers (pragmatic clean arch) |

---

## Architecture

```
Screen → Provider (ChangeNotifier) → Service → StorageService (ObjectBox)
```

```
lib/
 ├── core/          # theme, constants, extensions
 ├── models/        # User, Activity, Reward, Transaction (@Entity)
 ├── services/      # point_engine, activity_service, reward_service, storage_service
 ├── providers/     # activity_provider, reward_provider, user_provider
 └── screens/       # home/, reward/, profile/ — each with widgets/ subfolder
```

- **Screens** are `StatelessWidget` — all state lives in providers
- **Services** contain pure business logic with no Flutter imports
- **StorageService** is the only layer that knows ObjectBox — full storage isolation

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.8.1`
- Android Studio / Xcode for device/emulator

### Setup

```bash
# Clone the repository
git clone https://github.com/Reinvy/flutter-earnjoy.git
cd earnjoy

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### After modifying models

ObjectBox requires code generation whenever `@Entity` models change:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Development Commands

```bash
# Run linter
flutter analyze

# Run unit tests
flutter test

# Build release APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS IPA
flutter build ipa --release
```

---

## Design System

Visual style: **Modern Minimalism + Soft Gradient** — dark warm-neutral base (`#0D0D12`), subtle purple-to-cyan gradient on hero elements and CTAs, glassmorphism on highlight cards.

All design tokens are defined in `lib/core/theme.dart`:

- `AppColors` — background, surface, primary, semantic colors
- `AppGradients` — primary (CTA/hero), progressFill, glassOverlay, heroGlow
- `AppText` — displayLarge, displaySmall, title, body, caption
- `AppSpacing` — xs/sm/md/lg/xl/xxl + screenH, sectionGap
- `AppRadius` — sm/md/lg/full

No hardcoded colors, sizes, or spacing anywhere in widget code.

---

## Point Formula Reference

| Category | Weight |
| -------- | ------ |
| Work     | 1.3    |
| Study    | 1.2    |
| Health   | 1.1    |
| Hobby    | 0.8    |
| Fun      | 0.5    |

Streak bonus: `1 + (streakDays × 0.05)`

---

## License

Private — all rights reserved.
