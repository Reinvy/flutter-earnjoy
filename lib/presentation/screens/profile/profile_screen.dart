import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'widgets/action_tile.dart';
import 'widgets/budget_setting.dart';
import 'widgets/category_manager.dart';
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

              const Text('Weekly Summary', style: AppText.title),
              const SizedBox(height: AppSpacing.sm),
              WeeklySummaryCard(
                activitiesCount: weeklyActivities,
                pointsEarned: weeklyPoints,
                redeemedCount: weeklyRedeemed,
              ),

              const SizedBox(height: AppSpacing.sectionGap),
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

              const Text('Categories', style: AppText.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Manage your categories. Long-press a preset in Log Activity to delete it.',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.sm),
              ChangeNotifierProvider.value(
                value: context.read<ActivityProvider>(),
                child: const CategoryManager(),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              const Text('Data', style: AppText.title),
              const SizedBox(height: AppSpacing.sm),

              ActionTile(
                icon: Icons.upload_outlined,
                label: 'Export Data',
                subtitle: 'Simpan semua data sebagai JSON',
                iconColor: AppColors.primary,
                onTap: () => _exportData(context),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
