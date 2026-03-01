import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/data/models/reward.dart';
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

  // New fields
  String _selectedCategory = RewardCategory.food;
  String _selectedEmoji = '🎁';
  String _selectedRecurrence = RecurrenceType.once;
  int _intervalDays = 7;
  int _monthlyLimit = 2;
  DateTime? _scheduledFor;

  static const _emojiOptions = [
    '🎁', '🍜', '☕', '🍔', '🍕', '🧋', '🍣',
    '🎬', '🎮', '🎵', '📺', '🎪',
    '🛍️', '👗', '👟', '💍',
    '✈️', '🏖️', '⛷️', '🎭', '💆', '🧖',
    '📚', '🎓', '💻', '🎨',
    '😴', '🛁', '🌿',
  ];

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

    context.read<RewardProvider>().addReward(
          name: _nameController.text.trim(),
          pointCost: double.tryParse(_pointsController.text.trim()) ?? 0,
          category: _selectedCategory,
          iconEmoji: _selectedEmoji,
          recurrenceType: _selectedRecurrence,
          recurrenceIntervalDays:
              _selectedRecurrence == RecurrenceType.recurring ? _intervalDays : null,
          monthlyLimit:
              _selectedRecurrence == RecurrenceType.limited ? _monthlyLimit : null,
          scheduledFor: _scheduledFor,
        );

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _scheduledFor = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
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
            // Handle bar
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

            const Text('Tambah Reward', style: AppText.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tentukan detail reward wishlist kamu.',
              style: AppText.body,
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Emoji Picker ─────────────────────────────────────────
            _SectionLabel(label: 'Icon'),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojiOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final emoji = _emojiOptions[i];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.glassBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Nama ─────────────────────────────────────────────────
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

            // ─── Biaya ────────────────────────────────────────────────
            _InputField(
              label: 'Biaya (poin)',
              hint: 'Contoh: 100',
              controller: _pointsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Masukkan angka lebih dari 0';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Kategori ─────────────────────────────────────────────
            _SectionLabel(label: 'Kategori'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: RewardCategory.all.map((cat) {
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.glassBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${RewardCategory.emoji(cat)} ${RewardCategory.label(cat)}',
                      style: AppText.caption.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Recurrence ───────────────────────────────────────────
            _SectionLabel(label: 'Tipe Reward'),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _RecurrenceChip(
                  label: '1x Saja',
                  icon: Icons.looks_one_outlined,
                  isSelected: _selectedRecurrence == RecurrenceType.once,
                  onTap: () =>
                      setState(() => _selectedRecurrence = RecurrenceType.once),
                ),
                const SizedBox(width: 6),
                _RecurrenceChip(
                  label: 'Berulang',
                  icon: Icons.repeat,
                  isSelected: _selectedRecurrence == RecurrenceType.recurring,
                  onTap: () => setState(
                      () => _selectedRecurrence = RecurrenceType.recurring),
                ),
                const SizedBox(width: 6),
                _RecurrenceChip(
                  label: 'Terbatas',
                  icon: Icons.calendar_month_outlined,
                  isSelected: _selectedRecurrence == RecurrenceType.limited,
                  onTap: () => setState(
                      () => _selectedRecurrence = RecurrenceType.limited),
                ),
              ],
            ),

            // Recurring interval
            if (_selectedRecurrence == RecurrenceType.recurring) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Interval: ', style: AppText.body),
                  const Spacer(),
                  _StepperControl(
                    value: _intervalDays,
                    min: 1,
                    max: 30,
                    suffix: ' hari',
                    onChanged: (v) => setState(() => _intervalDays = v),
                  ),
                ],
              ),
            ],

            // Limited monthly count
            if (_selectedRecurrence == RecurrenceType.limited) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Maks per bulan: ', style: AppText.body),
                  const Spacer(),
                  _StepperControl(
                    value: _monthlyLimit,
                    min: 1,
                    max: 20,
                    suffix: 'x',
                    onChanged: (v) => setState(() => _monthlyLimit = v),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // ─── Scheduling ───────────────────────────────────────────
            _SectionLabel(label: 'Jadwalkan Redeem (opsional)'),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _scheduledFor != null
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.glassBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 18,
                      color: _scheduledFor != null
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _scheduledFor != null
                            ? '${_scheduledFor!.day}/${_scheduledFor!.month}/${_scheduledFor!.year}'
                            : 'Pilih tanggal...',
                        style: AppText.body.copyWith(
                          color: _scheduledFor != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                    if (_scheduledFor != null)
                      GestureDetector(
                        onTap: () => setState(() => _scheduledFor = null),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.textDisabled),
                      ),
                  ],
                ),
              ),
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

// ─── Small Helper Widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppText.caption.copyWith(color: AppColors.textSecondary));
}

class _RecurrenceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecurrenceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: isSelected ? AppColors.primary : AppColors.textDisabled),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _StepperControl({
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            '$value$suffix',
            style: AppText.body.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        _StepBtn(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.textDisabled.withValues(alpha: 0.1)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? AppColors.textDisabled : AppColors.textPrimary,
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
