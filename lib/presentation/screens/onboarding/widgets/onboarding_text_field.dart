import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:earnjoy/core/theme.dart';

/// Shared text field used across onboarding pages.
class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? prefixIconWidget;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const OnboardingTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIconWidget,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppText.title,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body,
        prefixIcon: prefixIconWidget != null
            ? SizedBox(
                width: 48,
                child: Center(child: prefixIconWidget),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
