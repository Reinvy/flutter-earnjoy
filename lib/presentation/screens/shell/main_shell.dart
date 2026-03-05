import 'package:flutter/material.dart';

import 'package:earnjoy/core/theme.dart';
import '../home/home_screen.dart';
import '../reward/reward_screen.dart';
import '../profile/profile_screen.dart';
import '../routines/routine_list_screen.dart';
import '../insights/insights_screen.dart';
import '../social/social_screen.dart';
import 'package:provider/provider.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/presentation/widgets/badge_toast.dart';
import 'package:earnjoy/presentation/screens/home/widgets/quick_log_sheet.dart';
import 'dart:async';

/// Root scaffold that owns the [NavigationBar] and switches between the three
/// main screens using an [IndexedStack] to preserve scroll/state across tabs.
class MainShell extends StatefulWidget {
  /// If set (from a widget/shortcut deep-link), the QuickLogSheet is opened
  /// automatically after the first frame, pre-selecting this preset title.
  final String? initialQuickLogTitle;

  const MainShell({super.key, this.initialQuickLogTitle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  StreamSubscription? _badgeSubscription;

  static const _screens = [
    HomeScreen(),
    InsightsScreen(),
    RoutineListScreen(),
    SocialScreen(),
    RewardScreen(),
    ProfileScreen(),
  ];

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
      // Auto-open QuickLogSheet when launched from widget/shortcut
      if (widget.initialQuickLogTitle != null) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => QuickLogSheet(presetTitle: widget.initialQuickLogTitle),
        );
      }
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
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Routines',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Social',
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
