import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingPage3 extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingPage3({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Center(child: Text('Aktivitasmu Sudah Siap!', style: AppText.displaySmall)),
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: Text(
              'Berikut preset aktivitas yang bisa langsung kamu log. Kamu juga bisa tambahkan aktivitas custom kapan saja.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          const Text('Aktivitas Tersedia', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),

          ...presetActivities.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PresetActivityRow(preset: p),
            ),
          ),

          const Spacer(),

          GradientButton(
            label: 'Mulai Sekarang!',
            icon: Icons.rocket_launch_rounded,
            onTap: onComplete,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ── Private sub-widget ────────────────────────────────────────────────────────

class _PresetActivityRow extends StatelessWidget {
  final Map<String, dynamic> preset;

  const _PresetActivityRow({required this.preset});

  String get _weightLabel {
    final w = categoryWeights[preset['category'] as String] ?? 1.0;
    return '×$w';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.directions_run, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preset['title'] as String, style: AppText.title),
                Text(
                  '${preset['category']} · ${preset['durationMinutes']} menit',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              _weightLabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
