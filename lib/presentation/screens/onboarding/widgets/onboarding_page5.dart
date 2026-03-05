import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/constants.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';

/// Page 5 — Log first activity with confetti celebration.
class OnboardingPage5 extends StatefulWidget {
  final List<String> selectedGoals;
  final VoidCallback onComplete;

  const OnboardingPage5({
    super.key,
    required this.selectedGoals,
    required this.onComplete,
  });

  @override
  State<OnboardingPage5> createState() => _OnboardingPage5State();
}

class _OnboardingPage5State extends State<OnboardingPage5> {
  late final ConfettiController _confetti;
  bool _logged = false;
  String? _selectedPresetTitle;
  double _earnedPoints = 0;

  /// Filter presets based on selected goals so they feel relevant.
  List<Map<String, dynamic>> get _relevantPresets {
    if (widget.selectedGoals.isEmpty) return presetActivities;

    final goalCategories = <String>{};
    for (final goal in widget.selectedGoals) {
      switch (goal) {
        case 'Work':
          goalCategories.add('Work');
        case 'Study':
          goalCategories.add('Study');
        case 'Health':
          goalCategories.add('Health');
        case 'Balance':
          goalCategories.addAll(['Health', 'Hobby']);
        case 'Finance':
          goalCategories.addAll(['Work', 'Study']);
      }
    }

    final filtered = presetActivities
        .where((p) => goalCategories.contains(p['category'] as String))
        .toList();
    return filtered.isEmpty ? presetActivities : filtered;
  }

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _logActivity(Map<String, dynamic> preset) {
    if (_logged) return;
    HapticFeedback.heavyImpact();

    final activityProvider = context.read<ActivityProvider>();
    final categoryName = preset['category'] as String;
    final categoryId = activityProvider.getCategoryIdByName(categoryName);

    if (categoryId == null) {
      // Category not found — skip silently and finish onboarding
      widget.onComplete();
      return;
    }

    final earned = activityProvider.logActivity(
      title: preset['title'] as String,
      categoryId: categoryId,
      durationMinutes: preset['durationMinutes'] as int,
    );

    if (!mounted) return;

    setState(() {
      _logged = true;
      _earnedPoints = earned ?? 0;
      _selectedPresetTitle = preset['title'] as String;
    });

    _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
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
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!_logged) ...[
                const Center(
                  child: Text('Log Aktivitas\nPertamamu!', style: AppText.displaySmall, textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Center(
                  child: Text(
                    'Pilih satu aktivitas yang ingin kamu catat sekarang.',
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                const Text('Aktivitas untuk kamu', style: AppText.title),
                const SizedBox(height: AppSpacing.sm),

                Expanded(
                  child: ListView.separated(
                    itemCount: _relevantPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final p = _relevantPresets[i];
                      final cat = p['category'] as String;
                      final weight = categoryWeights[cat] ?? 1.0;
                      final pts = (p['durationMinutes'] as int) * weight;
                      return GestureDetector(
                        onTap: () => _logActivity(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDim,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['title'] as String, style: AppText.title),
                                    Text(
                                      '$cat · ${p['durationMinutes']} menit',
                                      style: AppText.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  '+${pts.toStringAsFixed(0)} pts',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: const Text(
                      'Lewati, log nanti',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                // Success state
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            gradient: AppGradients.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '+${_earnedPoints.toStringAsFixed(0)} poin pertamamu! 🎉',
                        style: AppText.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '"$_selectedPresetTitle" berhasil dilog.\nStreakmu dimulai hari ini!',
                        style: AppText.body,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      GradientButton(
                        label: 'Mulai EarnJoy!',
                        icon: Icons.rocket_launch_rounded,
                        onTap: widget.onComplete,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Confetti overlay
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.07,
          numberOfParticles: 25,
          gravity: 0.1,
          colors: const [
            AppColors.primary,
            AppColors.gradientEnd,
            AppColors.warning,
            AppColors.success,
            Colors.white,
          ],
        ),
      ],
    );
  }
}
