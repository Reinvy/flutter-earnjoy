import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/reward_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'package:earnjoy/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:earnjoy/presentation/screens/shell/main_shell.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';

import 'package:earnjoy/presentation/providers/quest_provider.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(MyApp(storageService: storageService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(create: (_) => UserProvider(storageService)),
        ChangeNotifierProvider(create: (_) => BadgeProvider(storageService)),
        ChangeNotifierProxyProvider<BadgeProvider, RewardProvider>(
          create: (_) => RewardProvider(storageService),
          update: (_, badgeProvider, rewardProvider) => rewardProvider!
            ..setBadgeProvider(badgeProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, QuestProvider>(
          create: (_) => QuestProvider(storageService),
          update: (_, userProvider, questProvider) => questProvider!
            ..setUserProvider(userProvider),
        ),
        ChangeNotifierProxyProvider4<UserProvider, RewardProvider, QuestProvider, BadgeProvider, ActivityProvider>(
          create: (_) => ActivityProvider(storageService),
          update: (_, userProvider, rewardProvider, questProvider, badgeProvider, activityProvider) => activityProvider!
            ..setUserProvider(userProvider)
            ..setRewardProvider(rewardProvider)
            ..setQuestProvider(questProvider)
            ..setBadgeProvider(badgeProvider),
        ),
      ],
      child: MaterialApp(
        title: 'EarnJoy',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _RootRouter(),
      ),
    );
  }
}

/// Reactive router that watches [UserProvider] so routing stays in sync with
/// persisted state (onboarding done / data reset) without needing
/// manual Navigator calls.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final onboardingDone = context.select<UserProvider, bool>((p) => p.user.onboardingDone);
    return onboardingDone ? const MainShell() : const OnboardingScreen();
  }
}
