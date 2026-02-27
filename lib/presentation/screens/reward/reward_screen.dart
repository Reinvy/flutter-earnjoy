import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/extensions.dart';
import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/core/widgets/gradient_button.dart';
import 'package:earnjoy/presentation/providers/reward_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'package:earnjoy/domain/usecases/reward_service.dart';
import 'package:earnjoy/data/datasources/storage_service.dart';
import 'widgets/add_reward_bottom_sheet.dart';
import 'widgets/reward_card.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> with TickerProviderStateMixin {
  bool _showCelebration = false;
  String _redeemedRewardName = '';
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _celebrationController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

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
      builder: (_) =>
          _RedeemConfirmSheet(rewardName: name, rewardCost: pointCost, userBalance: userBalance),
    );
    if (!mounted) return;
    if (confirmed == true) {
      _executeRedeem(context, rewardId, name);
    }
  }

  Future<void> _executeRedeem(BuildContext context, int rewardId, String name) async {
    final rewardProvider = context.read<RewardProvider>();
    final userProvider = context.read<UserProvider>();
    final storage = context.read<StorageService>();

    // Validate monthly budget before redeeming
    final rewardService = RewardService(storage);
    if (rewardService.isMonthlyBudgetExceeded(userProvider.user)) {
      _showErrorSnackbar(context, 'Monthly budget terlampaui.');
      return;
    }

    final success = rewardProvider.redeem(rewardId);
    if (!success) {
      _showErrorSnackbar(context, 'Balance tidak cukup atau reward belum unlocked.');
      return;
    }

    // Sync user balance from storage after redeem
    userProvider.loadUser();

    // Celebration feedback
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardProvider>().rewards;
    final userBalance = context.select<UserProvider, double>((p) => p.user.pointBalance);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        _Header(
                          totalRewards: rewards.length,
                          unlockedCount: rewards
                              .where((r) => r.canRedeemWithBalance(userBalance))
                              .length,
                        ),

                        const SizedBox(height: AppSpacing.sectionGap),

                        if (rewards.isEmpty)
                          const _EmptyState()
                        else ...[
                          const Text('Your Rewards', style: AppText.title),
                          const SizedBox(height: AppSpacing.sm),
                          ...rewards.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: RewardCard(
                                reward: r,
                                userBalance: userBalance,
                                onRedeem: r.canRedeemWithBalance(userBalance)
                                    ? () => _confirmRedeem(
                                        context,
                                        r.id,
                                        r.name,
                                        r.pointCost,
                                        userBalance,
                                      )
                                    : null,
                                onDelete: () => context.read<RewardProvider>().deleteReward(r.id),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.sm,
                    AppSpacing.screenH,
                    AppSpacing.md,
                  ),
                  child: GradientButton(
                    label: 'Add Reward',
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

class _Header extends StatelessWidget {
  final int totalRewards;
  final int unlockedCount;

  const _Header({required this.totalRewards, required this.unlockedCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rewards', style: AppText.displaySmall),
              const SizedBox(height: 2),
              Text('$totalRewards total · $unlockedCount unlocked', style: AppText.body),
            ],
          ),
        ),
        if (unlockedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Ready to redeem!', style: AppText.caption.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.redeem_outlined, color: AppColors.textDisabled, size: 48),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Belum ada reward.\nTambahkan wishlist pertama kamu!',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Redeem Confirmation Sheet ─────────────────────────────────────────────────

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

          // Icon
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

          // Info card
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

          // Confirm CTA
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
              child: const Center(child: Text('Redeem Sekarang', style: AppText.title)),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Cancel
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Center(
                child: Text('Batal', style: AppText.body.copyWith(color: AppColors.textSecondary)),
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

  const _InfoRow({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body),
        Text(
          value,
          style: AppText.body.copyWith(color: valueColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  final String rewardName;
  final VoidCallback onDismiss;

  const _CelebrationOverlay({required this.rewardName, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Icon with pulsing glow background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration, color: Colors.white, size: 64),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Kamu berhasil redeem',
                style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
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
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
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
