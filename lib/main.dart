import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/activity_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home/home_screen.dart';
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
        ChangeNotifierProxyProvider<UserProvider, ActivityProvider>(
          create: (_) => ActivityProvider(storageService),
          update: (_, userProvider, activityProvider) =>
              activityProvider!..setUserProvider(userProvider),
        ),
      ],
      child: MaterialApp(
        title: 'EarnJoy',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
