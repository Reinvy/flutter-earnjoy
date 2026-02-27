import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/activity_preset.dart';
import 'package:earnjoy/data/models/category.dart';
import 'package:earnjoy/domain/usecases/point_engine.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'package:earnjoy/presentation/widgets/level_up_dialog.dart' as import_level_up;

/// Modal bottom sheet showing dynamic activity presets.
/// Users can tap a preset to log it, long-press to delete, or tap "+" to add new.
class QuickAddBottomSheet extends StatelessWidget {
  const QuickAddBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final presets = provider.presets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Activity', style: AppText.title),
                GestureDetector(
                  onTap: () => _openAddPresetSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Add Activity',
                          style: AppText.caption.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (presets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    'No activities yet. Tap "Add Activity" to create one.',
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) => _PresetTile(preset: presets[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddPresetSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ActivityProvider>(),
        child: const _AddPresetSheet(),
      ),
    );
  }
}

// ─── Preset Tile ──────────────────────────────────────────────────────────────

class _PresetTile extends StatelessWidget {
  final ActivityPreset preset;
  const _PresetTile({required this.preset});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final categoryId = preset.category.targetId;
    final penaltyCount = provider.penaltyCountForCategory(categoryId);
    final hasPenalty = penaltyCount > 0;

    // Approximate penalty factor for display
    final penaltyFactor = hasPenalty
        ? (PointEngine.applyDiminishingReturn(1.0, penaltyCount) * 100).round()
        : 100;

    return GestureDetector(
      onTap: () => _log(context),
      onLongPress: () => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _iconForCategory(preset.category.target?.icon ?? ''),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preset.title, style: AppText.title),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${preset.category.target?.name ?? '—'}  ·  ${preset.durationMinutes.minutesToLabel}',
                        style: AppText.caption,
                      ),
                      if (hasPenalty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '×$penaltyFactor%',
                            style: AppText.caption.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _log(BuildContext context) {
    HapticFeedback.mediumImpact();
    final activityProvider = context.read<ActivityProvider>();
    final userProvider = context.read<UserProvider>();
    
    final categoryId = preset.category.targetId;
    final int oldLevel = userProvider.currentLevel;
    
    final earned = activityProvider.logActivity(
      title: preset.title,
      categoryId: categoryId,
      durationMinutes: preset.durationMinutes,
    );
    
    final int newLevel = userProvider.currentLevel;
    if (newLevel > oldLevel) {
      import_level_up.LevelUpDialog.show(context, newLevel, userProvider.currentTierName);
    }
    
    Navigator.pop(context, earned);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete preset?', style: AppText.title),
        content: Text('Remove "${preset.title}" from the list?', style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ActivityProvider>().deletePreset(preset.id);
    }
  }

  IconData _iconForCategory(String icon) {
    switch (icon) {
      case 'work':
        return Icons.work_outline;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'palette':
        return Icons.palette_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'phone_android':
        return Icons.phone_android;
      default:
        return Icons.star_outline;
    }
  }
}

// ─── Add Preset Sheet ─────────────────────────────────────────────────────────

class _AddPresetSheet extends StatefulWidget {
  const _AddPresetSheet();

  @override
  State<_AddPresetSheet> createState() => _AddPresetSheetState();
}

class _AddPresetSheetState extends State<_AddPresetSheet> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  Category? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ActivityProvider>().categories;
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
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
          const SizedBox(height: AppSpacing.md),
          const Text('New Activity Preset', style: AppText.title),
          const SizedBox(height: AppSpacing.md),

          // Title field
          _InputField(
            controller: _titleController,
            label: 'Activity name',
            hint: 'e.g. Morning Yoga',
          ),
          const SizedBox(height: AppSpacing.sm),

          // Duration field
          _InputField(
            controller: _durationController,
            label: 'Duration (minutes)',
            hint: '30',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category picker
          const Text('Category', style: AppText.body),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: categories.map((cat) {
              final selected = _selectedCategory?.id == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryDim : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder),
                  ),
                  child: Text(
                    cat.name,
                    style: AppText.caption.copyWith(
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Center(child: Text('Add Preset', style: AppText.title)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (title.isEmpty || duration <= 0 || _selectedCategory == null) return;

    HapticFeedback.mediumImpact();
    context.read<ActivityProvider>().addPreset(
      title: title,
      categoryId: _selectedCategory!.id,
      durationMinutes: duration,
    );
    Navigator.pop(context);
  }
}

// ─── Input Field helper ───────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppText.title,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.caption,
            filled: true,
            fillColor: AppColors.surfaceHigh,
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
