import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
    (icon: Icons.grid_view_rounded, label: 'Heatmap'),
    (icon: Icons.trending_up_rounded, label: 'Trend'),
    (icon: Icons.donut_large_rounded, label: 'Kategori'),
    (icon: Icons.bar_chart_rounded, label: 'Peak Hours'),
    (icon: Icons.local_fire_department_rounded, label: 'Streak'),
    (icon: Icons.flag_rounded, label: 'Target'),
    (icon: Icons.favorite_rounded, label: 'Wellbeing'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
                  _HeatmapPanel(),
                  _TrendPanel(),
                  _CategoryPanel(),
                  _PeakHoursPanel(),
                  _StreakHistoryPanel(),
                  _GoalActualPanel(),
                  _WellbeingPanel(),
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
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Insights', style: AppText.displaySmall.copyWith(fontSize: 22)),
          const Spacer(),
          _RefreshButton(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppText.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: AppText.caption.copyWith(fontSize: 12),
        padding: EdgeInsets.zero,
        tabs: _tabs.map((t) => Tab(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, size: 14),
                const SizedBox(width: 4),
                Text(t.label),
              ],
            ),
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
      onTap: () => context.read<InsightsProvider>().refresh(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────────────────

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
                    Text(title, style: AppText.title),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppText.caption),
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

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppText.title.copyWith(
                color: color ?? AppColors.primary,
                fontSize: 18,
              )),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

// ─── 1. Heatmap Panel ────────────────────────────────────────────────────────

class _HeatmapPanel extends StatelessWidget {
  const _HeatmapPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final data = provider.heatmapData;
    final now = DateTime.now();

    // Build 52-week grid (most recent week on right)
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = today.subtract(const Duration(days: 364));

    // Find max value for color normalization
    final maxVal = data.values.isEmpty ? 1.0 : data.values.reduce((a, b) => a > b ? a : b);

