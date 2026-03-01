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
import 'package:earnjoy/presentation/providers/event_provider.dart';
import 'package:earnjoy/presentation/providers/season_provider.dart';
import 'package:earnjoy/presentation/providers/habit_stack_provider.dart';
import 'package:earnjoy/presentation/providers/insights_provider.dart';
import 'package:earnjoy/presentation/providers/notification_provider.dart';
import 'package:earnjoy/domain/usecases/notification_service.dart';
import 'package:earnjoy/presentation/providers/wellbeing_provider.dart';
import 'package:earnjoy/domain/usecases/widget_sync_service.dart';
import 'package:home_widget/home_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  // Initialize notification service before app starts
  final notificationService = SmartNotificationService();
  await notificationService.initialize();

  // Seed initial widget data on first launch
  final user = storageService.getUser();
  await WidgetSyncService.updateWidget(user);

  runApp(MyApp(storageService: storageService, notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final SmartNotificationService notificationService;

  const MyApp({super.key, required this.storageService, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(create: (_) => SeasonProvider(storageService)),
        ChangeNotifierProxyProvider<SeasonProvider, UserProvider>(
          create: (_) => UserProvider(storageService),
          update: (_, season, user) => user!..setSeasonProvider(season),
        ),
        ChangeNotifierProvider(create: (_) => EventProvider(storageService)),
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
        // NotificationProvider must be registered BEFORE ActivityProvider.
        ChangeNotifierProxyProvider<UserProvider, NotificationProvider>(
          create: (_) => NotificationProvider(storageService, notificationService),
          update: (_, userProvider, notificationProvider) =>
            notificationProvider!..setUserProvider(userProvider),
        ),
        // WellbeingProvider must be registered BEFORE ActivityProvider so it
        // can be injected into ActivityProvider via Provider.of in the update.
        ChangeNotifierProvider<WellbeingProvider>(
          create: (_) => WellbeingProvider(storageService),
        ),
        ChangeNotifierProxyProvider6<UserProvider, RewardProvider, QuestProvider, BadgeProvider, EventProvider, NotificationProvider, ActivityProvider>(
          create: (_) => ActivityProvider(storageService),
          update: (context, userProvider, rewardProvider, questProvider, badgeProvider, eventProvider, notificationProvider, activityProvider) {
            final wellbeing = Provider.of<WellbeingProvider>(context, listen: false);
            return activityProvider!
              ..setUserProvider(userProvider)
              ..setRewardProvider(rewardProvider)
              ..setQuestProvider(questProvider)
              ..setBadgeProvider(badgeProvider)
              ..setEventProvider(eventProvider)
              ..setNotificationProvider(notificationProvider)
              ..setWellbeingProvider(wellbeing);
          },
        ),
        ChangeNotifierProxyProvider2<UserProvider, ActivityProvider, HabitStackProvider>(
          create: (context) => HabitStackProvider(
            storageService,
            Provider.of<UserProvider>(context, listen: false),
            Provider.of<ActivityProvider>(context, listen: false),
          ),
          update: (_, userProvider, activityProvider, habitStackProvider) => 
            HabitStackProvider(storageService, userProvider, activityProvider),
        ),
        ChangeNotifierProxyProvider<ActivityProvider, InsightsProvider>(
          create: (_) => InsightsProvider(storageService),
          update: (_, activityProvider, insightsProvider) => insightsProvider!..refresh(),
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

/// Reactive router that watches [UserProvider] and also handles deep-links
/// from home screen widget buttons and app shortcuts.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  /// Set when a quick-log deep-link arrives before the widget tree is ready.
  String? _pendingQuickLogTitle;

  @override
  void initState() {
    super.initState();
    // Handle widget tap while app is running in the background.
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null && mounted) _handleUri(uri);
    });
    // Handle the URI that cold-started the app via a widget/shortcut click.
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null && mounted) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    if (uri.host == 'quick_log') {
      setState(() {
        _pendingQuickLogTitle = uri.queryParameters['title'];
      });
    }
    // earnjoy://tab?index=N or earnjoy://home → no additional action needed;
    // simply opening the app navigates to the main shell.
  }

  @override
  Widget build(BuildContext context) {
    final onboardingDone = context.select<UserProvider, bool>((p) => p.user.onboardingDone);
    return onboardingDone
        ? MainShell(initialQuickLogTitle: _pendingQuickLogTitle)
        : const OnboardingScreen();
  }
}
