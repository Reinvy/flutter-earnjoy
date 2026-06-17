import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      physics: const BouncingScrollPhysics(),
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

            Text(
              'Tambah Wishlist Reward', 
              style: AppText.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tentukan detail reward impian yang ingin kamu raih.',
              style: AppText.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Emoji Picker ─────────────────────────────────────────
            const _SectionLabel(label: 'Icon Emoji'),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _emojiOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final emoji = _emojiOptions[i];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedEmoji = emoji);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.glassBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
              hint: 'Contoh: Kopi Susu Gula Aren, Beli Baju Baru',
              controller: _nameController,
              icon: FontAwesomeIcons.gift,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Biaya ────────────────────────────────────────────────
            _InputField(
              label: 'Biaya Poin',
              hint: 'Contoh: 150',
              controller: _pointsController,
              icon: FontAwesomeIcons.coins,
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
            const _SectionLabel(label: 'Kategori Reward'),
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
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceHigh.withValues(alpha: 0.5),
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
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // ─── Recurrence ───────────────────────────────────────────
            const _SectionLabel(label: 'Tipe Ketersediaan'),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _RecurrenceChip(
                    label: '1x Saja',
                    icon: FontAwesomeIcons.one,
                    isSelected: _selectedRecurrence == RecurrenceType.once,
                    onTap: () =>
                        setState(() => _selectedRecurrence = RecurrenceType.once),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RecurrenceChip(
                    label: 'Berulang',
                    icon: FontAwesomeIcons.repeat,
                    isSelected: _selectedRecurrence == RecurrenceType.recurring,
                    onTap: () => setState(
                        () => _selectedRecurrence = RecurrenceType.recurring),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RecurrenceChip(
                    label: 'Terbatas',
                    icon: FontAwesomeIcons.calendarDays,
                    isSelected: _selectedRecurrence == RecurrenceType.limited,
                    onTap: () => setState(
                        () => _selectedRecurrence = RecurrenceType.limited),
                  ),
                ),
              ],
            ),

            // Recurring interval stepper
            if (_selectedRecurrence == RecurrenceType.recurring) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Interval Redeem: ', style: AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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

            // Limited monthly stepper
            if (_selectedRecurrence == RecurrenceType.limited) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Maks per bulan: ', style: AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
            const _SectionLabel(label: 'Jadwalkan Penukaran (Opsional)'),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _scheduledFor != null
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.glassBorder,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.calendarDay,
                      size: 16,
                      color: _scheduledFor != null
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _scheduledFor != null
                            ? '${_scheduledFor!.day}/${_scheduledFor!.month}/${_scheduledFor!.year}'
                            : 'Pilih tanggal buka...',
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          color: _scheduledFor != null
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                    if (_scheduledFor != null)
                      GestureDetector(
                        onTap: () => setState(() => _scheduledFor = null),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: FaIcon(FontAwesomeIcons.xmark,
                              size: 14, color: AppColors.textDisabled),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            GradientButton(label: 'Tambah Ke Wishlist', onTap: _submit),

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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          label, 
          style: AppText.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon,
                size: 11,
                color: isSelected ? AppColors.primary : AppColors.textDisabled),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
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
          icon: FontAwesomeIcons.minus,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Text(
            '$value$suffix',
            style: AppText.body.copyWith(
                fontSize: 13,
                color: AppColors.primary, 
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        _StepBtn(
          icon: FontAwesomeIcons.plus,
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.textDisabled.withValues(alpha: 0.05)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.glassBorder),
        ),
        alignment: Alignment.center,
        child: FaIcon(
          icon,
          size: 11,
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
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: AppText.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          validator: validator,
          style: AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body.copyWith(color: AppColors.textDisabled, fontSize: 13),
            filled: true,
            fillColor: AppColors.surfaceHigh.withValues(alpha: 0.5),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(icon, size: 14, color: AppColors.textDisabled),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
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
