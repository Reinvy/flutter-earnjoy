import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'onboarding_text_field.dart';

class _Goal {
  final IconData icon;
  final String label;
  final String description;
  const _Goal(this.icon, this.label, this.description);
}

const _goals = [
  _Goal(Icons.work_outline_rounded, 'Work', 'Produktivitas & karier'),
  _Goal(Icons.school_outlined, 'Study', 'Belajar & akademik'),
  _Goal(Icons.fitness_center, 'Health', 'Kesehatan & olahraga'),
  _Goal(Icons.self_improvement, 'Balance', 'Keseimbangan hidup'),
];

class OnboardingPage1 extends StatefulWidget {
  final TextEditingController nameController;
  final String? selectedGoal;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onNext;

  const OnboardingPage1({
    super.key,
    required this.nameController,
    required this.selectedGoal,
    required this.onGoalSelected,
    required this.onNext,
  });

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1> {
  bool get _canProceed => widget.nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Hero icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Center(child: Text('Selamat datang di EarnJoy', style: AppText.displaySmall)),
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: Text(
              'Earn your rewards. Setiap usaha layak dihargai.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // Name input
          const Text('Siapa namamu?', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          OnboardingTextField(
            controller: widget.nameController,
            hint: 'Nama kamu...',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // Goal selection
          const Text('Apa fokus utamamu?', style: AppText.title),
          const SizedBox(height: AppSpacing.xs),
          const Text('Ini membantu kami menyesuaikan pengalaman untukmu.', style: AppText.body),
          const SizedBox(height: AppSpacing.sm),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
            children: _goals.map((g) {
              final isSelected = widget.selectedGoal == g.label;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onGoalSelected(g.label);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDim : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        g.icon,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        g.label,
                        style: AppText.title.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        g.description,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          GradientButton(
            label: 'Lanjut',
            icon: Icons.arrow_forward_rounded,
            onTap: _canProceed ? widget.onNext : null,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
