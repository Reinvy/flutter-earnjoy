import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../providers/activity_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';
import 'widgets/action_tile.dart';
import 'widgets/budget_setting.dart';
import 'widgets/user_header.dart';
import 'widgets/weekly_summary_card.dart';

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
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Warning icon ─────────────────────────────────────────
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Title ────────────────────────────────────────────────
              const Text('Reset Semua Data?', style: AppText.title, textAlign: TextAlign.center),

              const SizedBox(height: AppSpacing.sm),

              // ── Body ─────────────────────────────────────────────────
              const Text(
                'Semua aktivitas, reward, dan transaksi akan dihapus permanen. Aksi ini tidak dapat dibatalkan.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Actions ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Batal', style: AppText.title),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              UserHeader(
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
              WeeklySummaryCard(
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
              BudgetSetting(
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

              ActionTile(
                icon: Icons.upload_outlined,
                label: 'Export Data',
                subtitle: 'Simpan semua data sebagai JSON',
                iconColor: AppColors.primary,
                onTap: () => _exportData(context),
              ),

              const SizedBox(height: AppSpacing.sm),

              ActionTile(
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
