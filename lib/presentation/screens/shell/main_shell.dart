import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/badge_provider.dart';
import 'package:earnjoy/presentation/widgets/badge_toast.dart';
import 'package:earnjoy/presentation/screens/home/widgets/quick_log_sheet.dart';
import '../home/home_screen.dart';
import '../insights/insights_screen.dart';
import '../reward/reward_screen.dart';
import '../profile/profile_screen.dart';

// ─── Nav item model ────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

const _navItems = [
  _NavItem(icon: FontAwesomeIcons.house,     label: 'Home'),
  _NavItem(icon: FontAwesomeIcons.chartLine, label: 'Insights'),
  _NavItem(icon: FontAwesomeIcons.gift,      label: 'Rewards'),
  _NavItem(icon: FontAwesomeIcons.user,      label: 'Profile'),
];

// ─── Main Shell ───────────────────────────────────────────────────────────────

/// Root scaffold with a clean floating pill navigation bar (4 tabs, icon-only).
class MainShell extends StatefulWidget {
  final String? initialQuickLogTitle;
  const MainShell({super.key, this.initialQuickLogTitle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  StreamSubscription? _badgeSub;

  static const _screens = [
    HomeScreen(),
    InsightsScreen(),
    RewardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final badges = Provider.of<BadgeProvider>(context, listen: false);
      _badgeSub = badges.onBadgeUnlocked.listen((badge) {
        if (mounted) GlobalBadgeToast.show(context, badge);
      });
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
    _badgeSub?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Nav bar total height: 64 pill + 16 bottom margin + bottomInset
    const navBarHeight = 64.0;
    const navBarMarginBottom = 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content area — padded so nothing hides beneath floating nav bar
          Padding(
            padding: EdgeInsets.only(
              bottom: navBarHeight + navBarMarginBottom + bottomInset,
            ),
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
          // Floating pill nav bar
          Positioned(
            left: 20,
            right: 20,
            bottom: navBarMarginBottom + bottomInset,
            child: _FloatingNavBar(
              selectedIndex: _selectedIndex,
              onTabTapped: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating Pill Nav Bar ────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_navItems.length, (index) {
          return Expanded(
            child: _NavTab(
              item: _navItems[index],
              isSelected: selectedIndex == index,
              onTap: () => onTabTapped(index),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Individual Nav Tab ───────────────────────────────────────────────────────

class _NavTab extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    // Press-down squeeze then spring back
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0), weight: 65),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final iconColor = isSelected ? AppColors.primary : AppColors.textDisabled;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with smooth color transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: FaIcon(
                  widget.item.icon,
                  key: ValueKey(isSelected),
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 6),
              // Dot indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: isSelected ? 6 : 0,
                height: isSelected ? 6 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
