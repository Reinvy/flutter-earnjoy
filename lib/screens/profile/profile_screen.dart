import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../providers/activity_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  bool _editingName = false;
  bool _editingBudget = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user.name);
    _budgetController = TextEditingController(text: user.monthlyBudget.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _saveName() {
    context.read<UserProvider>().updateName(_nameController.text);
    setState(() => _editingName = false);
    HapticFeedback.selectionClick();
  }

  void _saveBudget() {
    final value = double.tryParse(_budgetController.text.trim());
    if (value != null && value >= 0) {
      context.read<UserProvider>().updateMonthlyBudget(value);
    }
    setState(() => _editingBudget = false);
    HapticFeedback.selectionClick();
  }

  Future<void> _exportData(BuildContext context) async {
    final storage = context.read<StorageService>();
    final json = storage.exportJson();
    await Share.share(json, subject: 'EarnJoy Data Export');
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Reset Semua Data?', style: AppText.title),
        content: const Text(
          'Semua aktivitas, reward, dan transaksi akan dihapus permanen. '
          'Aksi ini tidak dapat dibatalkan.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<StorageService>().resetAllData();
      context.read<UserProvider>().loadUser();
      context.read<ActivityProvider>().loadTodayActivities();
      context.read<RewardProvider>().refresh();
      HapticFeedback.heavyImpact();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Semua data telah direset.', style: AppText.body),
            backgroundColor: AppColors.surfaceHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final storage = context.read<StorageService>();
    final totalEarned = storage.getTotalEarnedPoints();
    final weeklyActivities = storage.getWeeklyActivitiesCount();
    final weeklyPoints = storage.getWeeklyEarnedPoints();
    final weeklyRedeemed = storage.getWeeklyRedeemedCount();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── Avatar + Name ─────────────────────────────────────────
              _UserHeader(
                user: user,
                totalEarned: totalEarned,
                editingName: _editingName,
                nameController: _nameController,
                onEditTap: () {
                  setState(() {
                    _editingName = true;
                    _editingBudget = false;
                  });
                },
                onSaveName: _saveName,
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Weekly Summary ────────────────────────────────────────
              const Text('Weekly Summary', style: AppText.title),
              const SizedBox(height: AppSpacing.sm),
              _WeeklySummaryCard(
                activitiesCount: weeklyActivities,
                pointsEarned: weeklyPoints,
                redeemedCount: weeklyRedeemed,
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Monthly Budget ────────────────────────────────────────
              const Text('Monthly Budget Cap', style: AppText.title),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Batas poin yang bisa kamu redeem dalam satu bulan. Isi 0 untuk unlimited.',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.sm),
              _BudgetSetting(
                user: user,
                editing: _editingBudget,
                controller: _budgetController,
                onEditTap: () {
                  setState(() {
                    _editingBudget = true;
                    _editingName = false;
                  });
                },
                onSave: _saveBudget,
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ── Data Actions ──────────────────────────────────────────
              const Text('Data', style: AppText.title),
              const SizedBox(height: AppSpacing.sm),

              _ActionTile(
                icon: Icons.upload_outlined,
                label: 'Export Data',
                subtitle: 'Simpan semua data sebagai JSON',
                iconColor: AppColors.primary,
                onTap: () => _exportData(context),
              ),

              const SizedBox(height: AppSpacing.sm),

              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Reset Semua Data',
                subtitle: 'Hapus semua aktivitas, reward, dan transaksi',
                iconColor: AppColors.error,
                onTap: () => _confirmReset(context),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  final dynamic user;
  final double totalEarned;
  final bool editingName;
  final TextEditingController nameController;
  final VoidCallback onEditTap;
  final VoidCallback onSaveName;

  const _UserHeader({
    required this.user,
    required this.totalEarned,
    required this.editingName,
    required this.nameController,
    required this.onEditTap,
    required this.onSaveName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(
              (user.name as String).isNotEmpty ? (user.name as String)[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (editingName)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        autofocus: true,
                        style: AppText.title,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => onSaveName(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: onSaveName,
                      child: const Icon(Icons.check, color: AppColors.success, size: 22),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: onEditTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.name as String, style: AppText.title),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.textDisabled),
                    ],
                  ),
                ),

              const SizedBox(height: 2),
              Text(
                '${(totalEarned).toStringAsFixed(0)} pts earned all-time',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final int activitiesCount;
  final double pointsEarned;
  final int redeemedCount;

  const _WeeklySummaryCard({
    required this.activitiesCount,
    required this.pointsEarned,
    required this.redeemedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Activities',
            value: '$activitiesCount',
            icon: Icons.directions_run,
            color: AppColors.primary,
          ),
          _Divider(),
          _StatItem(
            label: 'Points',
            value: pointsEarned >= 1000
                ? '${(pointsEarned / 1000).toStringAsFixed(1)}k'
                : pointsEarned.toStringAsFixed(0),
            icon: Icons.star_outline,
            color: AppColors.warning,
          ),
          _Divider(),
          _StatItem(
            label: 'Redeemed',
            value: '$redeemedCount',
            icon: Icons.redeem,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.glassBorder,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.displaySmall.copyWith(fontSize: 22, color: AppColors.textPrimary),
          ),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _BudgetSetting extends StatelessWidget {
  final dynamic user;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onEditTap;
  final VoidCallback onSave;

  const _BudgetSetting({
    required this.user,
    required this.editing,
    required this.controller,
    required this.onEditTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Budget Cap (poin)', style: AppText.caption),
                const SizedBox(height: 2),
                if (editing)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          style: AppText.title,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 6,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => onSave(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: onSave,
                        child: const Icon(Icons.check, color: AppColors.success, size: 22),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: onEditTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (user.monthlyBudget as double) == 0
                              ? 'Unlimited'
                              : '${(user.monthlyBudget as double).toStringAsFixed(0)} pts',
                          style: AppText.title,
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined, size: 14, color: AppColors.textDisabled),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.title),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 20),
          ],
        ),
      ),
    );
  }
}
