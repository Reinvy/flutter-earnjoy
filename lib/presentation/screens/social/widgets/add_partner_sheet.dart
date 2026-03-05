import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/social_provider.dart';

class AddPartnerSheet extends StatefulWidget {
  const AddPartnerSheet({super.key});

  @override
  State<AddPartnerSheet> createState() => _AddPartnerSheetState();
}

class _AddPartnerSheetState extends State<AddPartnerSheet> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) return;

    ctx.read<SocialProvider>().addPartner(
          name: name,
          inviteCode: code,
          mockStreakDays: 0,
          mockWeeklyPoints: 0,
        );
    HapticFeedback.mediumImpact();
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Tambah Partner', style: AppText.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Minta temanmu share invite code mereka, lalu masukkan di sini.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInput('Nama partner', _nameController, icon: Icons.person_outline),
          const SizedBox(height: AppSpacing.sm),
          _buildInput(
            'Invite code (contoh: AB3H72XK)',
            _codeController,
            icon: Icons.key_outlined,
            uppercase: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Tambahkan Partner', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller, {
    required IconData icon,
    bool uppercase = false,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.words,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: AppColors.textDisabled),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary.withAlpha(180)),
        ),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
