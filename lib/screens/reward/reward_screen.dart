import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/reward_service.dart';
import '../../services/storage_service.dart';
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

  Future<void> _onRedeem(BuildContext context, int rewardId, String name) async {
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Scrollable content ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        // ── Header ─────────────────────────────────────────
                        _Header(
                          totalRewards: rewards.length,
                          unlockedCount: rewards.where((r) => r.isUnlocked).length,
                        ),

                        const SizedBox(height: AppSpacing.sectionGap),

                        // ── Reward list ────────────────────────────────────
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
                                onRedeem: r.isUnlocked
                                    ? () => _onRedeem(context, r.id, r.name)
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

                // ── Fixed CTA ─────────────────────────────────────────────
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

        // ── Celebration overlay ────────────────────────────────────────────
        if (_showCelebration)
          FadeTransition(
            opacity: _fadeAnim,
            child: _CelebrationOverlay(rewardName: _redeemedRewardName),
          ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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

class _CelebrationOverlay extends StatelessWidget {
  final String rewardName;
  const _CelebrationOverlay({required this.rewardName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, color: Colors.white, size: 80),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Selamat!',
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
                'Kamu berhasil redeem\n"$rewardName"',
                style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'Kamu layak mendapatkannya! 🎉',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
