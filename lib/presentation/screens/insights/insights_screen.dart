import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/streak_record.dart';
import 'package:earnjoy/domain/usecases/burnout_service.dart';
import 'package:earnjoy/presentation/providers/insights_provider.dart';
import 'package:earnjoy/presentation/providers/wellbeing_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (icon: FontAwesomeIcons.chartSimple, label: 'Ringkasan'),
    (icon: FontAwesomeIcons.bolt, label: 'Produktivitas'),
    (icon: FontAwesomeIcons.handHoldingHeart, label: 'Keseimbangan'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _SummaryTab(),
                  _ProductivityTab(),
                  _BalanceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (r) => AppGradients.primary.createShader(r),
            child: const FaIcon(FontAwesomeIcons.chartLine, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Insights',
            style: AppText.displaySmall.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _RefreshButton(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppText.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
        padding: EdgeInsets.zero,
        tabs: _tabs.map((t) => Tab(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(t.icon, size: 11),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  t.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<InsightsProvider>().refresh();
        context.read<WellbeingProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data analitik berhasil diperbarui ⚡'),
            backgroundColor: AppColors.surfaceHigh,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Shared Panels & Elements ────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const _PanelCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
        gradient: LinearGradient(
          colors: [AppColors.surfaceHigh.withValues(alpha: 0.3), AppColors.surface.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
        gradient: LinearGradient(
          colors: [AppColors.surfaceHigh.withValues(alpha: 0.5), AppColors.surface.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 11, color: color ?? AppColors.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  style: AppText.title.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.caption.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (r) => AppGradients.primary.createShader(r),
            child: const FaIcon(FontAwesomeIcons.chartBar, size: 38, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppText.body.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SmartTipsCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _SmartTipsCard({
    required this.title,
    required this.content,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, size: 14, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.title.copyWith(fontSize: 13, color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppText.body.copyWith(fontSize: 12, height: 1.45, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      duration: const Duration(milliseconds: 500),
    );

    final startDelay = (widget.index * 90).clamp(0, 450);

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

// ─── Tab 1: Ringkasan ────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final heatmapData = provider.heatmapData;
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final firstDay = today.subtract(const Duration(days: 364));

    final maxVal = heatmapData.values.isEmpty ? 1.0 : heatmapData.values.reduce((a, b) => a > b ? a : b);

    final activeDays = heatmapData.entries.where((e) => e.value > 0).length;
    final avgPts = activeDays == 0
        ? 0.0
        : heatmapData.values.fold(0.0, (s, v) => s + v) / activeDays;

    final history = provider.streakHistory;
    final pr = provider.personalRecord;
    final current = provider.currentStreak;

    // Dynamic smart tips logic
    String smartTipTitle = 'Konsistensi adalah Kunci';
    String smartTipContent = 'Mulai log aktivitas pertamamu hari ini untuk menyalakan api streak!';
    IconData smartTipIcon = FontAwesomeIcons.lightbulb;
    Color smartTipColor = AppColors.primary;

    if (current != null && current.days >= 7) {
      smartTipTitle = '🔥 Luar Biasa!';
      smartTipContent = 'Kamu berhasil mempertahankan streak selama ${current.days} hari. Pertahankan ritme kerja yang sehat dan jangan lupa istirahat!';
      smartTipIcon = FontAwesomeIcons.fire;
      smartTipColor = AppColors.warning;
    } else if (current != null) {
      smartTipTitle = '⚡ Sedang Berjalan';
      smartTipContent = 'Streak aktif kamu saat ini ${current.days} hari. Yuk, lakukan minimal 1 aktivitas hari ini agar momentum kebiasaanmu tidak terputus!';
      smartTipIcon = FontAwesomeIcons.bolt;
      smartTipColor = AppColors.primaryLight;
    } else if (history.isNotEmpty) {
      smartTipTitle = '🌱 Yuk, Mulai Lagi!';
      smartTipContent = 'Streak kamu terputus, tapi tidak apa-apa! Setiap hari adalah kesempatan baru. Catat satu pencapaian hari ini untuk memulai kembali.';
      smartTipIcon = FontAwesomeIcons.seedling;
      smartTipColor = AppColors.success;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),

        // 1. Stats Chips Row
        _SlideUpFadeIn(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Hari Aktif',
                    value: '$activeDays',
                    icon: FontAwesomeIcons.calendarCheck,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Streak',
                    value: '${current?.days ?? 0} hari',
                    color: AppColors.warning,
                    icon: FontAwesomeIcons.fire,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Rata-rata Poin',
                    value: '${avgPts.toStringAsFixed(0)} pts',
                    icon: FontAwesomeIcons.award,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Heatmap Card
        _SlideUpFadeIn(
          index: 1,
          child: _PanelCard(
            title: '📅 Heatmap Aktivitas',
            subtitle: '365 hari terakhir (geser kesamping)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 126,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMonthLabels(firstDay),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(53, (weekIdx) {
                              return Column(
                                children: List.generate(7, (dayIdx) {
                                  final dayOffset = weekIdx * 7 + dayIdx;
                                  final dayDate = firstDay.add(Duration(days: dayOffset));
                                  if (dayDate.isAfter(today)) {
                                    return _HeatCell(intensity: -1);
                                  }
                                  final pts = heatmapData[dayDate] ?? 0.0;
                                  final intensity = maxVal == 0 ? 0.0 : (pts / maxVal).clamp(0.0, 1.0);
                                  return Tooltip(
                                    triggerMode: TooltipTriggerMode.tap,
                                    message: '${dayDate.day}/${dayDate.month}: ${pts.toStringAsFixed(0)} pts',
                                    child: _HeatCell(intensity: intensity),
                                  );
                                }),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ),
          ),
        ),

        // 3. Streak Banner & History Card
        _SlideUpFadeIn(
          index: 2,
          child: _PanelCard(
            title: '🔥 Riwayat Streak',
            subtitle: '${history.length} periode streak terekam',
            child: Column(
              children: [
                if (pr != null) ...[
                  _buildPRBanner(pr),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (history.isEmpty)
                  const _EmptyState(message: 'Belum ada riwayat streak. Yuk mulai hari ini!')
                else
                  ...history.take(5).map((r) => _StreakRow(record: r)),
              ],
            ),
          ),
        ),

        // 4. Smart Tip Panel
        _SlideUpFadeIn(
          index: 3,
          child: _SmartTipsCard(
            title: smartTipTitle,
            content: smartTipContent,
            icon: smartTipIcon,
            color: smartTipColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthLabels(DateTime firstDay) {
    final labels = <Widget>[];
    String? lastMonth;
    for (int w = 0; w < 53; w++) {
      final d = firstDay.add(Duration(days: w * 7));
      final monthStr = _monthAbbr(d.month);
      if (monthStr != lastMonth) {
        lastMonth = monthStr;
        labels.add(SizedBox(
          width: 12.4,
          child: Text(
            monthStr,
            style: AppText.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ));
      } else {
        labels.add(const SizedBox(width: 12.4));
      }
    }
    return Row(children: labels);
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text('Sedikit', style: AppText.caption.copyWith(fontSize: 10)),
        const SizedBox(width: 6),
        ...List.generate(5, (i) => _HeatCell(intensity: i / 4.0)),
        const SizedBox(width: 6),
        Text('Banyak', style: AppText.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  String _monthAbbr(int month) {
    const abbrs = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return abbrs[month];
  }

  Widget _buildPRBanner(StreakRecord pr) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.trophy, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Record: ${pr.days} Hari!',
                  style: AppText.title.copyWith(color: AppColors.success, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtDate(pr.startDate)} – ${_fmtDate(pr.endDate)}',
                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _HeatCell extends StatelessWidget {
  final double intensity; // -1 = future/empty, 0..1 = activity level

  const _HeatCell({required this.intensity});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (intensity < 0) {
      color = Colors.transparent;
    } else if (intensity == 0) {
      color = AppColors.textDisabled.withValues(alpha: 0.15);
    } else {
      color = Color.lerp(
        AppColors.primary.withValues(alpha: 0.25),
        AppColors.primaryLight,
        intensity,
      )!;
    }
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
        border: intensity == 0 ? null : Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  final StreakRecord record;

  const _StreakRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: record.isComeback
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: record.isComeback
                    ? AppColors.warning.withValues(alpha: 0.25)
                    : AppColors.glassBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '🔥',
              style: TextStyle(fontSize: record.days >= 7 ? 18 : 14),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${record.days} hari',
                      style: AppText.title.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    if (record.isComeback) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          'Comeback!',
                          style: AppText.caption.copyWith(
                            color: AppColors.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(record.startDate)} – ${_fmt(record.endDate)}',
                  style: AppText.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            height: 6,
            width: 70,
            decoration: BoxDecoration(
              color: AppColors.textDisabled.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (record.days / 30.0).clamp(0.08, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.progressFill,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ─── Tab 2: Produktivitas ──────────────────────────────────────────────────

class _ProductivityTab extends StatelessWidget {
  const _ProductivityTab();

  static final _catColors = [
    AppColors.primary,
    const Color(0xFF7CD1F9),
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    const Color(0xFFD6A8FF),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();

    // Trend Data
    final trendData = provider.trendData;
    final spots = <FlSpot>[];
    for (final d in trendData) {
      spots.add(FlSpot((d['index'] as int).toDouble(), (d['points'] as double)));
    }
    final maxY = spots.isEmpty ? 500.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final effectiveMaxY = maxY < 100 ? 500.0 : maxY * 1.25;
    final totalPts = spots.fold(0.0, (s, f) => s + f.y);

    // Category Distribution Data
    final dist = provider.categoryDistribution;
    final totalMinutes = dist.values.fold(0.0, (s, v) => s + v);
    final sections = <PieChartSectionData>[];
    final entries = dist.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      sections.add(PieChartSectionData(
        value: entries[i].value,
        color: _catColors[i % _catColors.length],
        radius: 16,
        showTitle: false,
      ));
    }

    String dominantCategory = '-';
    if (dist.isNotEmpty) {
      dominantCategory = dist.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      dominantCategory = _formatCategoryName(dominantCategory);
    }

    // Hourly Productivity / Peak Hours
    final productivity = provider.hourlyProductivity;
    final goldenHour = provider.goldenHour;
    final maxHourlyVal = productivity.values.isEmpty
        ? 1.0
        : productivity.values.reduce((a, b) => a > b ? a : b);

    final barGroups = <BarChartGroupData>[];
    for (int h = 0; h < 24; h++) {
      final val = productivity[h] ?? 0.0;
      final isGolden = h == goldenHour;
      barGroups.add(BarChartGroupData(
        x: h,
        barRods: [
          BarChartRodData(
            toY: val,
            gradient: isGolden
                ? const LinearGradient(
                    colors: [AppColors.warning, AppColors.error],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.6),
                      AppColors.primaryLight.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
            width: 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      ));
    }

    // Dynamic smart tips logic
    String smartTipTitle = 'Optimalkan Waktumu';
    String smartTipContent = 'Catat aktivitas lebih sering untuk mendapatkan analisis jam kerja paling produktif secara akurat.';
    IconData smartTipIcon = FontAwesomeIcons.clock;
    Color smartTipColor = AppColors.primary;

    if (goldenHour != null) {
      smartTipTitle = '⏰ Fokus di Jam Emas';
      smartTipContent = 'Jam produktif tertinggimu adalah pukul ${goldenHour.toString().padLeft(2, '0')}:00. Coba kerjakan tugas paling menantang atau kebiasaan terpentingmu di jam ini!';
      smartTipIcon = FontAwesomeIcons.lightbulb;
      smartTipColor = AppColors.warning;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),

        // 1. Stats Chips Row
        _SlideUpFadeIn(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Total Poin',
                    value: '${totalPts.toStringAsFixed(0)} pts',
                    icon: FontAwesomeIcons.star,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Jam Emas',
                    value: goldenHour != null ? '${goldenHour.toString().padLeft(2, '0')}:00' : '-',
                    color: AppColors.warning,
                    icon: FontAwesomeIcons.clock,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Dominan',
                    value: dominantCategory,
                    icon: FontAwesomeIcons.chartPie,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Point Trend Chart Card
        _SlideUpFadeIn(
          index: 1,
          child: _PanelCard(
            title: '📈 Tren Perolehan Poin',
            subtitle: 'Grafik fluktuasi poin harian',
            trailing: _PeriodToggle(),
            child: spots.isEmpty
                ? const _EmptyState(message: 'Belum ada data poin untuk tren ini.')
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.surfaceHigh,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(0)} pts',
                                  AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: effectiveMaxY / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppColors.glassBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: effectiveMaxY / 4,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  v == 0 ? '0' : v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0),
                                  style: AppText.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: math.max(1.0, (spots.length / 5).ceilToDouble()),
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= trendData.length) return const SizedBox();
                                final day = trendData[idx]['day'] as DateTime;
                                return Text(
                                  '${day.day}/${day.month}',
                                  style: AppText.caption.copyWith(fontSize: 9),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            gradient: AppGradients.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 3,
                                color: AppColors.primaryLight,
                                strokeWidth: 1,
                                strokeColor: AppColors.surfaceHigh,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.25),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        minY: 0,
                        maxY: effectiveMaxY,
                      ),
                    ),
                  ),
          ),
        ),

        // 3. Category Distribution Card
        _SlideUpFadeIn(
          index: 2,
          child: _PanelCard(
            title: '🥧 Distribusi Kategori',
            subtitle: 'Porsi waktu yang Anda habiskan',
            trailing: _PeriodToggle(),
            child: dist.isEmpty
                ? const _EmptyState(message: 'Belum ada data kategori untuk dianalisis.')
                : Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 52,
                                sectionsSpace: 3,
                                startDegreeOffset: -90,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.totalHoursLogged.toStringAsFixed(1),
                                style: AppText.displaySmall.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text('jam total', style: AppText.caption.copyWith(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: entries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final e = entry.value;
                          final pct = totalMinutes == 0 ? 0.0 : (e.value / totalMinutes * 100);
                          final hours = e.value / 60.0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _catColors[idx % _catColors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatCategoryName(e.key)} ${pct.toStringAsFixed(0)}% (${hours.toStringAsFixed(1)}j)',
                                style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ),

        // 4. Peak Hours Card
        _SlideUpFadeIn(
          index: 3,
          child: _PanelCard(
            title: '⏰ Peak Hours',
            subtitle: 'Rata-rata produktivitas per jam',
            child: Column(
              children: [
                if (goldenHour != null) ...[
                  _buildGoldenHourBanner(goldenHour),
                  const SizedBox(height: AppSpacing.md),
                ],
                productivity.isEmpty
                    ? const _EmptyState(message: 'Belum ada data produktivitas jam.')
                    : SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            barGroups: barGroups,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxHourlyVal / 4,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.glassBorder,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 20,
                                  interval: 4,
                                  getTitlesWidget: (v, _) {
                                    final hourVal = v.toInt();
                                    if (hourVal % 4 != 0) return const SizedBox();
                                    return Text(
                                      hourVal.toString().padLeft(2, '0'),
                                      style: AppText.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),
                              ),
                            ),
                            maxY: maxHourlyVal < 1 ? 100 : maxHourlyVal * 1.2,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.surfaceHigh,
                                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                                  'Pukul ${group.x}:00\n${rod.toY.toStringAsFixed(0)} pts',
                                  AppText.caption.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),

        // 5. Smart Tip Card
        _SlideUpFadeIn(
          index: 4,
          child: _SmartTipsCard(
            title: smartTipTitle,
            content: smartTipContent,
            icon: smartTipIcon,
            color: smartTipColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGoldenHourBanner(int goldenHour) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withValues(alpha: 0.15), AppColors.warning.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.solidClock, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jam Emas Anda',
                  style: AppText.title.copyWith(color: AppColors.warning, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Anda paling produktif pada pukul ${goldenHour.toString().padLeft(2, '0')}:00 – ${(goldenHour + 1).toString().padLeft(2, '0')}:00.',
                  style: AppText.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String cat) {
    switch (cat) {
      case 'food': return 'Kuliner';
      case 'entertainment': return 'Hiburan';
      case 'shopping': return 'Belanja';
      case 'experience': return 'Pengalaman';
      case 'self_growth': return 'Pengembangan Diri';
      case 'rest': return 'Istirahat';
      default: return cat;
    }
  }
}

class _PeriodToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (period, label) in [
          (InsightsPeriod.week, '7H'),
          (InsightsPeriod.month, '30H'),
          (InsightsPeriod.allTime, '90H'),
        ])
          GestureDetector(
            onTap: () => provider.setPeriod(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: provider.period == period
                    ? AppColors.primary
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: provider.period == period
                      ? AppColors.primaryLight.withValues(alpha: 0.3)
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  color: provider.period == period
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Tab 3: Keseimbangan ───────────────────────────────────────────────────

class _BalanceTab extends StatefulWidget {
  const _BalanceTab();

  @override
  State<_BalanceTab> createState() => _BalanceTabState();
}

class _BalanceTabState extends State<_BalanceTab> {
  double? _localTarget;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final target = _localTarget ?? provider.dailyPointTarget;
    final gva = provider.goalVsActual;
    final rate = provider.goalAchievementRate;

    final achieved = gva.values.where((v) => (v['actual'] ?? 0) >= (v['target'] ?? 1)).length;

    // Last 14 days
    final recentEntries = gva.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last14 = recentEntries.length > 14
        ? recentEntries.sublist(recentEntries.length - 14)
        : recentEntries;

    final maxY = [
      target * 1.2,
      ...last14.map((e) => e.value['actual'] ?? 0.0),
    ].reduce((a, b) => a > b ? a : b);

    final barGroups = last14.asMap().entries.map((entry) {
      final i = entry.key;
      final actual = entry.value.value['actual'] ?? 0.0;
      final hit = actual >= target;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: actual,
            color: hit ? AppColors.success : AppColors.primary.withValues(alpha: 0.6),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    // Wellbeing Provider
    final wellbeing = context.watch<WellbeingProvider>();
    final score = wellbeing.burnoutScore;
    final status = wellbeing.status;
    final insight = wellbeing.balanceInsight;
    final canDeclare = wellbeing.canDeclareRestDay;
    final restDayCount = wellbeing.restDayCount;

    // Dynamic smart tips logic
    String smartTipTitle = 'Keseimbangan Hidup';
    String smartTipContent = 'Jaga skor burnout tetap rendah dengan menyeimbangkan aktivitas fisik, pengembangan diri, dan istirahat.';
    IconData smartTipIcon = FontAwesomeIcons.heart;
    Color smartTipColor = AppColors.success;

    if (status == BurnoutStatus.burnout) {
      smartTipTitle = '🔴 Peringatan Burnout!';
      smartTipContent = 'Skor burnout Anda berada di level kritis. Hentikan aktivitas berat dan segera gunakan Hari Istirahat (Rest Day) untuk mengembalikan energi Anda.';
      smartTipIcon = FontAwesomeIcons.triangleExclamation;
      smartTipColor = AppColors.error;
    } else if (status == BurnoutStatus.fatigue || status == BurnoutStatus.attention) {
      smartTipTitle = '⚠️ Tubuh Butuh Istirahat';
      smartTipContent = 'Anda menunjukkan tanda-tanda kelelahan. Gunakan fitur Rest Day jika Anda merasa penat hari ini agar streak Anda tetap aman.';
      smartTipIcon = FontAwesomeIcons.circleExclamation;
      smartTipColor = AppColors.warning;
    } else if (score < 20 && achieved > 5) {
      smartTipTitle = '💚 Keseimbangan Sempurna';
      smartTipContent = 'Luar biasa! Produktivitas tinggi namun tingkat burnout tetap sangat rendah. Anda memiliki pola hidup yang sangat sehat.';
      smartTipIcon = FontAwesomeIcons.solidCircleCheck;
      smartTipColor = AppColors.success;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),

        // 1. Stats Chips Row
        _SlideUpFadeIn(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Target/Hari',
                    value: '${target.toStringAsFixed(0)} pts',
                    icon: FontAwesomeIcons.crosshairs,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Konsistensi',
                    value: '${(rate * 100).toStringAsFixed(0)}%',
                    color: rate >= 0.7
                        ? AppColors.success
                        : rate >= 0.4
                            ? AppColors.warning
                            : AppColors.error,
                    icon: FontAwesomeIcons.circleCheck,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: 'Burnout',
                    value: score.toStringAsFixed(0),
                    color: _statusColor(status),
                    icon: FontAwesomeIcons.heartPulse,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Set Daily Target Slider Card
        _SlideUpFadeIn(
          index: 1,
          child: _PanelCard(
            title: '🎯 Set Target Poin Harian',
            subtitle: 'Geser slider untuk mengubah sasaran harian Anda',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${target.toStringAsFixed(0)} pts',
                      style: AppText.displaySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        target < 300
                            ? '😌 Santai'
                            : target < 700
                                ? '💪 Moderat'
                                : '🔥 Intensif',
                        style: AppText.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.textDisabled.withValues(alpha: 0.3),
                    thumbColor: AppColors.primaryLight,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: target,
                    min: 50,
                    max: 3000,
                    divisions: 59,
                    onChanged: (v) => setState(() => _localTarget = v),
                    onChangeEnd: (v) {
                      provider.setDailyTarget(v);
                      setState(() => _localTarget = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('50', style: TextStyle(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
                      Text('3000 pts', style: TextStyle(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Goal vs Actual Chart Card
        _SlideUpFadeIn(
          index: 2,
          child: _PanelCard(
            title: '📊 Goal vs Aktual (14 Hari)',
            subtitle: 'Warna hijau menunjukkan pencapaian target harian',
            child: last14.isEmpty
                ? const _EmptyState(message: 'Belum ada data untuk pencapaian target.')
                : SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: target,
                              color: AppColors.warning,
                              strokeWidth: 1.5,
                              dashArray: [5, 3],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: AppText.caption.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (_) => 'Target',
                              ),
                            ),
                          ],
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppColors.glassBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx >= last14.length || idx < 0) return const SizedBox();
                                final day = last14[idx].key;
                                return Text(
                                  '${day.day}/${day.month}',
                                  style: AppText.caption.copyWith(fontSize: 9),
                                );
                              },
                            ),
                          ),
                        ),
                        maxY: maxY < 1 ? 500 : maxY,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.surfaceHigh,
                            getTooltipItem: (group, _, rod, __) {
                              if (group.x >= last14.length || group.x < 0) return null;
                              return BarTooltipItem(
                                '${rod.toY.toStringAsFixed(0)} pts',
                                AppText.caption.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        // 4. Burnout Gauge Card
        _SlideUpFadeIn(
          index: 3,
          child: _PanelCard(
            title: '🫀 Burnout Score',
            subtitle: 'Tingkat kelelahan berdasar aktivitas 7 hari terakhir',
            child: Column(
              children: [
                _BurnoutGauge(score: score, status: status),
                const SizedBox(height: AppSpacing.md),
                _BurnoutStatusRow(status: status),
              ],
            ),
          ),
        ),

        // 5. Balance Insight Card
        _SlideUpFadeIn(
          index: 4,
          child: _PanelCard(
            title: '📊 Keseimbangan Aktivitas',
            subtitle: 'Analisis keseimbangan aktivitas mingguan',
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: _statusColor(status).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FaIcon(
                      status == BurnoutStatus.healthy
                          ? FontAwesomeIcons.circleCheck
                          : FontAwesomeIcons.circleExclamation,
                      size: 16,
                      color: _statusColor(status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.isNotEmpty ? insight : 'Belum ada data aktivitas yang cukup untuk analisis.',
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 6. Rest Day Panel Card
        _SlideUpFadeIn(
          index: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.glassBorder),
                gradient: LinearGradient(
                  colors: [AppColors.surfaceHigh.withValues(alpha: 0.4), AppColors.surface.withValues(alpha: 0.7)],
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
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('☀️', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hari Istirahat (Rest Day)', style: AppText.title.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'Streak tetap aman • +10 poin self-care • Maks 1x per 7 hari',
                              style: AppText.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: canDeclare
                            ? [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: canDeclare
                            ? () async {
                                await wellbeing.declareRestDay();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        '☀️ Hari Istirahat diaktifkan! +10 pts. Streakmu aman. 💚',
                                      ),
                                      backgroundColor: AppColors.success.withValues(alpha: 0.85),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: FaIcon(
                          canDeclare ? FontAwesomeIcons.personArrowUpFromLine : FontAwesomeIcons.clockRotateLeft,
                          size: 16,
                        ),
                        label: Text(
                          canDeclare
                              ? 'Deklarasikan Hari Istirahat (+10 pts)'
                              : 'Sudah digunakan minggu ini (Total: $restDayCount kali)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canDeclare ? AppColors.success : AppColors.surfaceHigh,
                          foregroundColor: canDeclare ? Colors.white : AppColors.textDisabled,
                          disabledBackgroundColor: AppColors.surfaceHigh,
                          disabledForegroundColor: AppColors.textDisabled,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 7. Smart Tip Card
        _SlideUpFadeIn(
          index: 6,
          child: _SmartTipsCard(
            title: smartTipTitle,
            content: smartTipContent,
            icon: smartTipIcon,
            color: smartTipColor,
          ),
        ),
      ],
    );
  }

  Color _statusColor(BurnoutStatus status) => switch (status) {
        BurnoutStatus.healthy   => AppColors.success,
        BurnoutStatus.attention => AppColors.warning,
        BurnoutStatus.fatigue   => AppColors.warning,
        BurnoutStatus.burnout   => AppColors.error,
      };
}

// ─── Wellbeing Subwidgets & Painters ────────────────────────────────────────

class _BurnoutGauge extends StatelessWidget {
  final double score;
  final BurnoutStatus status;
  const _BurnoutGauge({required this.score, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(status);
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _GaugePainter(score: score, color: color),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: AppText.displaySmall.copyWith(
                    color: color,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('/100', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForStatus(BurnoutStatus s) => switch (s) {
        BurnoutStatus.healthy   => AppColors.success,
        BurnoutStatus.attention => AppColors.warning,
        BurnoutStatus.fatigue   => AppColors.warning,
        BurnoutStatus.burnout   => AppColors.error,
      };
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.72;
    final radius = size.width * 0.38;
    const startAngle = 3.14159; // π (left)
    const sweepAll = 3.14159;   // π (half circle)

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.textDisabled.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAll,
      false,
      trackPaint,
    );

    // Filled arc
    final filledPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final filledSweep = sweepAll * (score / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      filledSweep,
      false,
      filledPaint,
    );

    // Zone labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, double angle) {
      final x = cx + (radius + 18) * cos(angle);
      final y = cy + (radius + 18) * sin(angle);
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    drawLabel('0', 3.14159);
    drawLabel('50', 3.14159 / 2 * 3);
    drawLabel('100', 0);
  }

  double cos(double rad) => math.cos(rad);
  double sin(double rad) => math.sin(rad);

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.score != score || old.color != color;
}

class _BurnoutStatusRow extends StatelessWidget {
  final BurnoutStatus status;
  const _BurnoutStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final zones = [
      (label: '0–30\nSehat', color: AppColors.success),
      (label: '31–60\nPerhatian', color: AppColors.warning),
      (label: '61–80\nKelelahan', color: AppColors.warning),
      (label: '81–100\nBurnout', color: AppColors.error),
    ];
    final statusIdx = status.index;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: zones.asMap().entries.map((e) {
        final isActive = e.key == statusIdx;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? e.value.color.withValues(alpha: 0.16)
                  : AppColors.surfaceHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isActive
                    ? e.value.color.withValues(alpha: 0.5)
                    : AppColors.glassBorder,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Text(
              e.value.label,
              style: AppText.caption.copyWith(
                color: isActive ? e.value.color : AppColors.textDisabled,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }
}
