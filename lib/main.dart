import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/activity_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/user_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/main_shell.dart';
import 'services/storage_service.dart';

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
        ChangeNotifierProvider(create: (_) => RewardProvider(storageService)),
        ChangeNotifierProxyProvider2<UserProvider, RewardProvider, ActivityProvider>(
          create: (_) => ActivityProvider(storageService),
          update: (_, userProvider, rewardProvider, activityProvider) => activityProvider!
            ..setUserProvider(userProvider)
            ..setRewardProvider(rewardProvider),
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

/// Reactive router — watches [UserProvider] so routing stays in sync with
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
