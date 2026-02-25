import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/category.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';

/// Displays all categories with options to add new ones and delete existing ones.
class CategoryManager extends StatelessWidget {
  const CategoryManager({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ActivityProvider>().categories;

    return Column(
      children: [
        ...categories.map(
          (cat) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CategoryTile(category: cat),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () => _openAddCategorySheet(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('Add Category', style: AppText.body.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAddCategorySheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ActivityProvider>(),
        child: const _AddCategorySheet(),
      ),
    );
  }
}

// ─── Category Tile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.isNegative
                  ? AppColors.error.withValues(alpha: 0.12)
                  : AppColors.primaryDim,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              _iconData(category.icon),
              color: category.isNegative ? AppColors.error : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(category.name, style: AppText.title),
                    if (category.isNegative) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'negative',
                          style: AppText.caption.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('weight: ${category.weight}', style: AppText.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Icon(Icons.delete_outline, color: AppColors.textDisabled, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete category?', style: AppText.title),
        content: Text(
          'Deleting "${category.name}" will also remove its linked presets.',
          style: AppText.body,
        ),
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
      context.read<ActivityProvider>().deleteCategory(category.id);
    }
  }

  IconData _iconData(String icon) {
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
        return Icons.label_outline;
    }
  }
}

// ─── Add Category Sheet ───────────────────────────────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '1.0');
  bool _isNegative = false;
  String _selectedIcon = 'label_outline';

  static const _icons = [
    ('label_outline', Icons.label_outline),
    ('work', Icons.work_outline),
    ('menu_book', Icons.menu_book_outlined),
    ('fitness_center', Icons.fitness_center),
    ('palette', Icons.palette_outlined),
    ('sports_esports', Icons.sports_esports_outlined),
    ('phone_android', Icons.phone_android),
    ('music_note', Icons.music_note_outlined),
    ('school', Icons.school_outlined),
    ('local_cafe', Icons.local_cafe_outlined),
    ('directions_walk', Icons.directions_walk),
    ('code', Icons.code),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const Text('New Category', style: AppText.title),
          const SizedBox(height: AppSpacing.md),

          // Name
          _field(label: 'Name', controller: _nameController, hint: 'e.g. Meditation'),
          const SizedBox(height: AppSpacing.sm),

          // Weight
          _field(
            label: 'Weight (multiplier)',
            controller: _weightController,
            hint: '1.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Negative toggle
          GestureDetector(
            onTap: () => setState(() => _isNegative = !_isNegative),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: _isNegative ? AppColors.error : AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _isNegative ? Icons.remove_circle : Icons.add_circle_outline,
                    color: _isNegative ? AppColors.error : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _isNegative ? 'Negative (deducts points)' : 'Positive (earns points)',
                      style: AppText.body.copyWith(
                        color: _isNegative ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    _isNegative ? Icons.toggle_on : Icons.toggle_off,
                    color: _isNegative ? AppColors.error : AppColors.textDisabled,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Icon picker
          const Text('Icon', style: AppText.body),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _icons.map(((String key, IconData icon) entry) {
              final selected = _selectedIcon == entry.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = entry.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryDim : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.glassBorder),
                  ),
                  child: Icon(
                    entry.$2,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
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
                child: const Center(child: Text('Add Category', style: AppText.title)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 1.0;
    if (name.isEmpty) return;

    HapticFeedback.mediumImpact();
    context.read<ActivityProvider>().addCategory(
      name: name,
      weight: weight.clamp(0.1, 5.0),
      isNegative: _isNegative,
      icon: _selectedIcon,
    );
    Navigator.pop(context);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
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
