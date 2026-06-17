import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/presentation/providers/reward_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'package:earnjoy/domain/usecases/reward_service.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'widgets/add_reward_bottom_sheet.dart';
import 'widgets/reward_card.dart';
import 'widgets/template_card.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with TickerProviderStateMixin {
  bool _showCelebration = false;
  String _redeemedRewardName = '';
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnim;
  late TabController _tabController;

  bool _showArchive = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _celebrationController, curve: Curves.easeIn);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Redeem flow ───────────────────────────────────────────────────────────

  Future<void> _confirmRedeem(
    BuildContext context,
    int rewardId,
    String name,
    double pointCost,
    double userBalance,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RedeemConfirmSheet(
          rewardName: name, rewardCost: pointCost, userBalance: userBalance),
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      _executeRedeem(context, rewardId, name);
    }
  }

  Future<void> _executeRedeem(
      BuildContext context, int rewardId, String name) async {
    final rewardProvider = context.read<RewardProvider>();
    final userProvider = context.read<UserProvider>();
    final storage = context.read<StorageService>();

    final rewardService = RewardService(storage);
    if (rewardService.isMonthlyBudgetExceeded(userProvider.user)) {
      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Monthly budget terlampaui.');
      return;
    }

    final success = rewardProvider.redeem(rewardId);
    if (!success) {
      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Balance tidak cukup atau reward belum tersedia.');
      return;
    }

    userProvider.loadUser();

    HapticFeedback.heavyImpact();

    setState(() {
      _showCelebration = true;
      _redeemedRewardName = name;
    });
    await _celebrationController.forward(from: 0);

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      await _celebrationController.reverse();
      if (mounted) setState(() => _showCelebration = false);
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body.copyWith(color: Colors.white)),
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openAddReward(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const AddRewardBottomSheet(),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userBalance =
        context.select<UserProvider, double>((p) => p.user.pointBalance);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Points Wallet Card Header ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.lg,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: _PointsWalletCard(userBalance: userBalance),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── TabBar ────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppText.body.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: AppText.body.copyWith(fontSize: 13),
                    tabs: const [
                      Tab(text: 'Wishlist'),
                      Tab(text: 'Shop'),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Tab Views ─────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _WishlistTab(
                        userBalance: userBalance,
                        showArchive: _showArchive,
                        onToggleArchive: () =>
                            setState(() => _showArchive = !_showArchive),
                        onConfirmRedeem: (id, name, cost) =>
                            _confirmRedeem(context, id, name, cost, userBalance),
                      ),
                      const _ShopTab(),
                    ],
                  ),
                ),

                // ── Add button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.sm,
                    AppSpacing.screenH,
                    AppSpacing.md,
                  ),
                  child: GradientButton(
                    label: 'Tambah Reward',
                    icon: FontAwesomeIcons.plus,
                    onTap: () => _openAddReward(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showCelebration)
          FadeTransition(
            opacity: _fadeAnim,
            child: _CelebrationOverlay(
              rewardName: _redeemedRewardName,
              onDismiss: () async {
                await _celebrationController.reverse();
                if (mounted) setState(() => _showCelebration = false);
              },
            ),
          ),
      ],
    );
  }
}

// ─── Points Wallet Card ──────────────────────────────────────────────────────

class _PointsWalletCard extends StatelessWidget {
  final double userBalance;

  const _PointsWalletCard({required this.userBalance});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final storage = context.read<StorageService>();
    final rewardService = RewardService(storage);
    final budgetUsed = rewardService.monthlyBudgetUsed();
    final monthlyBudget = userProvider.user.monthlyBudget;

    final rewards = context.watch<RewardProvider>().rewards;
    final unlockedCount =
        rewards.where((r) => r.canRedeemWithBalance(userBalance) && !r.isRedeemed).length;

