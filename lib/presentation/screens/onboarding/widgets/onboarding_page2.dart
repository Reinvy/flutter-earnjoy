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
  _Goal(Icons.savings_outlined, 'Finance', 'Kontrol pengeluaran'),
  _Goal(Icons.self_improvement, 'Balance', 'Membangun kebiasaan baik'),
];

/// Page 2 — Name input + multi-select goals (up to 3).
class OnboardingPage2 extends StatefulWidget {
  final TextEditingController nameController;
  final Set<String> selectedGoals;
  final ValueChanged<String> onGoalToggled;
  final VoidCallback onNext;

  const OnboardingPage2({
    super.key,
    required this.nameController,
    required this.selectedGoals,
    required this.onGoalToggled,
    required this.onNext,
  });

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2> {
  bool get _canProceed =>
      widget.nameController.text.trim().isNotEmpty && widget.selectedGoals.isNotEmpty;

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

          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Center(child: Text('Siapa kamu?', style: AppText.displaySmall)),
          const SizedBox(height: AppSpacing.xs),
          const Center(
            child: Text(
              'Bantu kami mengenal kamu lebih baik.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          const Text('Nama panggilanmu', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          OnboardingTextField(
            controller: widget.nameController,
            hint: 'Contoh: Rizky',
            icon: Icons.badge_outlined,
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          Row(
            children: [
              const Expanded(child: Text('Tujuan utamamu', style: AppText.title)),
              if (widget.selectedGoals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${widget.selectedGoals.length} dipilih',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Pilih 1–3 yang paling relevan denganmu.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.sm),

          ..._goals.map((g) {
            final isSelected = widget.selectedGoals.contains(g.label);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onGoalToggled(g.label);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDim : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        g.icon,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.label,
                              style: AppText.title.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            Text(g.description, style: AppText.caption),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isSelected ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

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
