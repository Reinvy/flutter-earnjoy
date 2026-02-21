import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/user_provider.dart';
import '../shell/main_shell.dart';
import 'widgets/onboarding_page1.dart';
import 'widgets/onboarding_page2.dart';
import 'widgets/onboarding_page3.dart';
import 'widgets/onboarding_progress_dots.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1
  final _nameController = TextEditingController();
  String? _selectedGoal;

  // Page 2
  final _incomeController = TextEditingController();
  double _rewardPercentage = 0.10;

  double get _calculatedBudget {
    final income = double.tryParse(_incomeController.text.trim()) ?? 0.0;
    return income * _rewardPercentage;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _goNext() {
    _pageController.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
  }

  void _complete() {
    final income = double.tryParse(_incomeController.text.trim()) ?? 0.0;
    context.read<UserProvider>().completeOnboarding(
      name: _nameController.text,
      income: income,
      rewardPercentage: _rewardPercentage,
      monthlyBudget: income * _rewardPercentage,
    );
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            OnboardingProgressDots(current: _currentPage, total: 3),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  OnboardingPage1(
                    nameController: _nameController,
                    selectedGoal: _selectedGoal,
                    onGoalSelected: (g) => setState(() => _selectedGoal = g),
                    onNext: _goNext,
                  ),
                  OnboardingPage2(
                    incomeController: _incomeController,
                    rewardPercentage: _rewardPercentage,
                    calculatedBudget: _calculatedBudget,
                    onPercentageChanged: (v) => setState(() => _rewardPercentage = v),
                    onNext: _goNext,
                  ),
                  OnboardingPage3(onComplete: _complete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

