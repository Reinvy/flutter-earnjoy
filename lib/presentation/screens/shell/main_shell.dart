import 'package:flutter/material.dart';

import 'package:earnjoy/core/theme.dart';
import '../home/home_screen.dart';
import '../reward/reward_screen.dart';
import '../profile/profile_screen.dart';
import '../routines/routine_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/presentation/widgets/badge_toast.dart';
import 'dart:async';

/// Root scaffold that owns the [NavigationBar] and switches between the three
/// main screens using an [IndexedStack] to preserve scroll/state across tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  StreamSubscription? _badgeSubscription;

  static const _screens = [HomeScreen(), RoutineListScreen(), RewardScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
      _badgeSubscription = badgeProvider.onBadgeUnlocked.listen((badge) {
        if (mounted) {
          GlobalBadgeToast.show(context, badge);
        }
      });
    });
  }

  @override
  void dispose() {
    _badgeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Routines',
          ),
          NavigationDestination(
            icon: Icon(Icons.redeem_outlined),
            selectedIcon: Icon(Icons.redeem_rounded),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
