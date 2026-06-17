import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'widgets/onboarding_page1.dart';
import 'widgets/onboarding_page2.dart';
import 'widgets/onboarding_page3.dart';
import 'widgets/onboarding_page4.dart';
import 'widgets/onboarding_page5.dart';
import 'widgets/onboarding_progress_dots.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 2 — Identity & Goals
  final _nameController = TextEditingController();
  final Set<String> _selectedGoals = {};

  // Page 3 — Dream Reward
  final _dreamRewardController = TextEditingController();
  String _dreamRewardEmoji = '🎁';

  // Page 4 — Active Hours
  int _activeSlotIndex = -1;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dreamRewardController.dispose();
    super.dispose();
  }

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  void _toggleGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else if (_selectedGoals.length < 3) {
        _selectedGoals.add(goal);
      }
    });
  }

  void _complete() {
    final activeHour = _activeSlotIndex >= 0
        ? _activeHourFromSlot(_activeSlotIndex)
        : -1;

    final income = 0.0; // Income setup is optional; user can set it later in Profile
    const rewardPercentage = 0.10;

    context.read<UserProvider>().completeOnboarding(
      name: _nameController.text,
      income: income,
      rewardPercentage: rewardPercentage,
      monthlyBudget: income * rewardPercentage,
      selectedGoals: _selectedGoals.toList(),
      dreamReward: _dreamRewardController.text.trim(),
      dreamRewardEmoji: _dreamRewardEmoji,
      preferredActiveHour: activeHour,
    );
    HapticFeedback.heavyImpact();
    // _RootRouter will automatically navigate to MainShell when onboardingDone == true
  }

  int _activeHourFromSlot(int slot) {
    const hours = [6, 10, 14, 18];
    if (slot < 0 || slot >= hours.length) return -1;
    return hours[slot];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            OnboardingProgressDots(current: _currentPage, total: 5),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Page 1 — Welcome
                  OnboardingPage1(onNext: _goNext),

                  // Page 2 — Name + Goals
                  OnboardingPage2(
                    nameController: _nameController,
                    selectedGoals: _selectedGoals,
                    onGoalToggled: _toggleGoal,
                    onNext: _goNext,
                  ),

                  // Page 3 — Dream Reward
                  OnboardingPage3(
                    dreamRewardController: _dreamRewardController,
                    selectedCategoryEmoji: _dreamRewardEmoji,
                    onCategorySelected: (e) => setState(() => _dreamRewardEmoji = e),
                    onNext: _goNext,
                  ),

                  // Page 4 — Active Hours
                  OnboardingPage4(
                    selectedSlotIndex: _activeSlotIndex,
                    onSlotSelected: (i) => setState(() => _activeSlotIndex = i),
                    onNext: _goNext,
                  ),

                  // Page 5 — First Log + Confetti
                  OnboardingPage5(
                    selectedGoals: _selectedGoals.toList(),
                    onComplete: _complete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
