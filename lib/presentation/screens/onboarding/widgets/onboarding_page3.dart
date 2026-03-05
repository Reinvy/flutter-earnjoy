import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'onboarding_text_field.dart';

class _RewardCategory {
  final String emoji;
  final String label;
  const _RewardCategory(this.emoji, this.label);
}

const _categories = [
  _RewardCategory('🍔', 'Food & Drink'),
  _RewardCategory('🎮', 'Entertainment'),
  _RewardCategory('🛍️', 'Shopping'),
  _RewardCategory('✈️', 'Experience'),
  _RewardCategory('📚', 'Self-Growth'),
  _RewardCategory('💤', 'Rest'),
];

/// Page 3 — Dream reward input with category selection and point estimate.
class OnboardingPage3 extends StatefulWidget {
  final TextEditingController dreamRewardController;
  final String selectedCategoryEmoji;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onNext;

  const OnboardingPage3({
    super.key,
    required this.dreamRewardController,
    required this.selectedCategoryEmoji,
    required this.onCategorySelected,
    required this.onNext,
  });

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  bool get _canProceed => widget.dreamRewardController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.dreamRewardController.addListener(() => setState(() {}));
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
              child: const Icon(Icons.redeem_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Center(child: Text('Reward Impianmu', style: AppText.displaySmall)),
          const SizedBox(height: AppSpacing.xs),
          const Center(
            child: Text(
              'Apa yang paling kamu inginkan sebagai\nhadiah untuk dirimu sendiri?',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          const Text('Nama reward-mu', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          OnboardingTextField(
            controller: widget.dreamRewardController,
            hint: 'Contoh: Makan di Restoran Favorit',
            icon: Icons.favorite_outline_rounded,
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          const Text('Kategori', style: AppText.title),
          const SizedBox(height: AppSpacing.xs),
          const Text('Pilih yang paling sesuai.', style: AppText.body),
          const SizedBox(height: AppSpacing.sm),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
            children: _categories.map((cat) {
              final isSelected = widget.selectedCategoryEmoji == cat.emoji;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onCategorySelected(cat.emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDim : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.glassBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text(
                        cat.label.split(' ').first,
                        style: AppText.caption.copyWith(
                          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (_canProceed) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: AppGradients.glassOverlay,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Text(widget.selectedCategoryEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dreamRewardController.text.trim(),
                          style: AppText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Reward pertamamu sudah siap! 🎉',
                          style: AppText.caption.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sectionGap),

          GradientButton(
            label: 'Lanjut',
            icon: Icons.arrow_forward_rounded,
            onTap: _canProceed ? widget.onNext : null,
          ),

          Center(
            child: TextButton(
              onPressed: widget.onNext,
              child: const Text(
                'Lewati, atur nanti',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
