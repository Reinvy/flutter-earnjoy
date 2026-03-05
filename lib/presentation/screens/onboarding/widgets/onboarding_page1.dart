import 'package:flutter/material.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';

/// Page 1 — Welcome screen with animated hero icon and tagline.
class OnboardingPage1 extends StatefulWidget {
  final VoidCallback onNext;

  const OnboardingPage1({super.key, required this.onNext});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Animated hero icon
          ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 60),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          FadeTransition(
            opacity: _fadeAnim,
            child: const Text(
              'Selamat datang di\nEarnJoy.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1.0,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          FadeTransition(
            opacity: _fadeAnim,
            child: const Text(
              'Kamu layak mendapat yang terbaik\n— tapi harus diusahakan dulu.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(flex: 3),

          // Feature highlights
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _FeatureHint(
                  icon: Icons.emoji_events_rounded,
                  text: 'Log aktivitas → dapatkan poin',
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureHint(
                  icon: Icons.redeem_rounded,
                  text: 'Tukar poin dengan reward impianmu',
                ),
                const SizedBox(height: AppSpacing.sm),
                _FeatureHint(
                  icon: Icons.local_fire_department_rounded,
                  text: 'Bangun streak & tingkatkan level',
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          GradientButton(
            label: 'Mulai Setup',
            icon: Icons.arrow_forward_rounded,
            onTap: widget.onNext,
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _FeatureHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryDim,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppText.body),
      ],
    );
  }
}
