import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      duration: const Duration(milliseconds: 400),
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
    if (!mounted) return;
    if (confirmed == true) {
      // ignore: use_build_context_synchronously
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

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      await _celebrationController.reverse();
      if (mounted) setState(() => _showCelebration = false);
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body),
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
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.lg,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: _ScreenHeader(userBalance: userBalance),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── TabBar ────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: AppText.body.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: AppText.body,
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
                    icon: Icons.add,
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

// ─── Screen Header ────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  final double userBalance;
  const _ScreenHeader({required this.userBalance});

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardProvider>().rewards;
    final unlockedCount =
        rewards.where((r) => r.canRedeemWithBalance(userBalance)).length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rewards', style: AppText.displaySmall),
              const SizedBox(height: 2),
              Text(
                '${rewards.length} reward · $unlockedCount siap redeem',
                style: AppText.body,
              ),
            ],
          ),
        ),
        if (unlockedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Ready!',
                    style: AppText.caption
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
      ],
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
                  return Padding(
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
                    Icon(
                      showArchive
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${archived.length} reward diarsipkan',
                      style: AppText.caption,
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
                    return Padding(
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.sm),
            child: Text(
              'Template reward siap pakai — pilih dan langsung tambah ke Wishlist!',
              style: AppText.body,
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
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final t = templates[i];
                  return TemplateCard(
                    template: t,
                    isAdded: addedNames.contains(t.name),
                    onAdd: () {
                      context.read<RewardProvider>().addFromTemplate(t);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${t.name} ditambahkan ke Wishlist!',
                            style: AppText.body,
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
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
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
            const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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
                  isSelected ? FontWeight.w600 : FontWeight.normal,
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
            const Text('🎁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Wishlist masih kosong.',
                style: AppText.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tambahkan reward impianmu atau pilih dari Shop!',
              style: AppText.body,
              textAlign: TextAlign.center,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🛍️', style: TextStyle(fontSize: 48)),
            SizedBox(height: AppSpacing.sm),
            Text('Tidak ada template di kategori ini.',
                style: AppText.title, textAlign: TextAlign.center),
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.redeem, color: Colors.white, size: 32),
          ),

          const SizedBox(height: AppSpacing.md),

          const Text('Redeem Reward?', style: AppText.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            rewardName,
            style: AppText.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
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
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Center(
                  child: Text('Redeem Sekarang', style: AppText.title)),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Center(
                child: Text('Batal',
                    style: AppText.body
                        .copyWith(color: AppColors.textSecondary)),
              ),
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
        Text(label, style: AppText.body),
        Text(
          value,
          style: AppText.body
              .copyWith(color: valueColor, fontWeight: FontWeight.w600),
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
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration,
                  color: Colors.white, size: 64),
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Selamat! 🎉',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Kamu berhasil redeem',
                style: TextStyle(
                    fontSize: 16, color: Colors.white70, height: 1.5),
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
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  rewardName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
              style: TextStyle(fontSize: 14, color: Colors.white60),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Center(
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
    );
  }
}
