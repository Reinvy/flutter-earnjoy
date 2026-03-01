import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/data/models/activity_preset.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';
import 'package:earnjoy/presentation/providers/user_provider.dart';

/// Bottom sheet that lets the user log one of their preset activities instantly,
/// without any input other than tapping a tile.
///
/// Opened from the HomeScreen "Quick Log" button or from a widget/shortcut
/// deep-link (pre-selects a row if [presetTitle] is supplied).
class QuickLogSheet extends StatefulWidget {
  final String? presetTitle; // from deep-link, optionally pre-selects a row

  const QuickLogSheet({super.key, this.presetTitle});

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  String? _logged;
  double? _earned;

  @override
  void initState() {
    super.initState();
    // Auto-log the requested preset immediately (from widget / shortcut)
    if (widget.presetTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryAutoLog(widget.presetTitle!);
      });
    }
  }

  void _tryAutoLog(String title) {
    final ap = context.read<ActivityProvider>();
    final preset = ap.presets
        .where((p) => p.title.toLowerCase() == title.toLowerCase())
        .firstOrNull;
    if (preset == null) return;
    _log(ap, preset);
  }

  void _log(ActivityProvider ap, ActivityPreset preset) {
    final categoryId = preset.category.targetId;
    if (categoryId == 0) return;

    final points = ap.logActivity(
      title: preset.title,
      categoryId: categoryId,
      durationMinutes: preset.durationMinutes,
    );

    setState(() {
      _logged = preset.title;
      _earned = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final user = context.watch<UserProvider>().user;
    final presets = ap.presets;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      '⚡ Quick Log',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${user.pointBalance.toStringAsFixed(0)} pts',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.surface, height: 1),

              // Success banner
              if (_logged != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('✅ ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          '${_logged!} logged! +${_earned?.toStringAsFixed(0) ?? '?'} pts',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Preset list
              Expanded(
                child: presets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline,
                                color: AppColors.textDisabled, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'No presets yet.\nCreate presets on the Home screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: presets.length,
                        itemBuilder: (_, i) {
                          final preset = presets[i];
                          final isJustLogged = _logged == preset.title;
                          return _PresetTile(
                            preset: preset,
                            isLogged: isJustLogged,
                            onTap: () => _log(ap, preset),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  final ActivityPreset preset;
  final bool isLogged;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.isLogged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = preset.category.target;
    final catName = cat?.name ?? 'General';
    final catIcon = cat?.icon ?? '🏷️';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: isLogged
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category icon circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(catIcon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$catName · ${preset.durationMinutes} min',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLogged ? Icons.check_circle_rounded : Icons.bolt_rounded,
                  color:
                      isLogged ? AppColors.primary : AppColors.textDisabled,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
