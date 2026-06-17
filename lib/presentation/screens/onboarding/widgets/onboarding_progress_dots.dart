import 'package:flutter/material.dart';

import 'package:earnjoy/core/theme.dart';

class OnboardingProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const OnboardingProgressDots({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            gradient: isActive ? AppGradients.primary : null,
            color: isActive ? null : AppColors.textDisabled,
          ),
        );
      }),
    );
  }
}