    final hasReady = unlockedCount > 0;
    final bool hasBudget = monthlyBudget > 0;
    final double budgetProgress =
        hasBudget ? (budgetUsed / monthlyBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasReady
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.glassBorder,
          width: hasReady ? 1.5 : 1.0,
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceHigh.withValues(alpha: 0.4),
            AppColors.surface.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: hasReady
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.coins,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Poin',
                    style: AppText.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${userBalance.toPointsLabel} pts',
                    style: AppText.displaySmall.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (hasReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.gift, size: 10, color: AppColors.primaryLight),
                      const SizedBox(width: 4),
                      Text(
                        '$unlockedCount Ready!',
                        style: AppText.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasBudget) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.glassBorder, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Bulanan',
                  style: AppText.caption.copyWith(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${budgetUsed.toPointsLabel} / ${monthlyBudget.toPointsLabel} pts',
                  style: AppText.caption.copyWith(
                    fontSize: 11,
                    color: budgetUsed >= monthlyBudget ? AppColors.error : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    Container(color: AppColors.primaryDim),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: budgetProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: budgetUsed >= monthlyBudget
                              ? const LinearGradient(colors: [AppColors.error, Color(0xFFFFA0A0)])
                              : AppGradients.progressFill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Wishlist Tab ──────────────────────────────────────────────────────────

class _WishlistTab extends StatelessWidget {
  final double userBalance;
  final bool showArchive;
  final VoidCallback onToggleArchive;
  final void Function(int id, String name, double cost) onConfirmRedeem;

  const _WishlistTab({
    required this.userBalance,
    required this.showArchive,
    required this.onToggleArchive,
    required this.onConfirmRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardProvider>();
    final filtered = provider.filteredRewards;
    final archived = provider.archivedRewards;
    final selectedFilter = provider.wishlistCategoryFilter;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Category filter
        SliverToBoxAdapter(
          child: _CategoryFilter(
            selectedCategory: selectedFilter,
            onSelect: (cat) => context
                .read<RewardProvider>()
                .setWishlistCategoryFilter(cat),
          ),
        ),

        // Reward list
        if (filtered.isEmpty)
          const SliverFillRemaining(child: _EmptyWishlist())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final r = filtered[i];
                  return _SlideUpFadeIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: RewardCard(
                        reward: r,
                        userBalance: userBalance,
                        onRedeem: r.canRedeemWithBalance(userBalance) ||
                                (r.recurrenceType == RecurrenceType.recurring &&
                                    r.isRecurringReady &&
                                    r.canRedeemWithBalance(userBalance))
                            ? () => onConfirmRedeem(r.id, r.name, r.pointCost)
                            : null,
                        onDelete: () =>
                            context.read<RewardProvider>().deleteReward(r.id),
                        onArchive: () =>
                            context.read<RewardProvider>().archiveReward(r.id),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),

        // Archive toggle
        if (archived.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
              child: GestureDetector(
                onTap: onToggleArchive,
                child: Row(
                  children: [
                    FaIcon(
                      showArchive
                          ? FontAwesomeIcons.chevronUp
                          : FontAwesomeIcons.chevronDown,
                      size: 14,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${archived.length} reward diarsipkan',
                      style: AppText.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (showArchive)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final r = archived[i];
                    return _SlideUpFadeIn(
                      index: i + 3,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Opacity(
                          opacity: 0.55,
                          child: RewardCard(
                            reward: r,
                            userBalance: userBalance,
                            onDelete: () => context
                                .read<RewardProvider>()
                                .deleteReward(r.id),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: archived.length,
                ),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

// ─── Shop Tab ──────────────────────────────────────────────────────────────

class _ShopTab extends StatelessWidget {
  const _ShopTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RewardProvider>();
    final templates = provider.filteredTemplates;
    final addedNames = provider.addedTemplateNames;
    final selectedFilter = provider.shopCategoryFilter;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, AppSpacing.xs, AppSpacing.screenH, AppSpacing.sm),
            child: Text(
              'Template reward siap pakai — pilih dan langsung tambah ke Wishlist!',
              style: AppText.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _CategoryFilter(
            selectedCategory: selectedFilter,
            onSelect: (cat) =>
                context.read<RewardProvider>().setShopCategoryFilter(cat),
          ),
        ),

        if (templates.isEmpty)
          const SliverFillRemaining(child: _EmptyShop())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final t = templates[i];
                  return _SlideUpFadeIn(
                    index: i,
                    child: TemplateCard(
                      template: t,
                      isAdded: addedNames.contains(t.name),
                      onAdd: () {
                        context.read<RewardProvider>().addFromTemplate(t);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${t.name} ditambahkan ke Wishlist!',
                              style: AppText.body.copyWith(color: Colors.white),
                            ),
                            backgroundColor:
                                AppColors.success.withValues(alpha: 0.9),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: templates.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

// ─── Category Filter Chips ────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onSelect;

  const _CategoryFilter({
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
          stops: [0.0, 0.04, 0.96, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 2),
          children: [
            // "All" chip
            _FilterChip(
              label: 'Semua',
              isSelected: selectedCategory == null,
              onTap: () => onSelect(null),
              emoji: '🌟',
            ),
            const SizedBox(width: 6),
            ...RewardCategory.all.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FilterChip(
                  label: RewardCategory.label(cat),
                  isSelected: selectedCategory == cat,
                  onTap: () => onSelect(selectedCategory == cat ? null : cat),
                  emoji: RewardCategory.emoji(cat),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primary : null,
          color: isSelected ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.glassBorder,
          ),
        ),
        child: Center(
          child: Text(
            '$emoji $label',
            style: AppText.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty States ─────────────────────────────────────────────────────────────

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              alignment: Alignment.center,
              child: const Text('🎁', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Wishlist Kosong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Tambahkan reward impianmu secara kustom atau pilih dari daftar template di tab Shop!',
                style: AppText.body.copyWith(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyShop extends StatelessWidget {
  const _EmptyShop();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              alignment: Alignment.center,
              child: const Text('🛍️', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Shop Kosong',
              style: AppText.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Tidak ada template reward yang tersedia dalam kategori ini.',
                style: AppText.body.copyWith(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Redeem Confirm Sheet ─────────────────────────────────────────────────────

class _RedeemConfirmSheet extends StatelessWidget {
  final String rewardName;
  final double rewardCost;
  final double userBalance;

  const _RedeemConfirmSheet({
    required this.rewardName,
    required this.rewardCost,
    required this.userBalance,
  });

  @override
  Widget build(BuildContext context) {
    final balanceAfter = userBalance - rewardCost;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Redeem Reward?', style: AppText.title.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            rewardName,
            style: AppText.body.copyWith(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Visual points flow indicator
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPointIndicator(userBalance.toPointsLabel, AppColors.textSecondary),
                const SizedBox(width: 12),
                const FaIcon(FontAwesomeIcons.arrowRightLong, size: 14, color: AppColors.textDisabled),
                const SizedBox(width: 12),
                _buildPointIndicator(balanceAfter.toPointsLabel, AppColors.success),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Biaya Redeem',
                  value: '${rewardCost.toPointsLabel} pts',
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: 'Balance Kamu',
                  value: '${userBalance.toPointsLabel} pts',
                  valueColor: AppColors.textPrimary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
                _InfoRow(
                  label: 'Sisa Setelah Redeem',
                  value: '${balanceAfter.toPointsLabel} pts',
                  valueColor: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                  child: Text('Redeem Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: Center(
                child: Text('Batal',
                    style: AppText.body
                        .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointIndicator(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.coins, color: AppColors.primaryLight, size: 12),
          const SizedBox(width: 6),
          Text(
            '$value pts',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: AppText.body
              .copyWith(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Celebration Overlay ───────────────────────────────────────────────────────

class _CelebrationOverlay extends StatelessWidget {
  final String rewardName;
  final VoidCallback onDismiss;

  const _CelebrationOverlay(
      {required this.rewardName, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.82),
              ),
            ),
          ),

          // 2. Confetti Particles Shower
          const Positioned.fill(
            child: _ConfettiShower(),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                _PulsingWidget(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const FaIcon(
                      FontAwesomeIcons.gift,
                      color: AppColors.primaryLight,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                const Text(
                  'Selamat! 🎉',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'Kamu berhasil menukarkan reward:',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      rewardName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                const Text(
                  'Kamu layak mendapatkannya! ✨',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    0,
                    AppSpacing.screenH,
                    AppSpacing.lg,
                  ),
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Klaim & Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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

class _PulsingWidget extends StatefulWidget {
  final Widget child;
  const _PulsingWidget({required this.child});

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

class _ConfettiShower extends StatefulWidget {
  const _ConfettiShower();

  @override
  State<_ConfettiShower> createState() => _ConfettiShowerState();
}

class _ConfettiShowerState extends State<_ConfettiShower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
    ];

    for (int i = 0; i < 45; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * -0.5,
        size: _random.nextDouble() * 6 + 4,
        speed: _random.nextDouble() * 1.5 + 0.8,
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * 3.1415,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2.0,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  double y;
  final double size;
  final double speed;
  final Color color;
  double rotation;
  final double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final currentY = (p.y + progress * p.speed) % 1.2;
      final yPos = currentY * size.height;
      final xPos = p.x * size.width;

      paint.color = p.color;

      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(p.rotation + progress * p.rotationSpeed * 5);

      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SlideUpFadeIn extends StatefulWidget {
  final Widget child;
  final int index;

  const _SlideUpFadeIn({required this.child, required this.index});

  @override
  State<_SlideUpFadeIn> createState() => _SlideUpFadeInState();
}

class _SlideUpFadeInState extends State<_SlideUpFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final startDelay = (widget.index * 60).clamp(0, 360);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(Duration(milliseconds: startDelay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
