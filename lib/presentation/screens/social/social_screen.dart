import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/group_challenge.dart';
import 'package:earnjoy/presentation/providers/social_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';
import 'widgets/partner_card.dart';
import 'widgets/add_partner_sheet.dart';
import 'widgets/group_challenge_sheet.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // ── Header ─────────────────────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Social',
                        style: AppText.displaySmall.copyWith(
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [AppColors.gradientStart, AppColors.gradientEnd],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                        ),
                      ),
                      Text('Accountability bersama teman', style: AppText.body),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // ── Privacy toggle / Profile Card ─────────────────────────────
              _ProfileCard(social: social, user: user),
              const SizedBox(height: AppSpacing.sectionGap),

              if (user.socialEnabled) ...[
                // ── Partners ─────────────────────────────────────────────────
                _PartnersSection(social: social),
                const SizedBox(height: AppSpacing.sectionGap),

                // ── Weekly Duel ───────────────────────────────────────────────
                _DuelSection(social: social, userName: user.name),
                const SizedBox(height: AppSpacing.sectionGap),

                // ── Group Challenge ────────────────────────────────────────────
                _GroupChallengeSection(social: social),
              ] else ...[
                _SocialDisabledBanner(),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final SocialProvider social;
  final dynamic user;

  const _ProfileCard({required this.social, required this.user});

  @override
  Widget build(BuildContext context) {
    final isEnabled = user.socialEnabled;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
        gradient: const LinearGradient(
          colors: [Color(0x0D8B7FF5), Color(0x055EC4F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mode Sosial', style: AppText.title),
                    Text(
                      isEnabled ? 'Aktif — teman bisa terhubung' : 'Nonaktif — hanya kamu yang bisa lihat data',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  if (val) {
                    social.enableSocial();
                  } else {
                    social.disableSocial();
                  }
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (isEnabled && user.inviteCode.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: AppSpacing.sm),
            const Text('Invite Code kamu:', style: AppText.caption),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: user.inviteCode));
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite code disalin ke clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.primaryDim),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.inviteCode,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.copy_outlined, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text('Tap untuk copy. Share ke teman agar mereka bisa tambahkan kamu sebagai partner.', style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

// ─── Social Disabled Banner ───────────────────────────────────────────────────

class _SocialDisabledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline, color: AppColors.textDisabled, size: 48),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Aktifkan Mode Sosial',
            style: AppText.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Undang teman sebagai accountability partner, tantang duel mingguan, dan buat group challenge bersama.',
            style: AppText.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outlined, color: AppColors.primary, size: 16),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Privacy-first: hanya statistik agregat yang dibagikan, bukan detail aktivitas.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
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

// ─── Partners Section ─────────────────────────────────────────────────────────

class _PartnersSection extends StatelessWidget {
  final SocialProvider social;
  const _PartnersSection({required this.social});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Accountability Partners', style: AppText.title),
            GestureDetector(
              onTap: () => _showAddPartnerSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          social.partners.isEmpty
              ? 'Belum ada partner. Tambahkan teman untuk saling menyemangati!'
              : '${social.partners.length} partner aktif',
          style: AppText.body,
        ),
        if (social.partners.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...social.partners.map((partner) => PartnerCard(
                partner: partner,
                hasActiveDuel: social.activeDuel != null,
                onDuelTap: () {
                  HapticFeedback.mediumImpact();
                  social.createDuel(
                    partnerId: partner.id,
                    partnerName: partner.name,
                  );
                },
                onRemoveTap: () {
                  HapticFeedback.selectionClick();
                  social.removePartner(partner.id);
                },
              )),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          _EmptyState(
            icon: Icons.people_outline,
            message: 'Tap "+ Tambah" untuk undang teman pertamamu',
          ),
        ],
      ],
    );
  }

  void _showAddPartnerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: social,
        child: const AddPartnerSheet(),
      ),
    );
  }
}

// ─── Duel Section ─────────────────────────────────────────────────────────────

class _DuelSection extends StatelessWidget {
  final SocialProvider social;
  final String userName;
  const _DuelSection({required this.social, required this.userName});

  @override
  Widget build(BuildContext context) {
    final duel = social.activeDuel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Weekly Duel', style: AppText.title),
        const SizedBox(height: AppSpacing.xs),
        if (duel != null) ...[
          Text(
            'Duel aktif vs ${duel.partnerName}. Sync untuk update progresmu!',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          DuelProgressCard(
            duel: duel,
            myName: userName,
            onSync: () {
              HapticFeedback.selectionClick();
              social.syncDuelProgress();
            },
            onResolve: () {
              HapticFeedback.mediumImpact();
              social.resolveDuel();
            },
          ),
        ] else ...[
          const Text(
            'Tantang partner dalam duel poin 7 hari. Siapa yang paling produktif minggu ini?',
            style: AppText.body,
          ),
          if (social.partners.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _EmptyState(
              icon: Icons.sports_kabaddi_outlined,
              message: 'Tambah partner dulu untuk mulai duel',
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_kabaddi_outlined, color: AppColors.textSecondary, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Tap "Duel" di kartu partner untuk memulai duel mingguan',
                      style: AppText.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Group Challenge Section ──────────────────────────────────────────────────

class _GroupChallengeSection extends StatelessWidget {
  final SocialProvider social;
  const _GroupChallengeSection({required this.social});

  @override
  Widget build(BuildContext context) {
    final challenge = social.activeGroupChallenge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Group Challenge', style: AppText.title),
            if (challenge == null)
              GestureDetector(
                onTap: () => _showGroupChallengeSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Buat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (challenge != null) ...[
          Text('Challenge aktif: ${challenge.name}', style: AppText.body),
          const SizedBox(height: AppSpacing.sm),
          _GroupChallengeCard(challenge: challenge, social: social),
        ] else ...[
          const Text(
            'Ajak 2–6 orang untuk kumpulkan poin bersama. Semua anggota berkontribusi ke target yang sama.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpacing.md),
          _EmptyState(
            icon: Icons.groups_outlined,
            message: 'Tap "+ Buat" untuk mulai challenge tim',
          ),
        ],
      ],
    );
  }

  void _showGroupChallengeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: social,
        child: const GroupChallengeSheet(),
      ),
    );
  }
}

class _GroupChallengeCard extends StatelessWidget {
  final GroupChallenge challenge;
  final SocialProvider social;

  const _GroupChallengeCard({required this.challenge, required this.social});

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.isCompleted;
    final progress = challenge.progress;
    final members = social.getMembersFromChallenge(challenge);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCompleted ? AppColors.success.withAlpha(120) : AppColors.primary.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.name, style: AppText.title),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success.withAlpha(40) : AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isCompleted ? '✅ Selesai' : '${challenge.daysRemaining} hari lagi',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (challenge.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(challenge.description, style: AppText.caption),
          ],
          const SizedBox(height: AppSpacing.md),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.currentPoints.toStringAsFixed(0)} / ${challenge.targetPoints.toStringAsFixed(0)} pts',
                style: AppText.body.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppText.title.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: AppColors.textDisabled),
                const SizedBox(width: 4),
                Text(
                  members.take(3).join(', ') + (members.length > 3 ? ' +${members.length - 3}' : ''),
                  style: AppText.caption,
                ),
              ],
            ),
          ],
          if (!isCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () {
                social.syncGroupChallengeProgress();
                HapticFeedback.selectionClick();
              },
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Sync Progres'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withAlpha(120)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: AppText.body),
          ),
        ],
      ),
    );
  }
}