    // Total active days and average
    final activeDays = data.entries.where((e) => e.value > 0).length;
    final avgPts = activeDays == 0
        ? 0.0
        : data.values.fold(0.0, (s, v) => s + v) / activeDays;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(label: 'Hari Aktif', value: '$activeDays'),
            _StatChip(label: 'Rata-rata/Hari', value: '${avgPts.toStringAsFixed(0)} pts'),
            _StatChip(
              label: 'Bulan Ini',
              value: '${data.entries.where((e) {
                return e.key.year == now.year && e.key.month == now.month && e.value > 0;
              }).length} hari',
            ),
          ],
        ),
        _PanelCard(
          title: '📅 Heatmap Aktivitas',
          subtitle: '365 hari terakhir',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthLabels(firstDay),
              const SizedBox(height: 4),
              SizedBox(
                height: 90,
                child: Row(
                  children: List.generate(53, (weekIdx) {
                    return Column(
                      children: List.generate(7, (dayIdx) {
                        final dayOffset = weekIdx * 7 + dayIdx;
                        final dayDate = firstDay.add(Duration(days: dayOffset));
                        if (dayDate.isAfter(today)) {
                          return _HeatCell(intensity: -1);
                        }
                        final pts = data[dayDate] ?? 0.0;
                        final intensity = maxVal == 0 ? 0.0 : (pts / maxVal).clamp(0.0, 1.0);
                        return Tooltip(
                          message:
                              '${dayDate.day}/${dayDate.month}: ${pts.toStringAsFixed(0)} pts',
                          child: _HeatCell(intensity: intensity),
                        );
                      }),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              _buildLegend(),
            ],
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
          width: 13,
          child: Text(monthStr, style: AppText.caption.copyWith(fontSize: 8)),
        ));
      } else {
        labels.add(const SizedBox(width: 13));
      }
    }
    return Row(children: labels);
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text('Sedikit', style: AppText.caption),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => _HeatCell(intensity: i / 4.0)),
        const SizedBox(width: 4),
        Text('Banyak', style: AppText.caption),
      ],
    );
  }

  String _monthAbbr(int month) {
    const abbrs = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return abbrs[month];
  }
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
      color = AppColors.textDisabled.withAlpha(80);
    } else {
      color = Color.lerp(
        AppColors.primaryDim.withAlpha(180),
        AppColors.primary,
        intensity,
      )!;
    }
    return Container(
      width: 11,
      height: 11,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─── 2. Trend Chart Panel ────────────────────────────────────────────────────

class _TrendPanel extends StatelessWidget {
  const _TrendPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final data = provider.trendData;

    final spots = <FlSpot>[];
    for (final d in data) {
      spots.add(FlSpot((d['index'] as int).toDouble(), (d['points'] as double)));
    }

    final maxY = spots.isEmpty ? 500.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final effectiveMaxY = maxY < 100 ? 500.0 : maxY * 1.2;

    final totalPts = spots.fold(0.0, (s, f) => s + f.y);
    final activeDays = spots.where((s) => s.y > 0).length;
    final avgPts = activeDays == 0 ? 0.0 : totalPts / activeDays;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(label: 'Total', value: '${totalPts.toStringAsFixed(0)} pts'),
            _StatChip(label: 'Rata-rata', value: '${avgPts.toStringAsFixed(0)} pts'),
            _StatChip(
              label: 'Terbaik',
              value: spots.isEmpty
                  ? '0 pts'
                  : '${spots.map((s) => s.y).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} pts',
              color: AppColors.success,
            ),
          ],
        ),
        _PanelCard(
          title: '📈 Tren Poin',
          subtitle: 'Riwayat poin per hari',
          trailing: _PeriodToggle(),
          child: spots.isEmpty
              ? const _EmptyState(message: 'Belum ada aktivitas. Mulai log sekarang!')
              : SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
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
                            getTitlesWidget: (v, _) => Text(
                              v == 0 ? '' : '${(v / 1000).toStringAsFixed(0)}k',
                              style: AppText.caption.copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (spots.length / 5).ceilToDouble(),
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= data.length) return const SizedBox();
                              final day = data[idx]['day'] as DateTime;
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
                          curveSmoothness: 0.3,
                          gradient: AppGradients.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withAlpha(80),
                                AppColors.primary.withAlpha(0),
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
      ],
    );
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
          (InsightsPeriod.week, '7D'),
          (InsightsPeriod.month, '30D'),
          (InsightsPeriod.allTime, '90D'),
        ])
          GestureDetector(
            onTap: () => provider.setPeriod(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: provider.period == period
                    ? AppColors.primary
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  color: provider.period == period
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── 3. Category Distribution Panel ──────────────────────────────────────────

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel();

  static const _catColors = [
    Color(0xFF8B7FF5),
    Color(0xFF5EC4F0),
    Color(0xFF4ECFA0),
    Color(0xFFFFB547),
    Color(0xFFFF6B6B),
    Color(0xFFB388FF),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final dist = provider.categoryDistribution;
    final totalMinutes = dist.values.fold(0.0, (s, v) => s + v);

    final sections = <PieChartSectionData>[];
    final entries = dist.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      sections.add(PieChartSectionData(
        value: entries[i].value,
        color: _catColors[i % _catColors.length],
        radius: 60,
        showTitle: false,
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(
              label: 'Total Jam',
              value: '${provider.totalHoursLogged.toStringAsFixed(1)} jam',
            ),
            _StatChip(label: 'Kategori', value: '${dist.length}'),
            if (dist.isNotEmpty)
              _StatChip(
                label: 'Dominan',
                value: dist.entries
                    .reduce((a, b) => a.value >= b.value ? a : b)
                    .key,
              ),
          ],
        ),
        _PanelCard(
          title: '🥧 Distribusi Kategori',
          subtitle: 'Waktu per kategori',
          trailing: _PeriodToggle(),
          child: dist.isEmpty
              ? const _EmptyState(message: 'Belum ada aktivitas untuk dianalisis.')
              : Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: entries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final pct = totalMinutes == 0
                            ? 0.0
                            : (e.value / totalMinutes * 100);
                        final hours = e.value / 60;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _catColors[i % _catColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.key} ${pct.toStringAsFixed(0)}% (${hours.toStringAsFixed(1)}j)',
                              style: AppText.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ─── 4. Peak Hours Panel ─────────────────────────────────────────────────────

class _PeakHoursPanel extends StatelessWidget {
  const _PeakHoursPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final productivity = provider.hourlyProductivity;
    final goldenHour = provider.goldenHour;

    final maxVal = productivity.values.isEmpty
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
                    colors: [Color(0xFFFFB547), Color(0xFFFF6B6B)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : LinearGradient(
                    colors: [
                      AppColors.gradientStart.withAlpha(180),
                      AppColors.gradientEnd.withAlpha(220),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (goldenHour != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x33FFB547), Color(0x11FF6B6B)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0x55FFB547)),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Golden Hour kamu',
                            style: AppText.title.copyWith(color: AppColors.warning)),
                        Text(
                          'Kamu paling produktif pukul ${goldenHour.toString().padLeft(2, '0')}:00 – '
                          '${(goldenHour + 1).toString().padLeft(2, '0')}:00',
                          style: AppText.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        _PanelCard(
          title: '⏰ Peak Hours',
          subtitle: 'Rata-rata poin per jam',
          child: productivity.isEmpty
              ? const _EmptyState(message: 'Belum ada data untuk analisis jam produktif.')
              : SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.glassBorder,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: 4,
                            getTitlesWidget: (v, _) {
                              final h = v.toInt();
                              if (h % 4 != 0) return const SizedBox();
                              return Text(
                                h.toString().padLeft(2, '0'),
                                style: AppText.caption.copyWith(fontSize: 9),
                              );
                            },
                          ),
                        ),
                      ),
                      maxY: maxVal < 1 ? 100 : maxVal * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceHigh,
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '${group.x}:00\n${rod.toY.toStringAsFixed(0)} pts',
                            AppText.caption.copyWith(color: AppColors.primary, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── 5. Streak History Panel ──────────────────────────────────────────────────

class _StreakHistoryPanel extends StatelessWidget {
  const _StreakHistoryPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final history = provider.streakHistory;
    final pr = provider.personalRecord;
    final current = provider.currentStreak;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(
              label: 'Streak Saat Ini',
              value: current != null ? '${current.days} hari' : '0 hari',
              color: AppColors.warning,
            ),
            _StatChip(
              label: 'Rekor Terbaik',
              value: pr != null ? '${pr.days} hari' : '0 hari',
              color: AppColors.success,
            ),
            _StatChip(
              label: 'Total Streak',
              value: '${history.length}x',
            ),
          ],
        ),
        if (pr != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x334ECFA0), Color(0x114ECFA0)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0x554ECFA0)),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personal Record: ${pr.days} hari',
                            style: AppText.title.copyWith(color: AppColors.success)),
                        Text(
                          '${_fmt(pr.startDate)} – ${_fmt(pr.endDate)}',
                          style: AppText.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        _PanelCard(
          title: '📊 Riwayat Streak',
          subtitle: '${history.length} periode streak',
          child: history.isEmpty
              ? const _EmptyState(message: 'Mulai streak pertamamu hari ini!')
              : Column(
                  children: history.take(10).map((r) => _StreakRow(record: r)).toList(),
                ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: record.isComeback
                  ? AppColors.warning.withAlpha(30)
                  : AppColors.primaryDim,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              '🔥',
              style: TextStyle(fontSize: record.days >= 7 ? 20 : 16),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${record.days} hari', style: AppText.title),
                    if (record.isComeback) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(40),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text('Comeback!',
                            style: AppText.caption.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                            )),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${_fmt(record.startDate)} – ${_fmt(record.endDate)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              color: AppColors.textDisabled,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (record.days / 30.0).clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  gradient: AppGradients.primary,
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

// ─── 6. Goal vs Actual Panel ──────────────────────────────────────────────────

class _GoalActualPanel extends StatefulWidget {
  const _GoalActualPanel();

  @override
  State<_GoalActualPanel> createState() => _GoalActualPanelState();
}

class _GoalActualPanelState extends State<_GoalActualPanel> {
  double? _localTarget;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InsightsProvider>();
    final target = _localTarget ?? provider.dailyPointTarget;
    final gva = provider.goalVsActual;

    final rate = provider.goalAchievementRate;
    final achieved = gva.values.where((v) => (v['actual'] ?? 0) >= (v['target'] ?? 1)).length;

    // Build bar chart groups (last 14 days for readability)
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
            color: hit ? AppColors.success : AppColors.primary.withAlpha(180),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(
              label: 'Tercapai',
              value: '$achieved hari',
              color: AppColors.success,
            ),
            _StatChip(
              label: 'Konsistensi',
              value: '${(rate * 100).toStringAsFixed(0)}%',
              color: rate >= 0.7
                  ? AppColors.success
                  : rate >= 0.4
                      ? AppColors.warning
                      : AppColors.error,
            ),
            _StatChip(label: 'Target/Hari', value: '${target.toStringAsFixed(0)} pts'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 Set Target Harian', style: AppText.title),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text('${target.toStringAsFixed(0)} pts',
                        style: AppText.title.copyWith(
                          color: AppColors.primary,
                          fontSize: 20,
                        )),
                    const Spacer(),
                    Text(
                      target < 200
                          ? '😌 Santai'
                          : target < 500
                              ? '💪 Moderat'
                              : '🔥 Intensif',
                      style: AppText.caption,
                    ),
                  ],
                ),
                Slider(
                  value: target,
                  min: 50,
                  max: 3000,
                  divisions: 59,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.textDisabled,
                  onChanged: (v) => setState(() => _localTarget = v),
                  onChangeEnd: (v) {
                    provider.setDailyTarget(v);
                    setState(() => _localTarget = null);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('50', style: TextStyle(fontSize: 10, color: AppColors.textDisabled)),
                    Text('3000 pts', style: TextStyle(fontSize: 10, color: AppColors.textDisabled)),
                  ],
                ),
              ],
            ),
          ),
        ),
        _PanelCard(
          title: '📊 Goal vs Aktual (14 Hari)',
          subtitle: '${AppColors.success} = target tercapai',
          child: gva.isEmpty
              ? const _EmptyState(message: 'Belum ada data untuk ditampilkan.')
              : SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: target,
                            color: AppColors.warning,
                            strokeWidth: 1.5,
                            dashArray: [6, 3],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: AppText.caption.copyWith(color: AppColors.warning, fontSize: 10),
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
                              final i = v.toInt();
                              if (i >= last14.length) return const SizedBox();
                              final day = last14[i].key;
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
                            if (group.x >= last14.length) return null;
                            return BarTooltipItem(
                              '${rod.toY.toStringAsFixed(0)} pts',
                              AppText.caption.copyWith(color: AppColors.primary, fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Shared Empty State ───────────────────────────────────────────────────────

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
            child: const Icon(Icons.bar_chart_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── 7. Wellbeing Panel ───────────────────────────────────────────────────────

class _WellbeingPanel extends StatelessWidget {
  const _WellbeingPanel();

  @override
  Widget build(BuildContext context) {
    final wellbeing = context.watch<WellbeingProvider>();
    final score = wellbeing.burnoutScore;
    final status = wellbeing.status;
    final insight = wellbeing.balanceInsight;
    final canDeclare = wellbeing.canDeclareRestDay;
    final restDayCount = wellbeing.restDayCount;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),

        // ── Stat chips ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(
              label: 'Burnout Score',
              value: score.toStringAsFixed(0),
              color: _statusColor(status),
            ),
            _StatChip(
              label: 'Status',
              value: _statusLabel(status),
              color: _statusColor(status),
            ),
            _StatChip(
              label: 'Rest Days',
              value: '$restDayCount kali',
              color: AppColors.success,
            ),
          ],
        ),

        // ── Burnout Score Gauge ───────────────────────────────────────────
        _PanelCard(
          title: '🫀 Burnout Score',
          subtitle: 'Score 0–100 berdasarkan 7 hari terakhir',
          child: Column(
            children: [
              _BurnoutGauge(score: score, status: status),
              const SizedBox(height: AppSpacing.md),
              _BurnoutStatusRow(status: status),
            ],
          ),
        ),

        // ── Balance Insight ───────────────────────────────────────────────
        _PanelCard(
          title: '📊 Balance Insight',
          subtitle: 'Keseimbangan aktivitas minggu ini',
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: _statusColor(status).withValues(alpha: 0.25)),
            ),
            child: Text(insight, style: AppText.body),
          ),
        ),

        // ── Rest Day Feature ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('☀️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hari Istirahat', style: AppText.title),
                          Text(
                            'Streak tetap aman • +10 poin self-care • Maks 1x per 7 hari',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
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
                    icon: Icon(
                      canDeclare ? Icons.self_improvement_rounded : Icons.lock_clock_rounded,
                      size: 18,
                    ),
                    label: Text(
                      canDeclare
                          ? 'Deklarasikan Hari Istirahat (+10 pts)'
                          : 'Sudah digunakan minggu ini',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canDeclare ? AppColors.success : AppColors.surfaceHigh,
                      foregroundColor: canDeclare ? Colors.white : AppColors.textDisabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(BurnoutStatus status) => switch (status) {
        BurnoutStatus.healthy   => AppColors.success,
        BurnoutStatus.attention => AppColors.warning,
        BurnoutStatus.fatigue   => const Color(0xFFFF8C00),
        BurnoutStatus.burnout   => AppColors.error,
      };

  String _statusLabel(BurnoutStatus status) => switch (status) {
        BurnoutStatus.healthy   => 'Sehat ✅',
        BurnoutStatus.attention => 'Perhatian ⚠️',
        BurnoutStatus.fatigue   => 'Kelelahan 🔶',
        BurnoutStatus.burnout   => 'Burnout 🔴',
      };
}

/// Custom arc gauge displaying burnout score 0–100.
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
                Text('/100', style: AppText.caption),
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
        BurnoutStatus.fatigue   => const Color(0xFFFF8C00),
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
      ..color = AppColors.textDisabled.withValues(alpha: 0.3)
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
          fontWeight: FontWeight.w500,
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
      (label: '61–80\nKelelahan', color: const Color(0xFFFF8C00)),
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
                  ? e.value.color.withValues(alpha: 0.18)
                  : AppColors.surfaceHigh,
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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }
}
