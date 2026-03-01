import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:earnjoy/core/theme.dart';
import 'package:earnjoy/presentation/providers/notification_provider.dart';
import 'package:earnjoy/presentation/providers/activity_provider.dart';

/// Settings card for Smart Notification & Reminder Engine.
/// Placed inside ProfileScreen.
class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final activities = context.read<ActivityProvider>().todayActivities;
    // We use all activities for pattern analysis; todayActivities is just
    // available here, the full list would be better but provider exposes today.
    final bestTime = provider.bestReminderTime(activities);
    final bestLabel =
        '${bestTime.hour.toString().padLeft(2, '0')}:${bestTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          // ─── Toggle ────────────────────────────────────────────────────
          _buildRow(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.primary,
            title: 'Smart Notifications',
            subtitle: 'Pengingat cerdas berdasarkan pola aktivitasmu',
            trailing: Switch.adaptive(
              value: provider.notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (_) async {
                await provider.toggleNotifications();
              },
            ),
          ),

          if (provider.notificationsEnabled) ...[
            Divider(color: AppColors.glassBorder, height: 1),

            // ─── Best reminder time (read-only) ──────────────────────
            _buildRow(
              icon: Icons.schedule_outlined,
              iconColor: AppColors.success,
              title: 'Waktu Terbaik',
              subtitle: 'Berdasarkan pola loggingmu: $bestLabel',
              trailing: const SizedBox.shrink(),
            ),

            Divider(color: AppColors.glassBorder, height: 1),

            // ─── Quiet hours ─────────────────────────────────────────
            _buildRow(
              icon: Icons.bedtime_outlined,
              iconColor: AppColors.warning,
              title: 'Quiet Hours',
              subtitle:
                  '${_fmtHour(provider.quietHoursStart)} – ${_fmtHour(provider.quietHoursEnd)} (tidak ada notif)',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onTap: () => _showQuietHoursPicker(context, provider),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.title.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.body.copyWith(fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  String _fmtHour(int hour) {
    final tod = TimeOfDay(hour: hour, minute: 0);
    final h = tod.hour.toString().padLeft(2, '0');
    return '$h:00';
  }

  Future<void> _showQuietHoursPicker(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    int startHour = provider.quietHoursStart;
    int endHour = provider.quietHoursEnd;

    final startPicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startHour, minute: 0),
      helpText: 'Quiet hours mulai',
      builder: (ctx, child) => _darkTimePicker(ctx, child),
    );
    if (startPicked == null || !context.mounted) return;
    startHour = startPicked.hour;

    final endPicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: endHour, minute: 0),
      helpText: 'Quiet hours selesai',
      builder: (ctx, child) => _darkTimePicker(ctx, child),
    );
    if (endPicked == null || !context.mounted) return;
    endHour = endPicked.hour;

    await context.read<NotificationProvider>().setQuietHours(
          startHour: startHour,
          endHour: endHour,
        );
  }

  Widget _darkTimePicker(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
      ),
      child: child!,
    );
  }
}
