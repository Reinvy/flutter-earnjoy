import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/gradient_button.dart';
import 'onboarding_text_field.dart';

class OnboardingPage2 extends StatelessWidget {
  final TextEditingController incomeController;
  final double rewardPercentage;
  final double calculatedBudget;
  final ValueChanged<double> onPercentageChanged;
  final VoidCallback onNext;

  const OnboardingPage2({
    super.key,
    required this.incomeController,
    required this.rewardPercentage,
    required this.calculatedBudget,
    required this.onPercentageChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(rewardPercentage * 100).toStringAsFixed(0)}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Center(child: Text('Atur Budget Reward', style: AppText.displaySmall)),
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: Text(
              'Tentukan berapa banyak yang bisa kamu "berikan" ke dirimu sendiri tiap bulan.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // Income input
          const Text('Penghasilan bulananmu (Rp)', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          OnboardingTextField(
            controller: incomeController,
            hint: 'Contoh: 5000000',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // Reward % slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Persentase reward', style: AppText.title),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  percentLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Berapa % dari penghasilan yang kamu alokasikan untuk reward?',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryDim,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primaryDim,
              trackHeight: 4,
            ),
            child: Slider(
              value: rewardPercentage,
              min: 0.05,
              max: 0.30,
              divisions: 25,
              onChanged: onPercentageChanged,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5%', style: AppText.caption),
              Text('30%', style: AppText.caption),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // Calculated budget preview
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppGradients.glassOverlay,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly budget cap (poin)', style: AppText.caption),
                      const SizedBox(height: 2),
                      Text(
                        calculatedBudget > 0
                            ? '${calculatedBudget.toStringAsFixed(0)} pts/bulan'
                            : 'Isi penghasilan untuk menghitung',
                        style: AppText.title.copyWith(
                          color: calculatedBudget > 0 ? AppColors.primary : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          GradientButton(label: 'Lanjut', icon: Icons.arrow_forward_rounded, onTap: onNext),

          // Skip option
          Center(
            child: TextButton(
              onPressed: onNext,
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
