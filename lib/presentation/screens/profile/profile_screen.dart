import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'widgets/badge_grid.dart';
import 'widgets/notification_settings_card.dart';
import 'widgets/cloud_sync_card.dart';
import 'package:earnjoy/presentation/screens/social/social_screen.dart';

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

              // ─── Kategori 1: Profil & Statistik ─────────────────────────────
              ProfileSectionCard(
                title: 'Profil & Statistik',
                icon: FontAwesomeIcons.solidUser,
                children: [
                  UserHeader(
                    user: user,
                    totalEarned: totalEarned,
                    editingName: _editingName,
                    nameController: _nameController,
                    level: context.watch<UserProvider>().currentLevel,
                    tierName: context.watch<UserProvider>().currentTierName,
                    xpProgress: context.watch<UserProvider>().xpProgress,
                    xpForNextLevel: context.watch<UserProvider>().xpForNextLevel,
                    onEditTap: () {
                      setState(() {
                        _editingName = true;
                        _editingBudget = false;
                      });
                    },
                    onSaveName: _saveName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ringkasan Mingguan',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  WeeklySummaryCard(
                    activitiesCount: weeklyActivities,
                    pointsEarned: weeklyPoints,
                    redeemedCount: weeklyRedeemed,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Lencana & Pencapaian',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const BadgeGrid(),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Kategori 2: Target & Kategori ─────────────────────────────
              ProfileSectionCard(
                title: 'Target & Kategori',
                icon: FontAwesomeIcons.bullseye,
                children: [
                  Text(
                    'Batas Budget Bulanan',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Batas poin yang bisa kamu redeem dalam satu bulan. Isi 0 untuk unlimited.',
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Kategori Aktivitas',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kelola kategori aktivitasmu. Tekan lama preset di Log Aktivitas untuk menghapusnya.',
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  ChangeNotifierProvider.value(
                    value: context.read<ActivityProvider>(),
                    child: const CategoryManager(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Kategori 3: Sistem & Cloud Sync ───────────────────────────
              ProfileSectionCard(
                title: 'Sistem & Cloud Sync',
                icon: FontAwesomeIcons.sliders,
                children: [
                  Text(
                    'Pengingat Pintar',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pengingat cerdas yang belajar dari pola aktivitasmu.',
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  const NotificationSettingsCard(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sinkronisasi Cloud',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Simpan data ke cloud dan akses dari perangkat lain.',
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  const CloudSyncCard(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sosial & Teman',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ActionTile(
                    icon: FontAwesomeIcons.users,
                    label: 'Sosial',
                    subtitle: 'Partner, duel, dan group challenge',
                    iconColor: AppColors.primaryLight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SocialScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Pencadangan Data',
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ActionTile(
                    icon: FontAwesomeIcons.fileExport,
                    label: 'Ekspor Data',
                    subtitle: 'Simpan semua data sebagai JSON',
                    iconColor: AppColors.primary,
                    onTap: () => _exportData(context),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceHigh.withValues(alpha: 0.15),
            AppColors.surface.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, size: 12, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppText.title.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
