import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/social_provider.dart';

class GroupChallengeSheet extends StatefulWidget {
  const GroupChallengeSheet({super.key});

  @override
  State<GroupChallengeSheet> createState() => _GroupChallengeSheetState();
}

class _GroupChallengeSheetState extends State<GroupChallengeSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController(text: '10000');
  int _selectedDuration = 7;

  final List<String> _memberNames = [];
  final _memberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty || _memberNames.length >= 5) return;
    setState(() => _memberNames.add(name));
    _memberController.clear();
  }

  void _submit(BuildContext ctx) {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim()) ?? 10000;
    if (name.isEmpty) return;

    final social = ctx.read<SocialProvider>();
    final success = social.createGroupChallenge(
      name: name,
      description: _descController.text.trim(),
      targetPoints: target,
      durationDays: _selectedDuration,
      memberNames: _memberNames,
    );

    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.pop(ctx);
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Sudah ada group challenge aktif!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const Text('Buat Group Challenge', style: AppText.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Tantang tim kamu kumpulkan poin bersama dalam periode tertentu.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInput('Nama challenge', _nameController, icon: Icons.flag_outlined),
          const SizedBox(height: AppSpacing.sm),
          _buildInput('Deskripsi (opsional)', _descController, icon: Icons.notes),
          const SizedBox(height: AppSpacing.sm),
          _buildInput('Target poin kolektif', _targetController,
              icon: Icons.bolt, keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          // Duration picker
          const Text('Durasi', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [3, 7, 14].map((d) {
              final selected = _selectedDuration == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDuration = d),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        '$d hari',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          // Members
          const Text('Anggota Tim (maks. 5 orang + kamu)', style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _memberController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Nama anggota',
                    hintStyle: AppText.body.copyWith(color: AppColors.textDisabled),
                    prefixIcon: const Icon(Icons.person_add_outlined, color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addMember,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
          if (_memberNames.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _memberNames.map((name) {
                return Chip(
                  label: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  backgroundColor: AppColors.surfaceHigh,
                  deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textDisabled),
                  onDeleted: () => setState(() => _memberNames.remove(name)),
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Mulai Challenge', style: TextStyle(fontWeight: FontWeight.w700)),
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
