import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/presentation/providers/reward_provider.dart';

class AddRewardBottomSheet extends StatefulWidget {
  const AddRewardBottomSheet({super.key});

  @override
  State<AddRewardBottomSheet> createState() => _AddRewardBottomSheetState();
}

class _AddRewardBottomSheetState extends State<AddRewardBottomSheet> {
  final _nameController = TextEditingController();
  final _pointsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final pointCost = double.tryParse(_pointsController.text.trim()) ?? 0;

    context.read<RewardProvider>().addReward(name: name, pointCost: pointCost);

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.md + bottomPadding,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text('Add Reward', style: AppText.title),
            const SizedBox(height: AppSpacing.xs),
            const Text('Tentukan nama dan biaya poin untuk reward ini.', style: AppText.body),

            const SizedBox(height: AppSpacing.lg),

            _InputField(
              label: 'Nama Reward',
              hint: 'Contoh: Kopi Kenangan, Netflix 1 Bulan',
              controller: _nameController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            _InputField(
              label: 'Biaya (poin)',
              hint: 'Contoh: 100',
              controller: _pointsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Masukkan angka lebih dari 0';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            GradientButton(label: 'Tambah Reward', onTap: _submit),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          validator: validator,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body.copyWith(color: AppColors.textDisabled),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
