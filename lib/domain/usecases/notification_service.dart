import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:earnjoy/data/models/activity.dart';
import 'package:earnjoy/data/models/quest.dart';
import 'package:earnjoy/data/models/reward.dart';
import 'package:earnjoy/data/models/user.dart';

/// Notification IDs — grouped by type to avoid collisions.
class NotifId {
  static const int streakAlert = 1;
  static const int weeklyMotivation = 2;
  static const int inactivityNudge = 3;
  static const int dailyReminder = 4;
  static const int goalProximityBase = 100; // 100 + index
  static const int questDeadlineBase = 200; // 200 + index (max 50)
}

/// Smart notification engine that learns from user activity patterns.
///
/// Responsibilities:
/// - Initialize flutter_local_notifications + timezone
/// - Request runtime permission
/// - Schedule contextual reminders (streak, quest deadlines, goal proximity)
/// - Schedule smart daily reminder at the user's most-active hour
/// - Cancel & reschedule after each activity log
class SmartNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialization ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Requests notification permission from the OS.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  // ─── Smart Scheduling Logic ───────────────────────────────────────────────

  /// Analyses the last 30 activity logs and returns the hour (0–23) with the
  /// most frequent activity, respecting quiet hours.
  /// Falls back to [user.preferredReminderHour] if >= 0, or 9 as default.
  int getBestReminderHour(User user, List<Activity> recentActivities) {
    // If user manually set a preferred hour, respect it
    if (user.preferredReminderHour >= 0) {
      return _respectQuietHours(user.preferredReminderHour, user);
    }

    final last30 = recentActivities.take(30).toList();
    if (last30.isEmpty) return _respectQuietHours(9, user);

    // Count activity frequency per hour
    final Map<int, int> hourCount = {};
    for (final activity in last30) {
      final hour = activity.createdAt.hour;
      hourCount[hour] = (hourCount[hour] ?? 0) + 1;
    }

    // Find the peak hour
    int bestHour = 9;
    int bestCount = 0;
    for (final entry in hourCount.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        bestHour = entry.key;
      }
    }

    return _respectQuietHours(bestHour, user);
  }

  /// If [hour] falls within quiet hours, shifts it to [user.quietHoursEnd].
  int _respectQuietHours(int hour, User user) {
    final start = user.quietHoursStart;
    final end = user.quietHoursEnd;

    bool isQuiet;
    if (start <= end) {
      // e.g. 10–14: quiet between those hours
      isQuiet = hour >= start && hour < end;
    } else {
      // Wraps midnight e.g. 22–07: quiet from 22:00 tonight to 07:00 tomorrow
      isQuiet = hour >= start || hour < end;
    }

    return isQuiet ? end : hour;
  }

  // ─── Individual Schedulers ────────────────────────────────────────────────

  /// Schedules a streak protection alert 3 hours before midnight IF the user
  /// has an active streak (> 0) and the scheduled time hasn't passed yet.
  Future<void> scheduleStreakAlert(int streak, User user) async {
    if (!user.notificationsEnabled || streak <= 0) return;

    await _plugin.cancel(NotifId.streakAlert);

    final now = DateTime.now();
    // Alert fires at 21:00 (3 h before midnight)
    var alertTime = DateTime(now.year, now.month, now.day, 21, 0);
    if (alertTime.isBefore(now)) {
      // Today's window already passed — skip until next launch
      return;
    }

    final tzAlert = tz.TZDateTime.from(alertTime, tz.local);

    await _plugin.zonedSchedule(
      NotifId.streakAlert,
      '⚡ Streak Terancam!',
      'Kamu belum log hari ini. Streak $streak harimu bisa putus! Yuk log sekarang.',
      tzAlert,
      _channelDetails(
        id: 'streak_channel',
        name: 'Streak Alerts',
        desc: 'Peringatan saat streak hampir putus',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules notifications 1 hour before each active quest expires.
  Future<void> scheduleQuestDeadlineNotifications(
    List<Quest> quests,
    User user,
  ) async {
    if (!user.notificationsEnabled) return;

    // Cancel existing quest deadline notifications
    for (var i = 0; i < 50; i++) {
      await _plugin.cancel(NotifId.questDeadlineBase + i);
    }

    final now = DateTime.now();
    int idx = 0;

    for (final quest in quests.where((q) => !q.isCompleted)) {
      final deadline = quest.expiresAt.subtract(const Duration(hours: 1));
      if (deadline.isAfter(now)) {
        final tzDeadline = tz.TZDateTime.from(deadline, tz.local);
        await _plugin.zonedSchedule(
          NotifId.questDeadlineBase + idx,
          '🗡️ Quest Hampir Berakhir!',
          '"${quest.title}" berakhir dalam 1 jam. Jangan lewatkan +${quest.bonusPoints.toInt()} poin!',
          tzDeadline,
          _channelDetails(
            id: 'quest_channel',
            name: 'Quest Deadlines',
            desc: 'Pengingat deadline quest aktif',
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        idx++;
        if (idx >= 50) break;
      }
    }
  }

  /// Schedules a one-time goal proximity notification for rewards
  /// that the user is at >= 80% progress toward.
  Future<void> scheduleGoalProximityNotification(
    List<Reward> rewards,
    double currentPoints,
    User user,
  ) async {
    if (!user.notificationsEnabled) return;

    // Cancel existing goal notifications
    for (var i = 0; i < 20; i++) {
      await _plugin.cancel(NotifId.goalProximityBase + i);
    }

    final now = DateTime.now();
    int idx = 0;

    // Find rewards user is close to affording (80–99%)
    final nearRewards = rewards
        .where(
          (r) =>
            !r.isRedeemed &&
            r.pointCost > 0 &&
            currentPoints / r.pointCost >= 0.8 &&
            currentPoints < r.pointCost,
        )
        .toList();

    for (final reward in nearRewards) {
      final remaining = (reward.pointCost - currentPoints).ceil();
      // Schedule the notification 5 minutes from now as a one-time nudge
      final notifTime = now.add(const Duration(minutes: 5));
      final tzTime = tz.TZDateTime.from(notifTime, tz.local);

      await _plugin.zonedSchedule(
        NotifId.goalProximityBase + idx,
        '🎁 Hampir Sampai!',
        'Kamu tinggal $remaining poin lagi untuk redeem "${reward.name}"!',
        tzTime,
        _channelDetails(
          id: 'goal_channel',
          name: 'Goal Progress',
          desc: 'Notif saat mendekati target reward',
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      idx++;
      if (idx >= 20) break;
    }
  }

  /// Schedules a recurring daily reminder at the user's best activity hour.
  Future<void> scheduleDailySmartReminder(
    User user,
    List<Activity> recentActivities,
  ) async {
    await _plugin.cancel(NotifId.dailyReminder);
    if (!user.notificationsEnabled) return;

    final bestHour = getBestReminderHour(user, recentActivities);
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, bestHour, 0);
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }
    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      NotifId.dailyReminder,
      '⚡ EarnJoy menyapa!',
      'Waktunya log aktivitas dan kumpulkan poin hari ini, ${user.name}! 🚀',
      tzTime,
      _channelDetails(
        id: 'daily_channel',
        name: 'Daily Reminders',
        desc: 'Pengingat harian cerdas',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  /// Schedules a one-time inactivity nudge 36 hours from [lastActivityDate].
  /// Only fires once after a prolonged absence.
  Future<void> scheduleInactivityNudge(User user) async {
    await _plugin.cancel(NotifId.inactivityNudge);
    if (!user.notificationsEnabled) return;

    final nudgeTime = user.lastActivityDate.add(const Duration(hours: 36));
    if (nudgeTime.isBefore(DateTime.now())) return;

    final tzNudge = tz.TZDateTime.from(nudgeTime, tz.local);

    await _plugin.zonedSchedule(
      NotifId.inactivityNudge,
      '👋 Sudah lama nih!',
      'EarnJoy kangen kamu, ${user.name}. Satu log kecil bisa memulihkan momentummu!',
      tzNudge,
      _channelDetails(
        id: 'inactivity_channel',
        name: 'Inactivity Nudge',
        desc: 'Pengingat setelah tidak aktif 36 jam',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedules a Monday morning motivation every week.
  Future<void> scheduleWeeklyMotivation(User user) async {
    await _plugin.cancel(NotifId.weeklyMotivation);
    if (!user.notificationsEnabled) return;

    final now = DateTime.now();
    // Find the next Monday at 08:00
    int daysUntilMonday = DateTime.monday - now.weekday;
    if (daysUntilMonday <= 0) daysUntilMonday += 7;
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilMonday,
      8,
      0,
    );
    final tzMonday = tz.TZDateTime.from(nextMonday, tz.local);

    await _plugin.zonedSchedule(
      NotifId.weeklyMotivation,
      '🚀 Minggu Baru, Semangat Baru!',
      'Minggu baru siap dimulai. Yuk mulai dengan satu aktivitas dan jaga streakmu! 🔥',
      tzMonday,
      _channelDetails(
        id: 'weekly_channel',
        name: 'Weekly Motivation',
        desc: 'Motivasi setiap Senin pagi',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Convenience: cancel then reschedule everything from scratch.
  Future<void> rescheduleAll({
    required User user,
    required List<Activity> recentActivities,
    required List<Quest> quests,
    required List<Reward> rewards,
  }) async {
    if (!user.notificationsEnabled) {
      await cancelAll();
      return;
    }
    await Future.wait([
      scheduleStreakAlert(user.streak, user),
      scheduleQuestDeadlineNotifications(quests, user),
      scheduleGoalProximityNotification(
        rewards,
        user.pointBalance,
        user,
      ),
      scheduleDailySmartReminder(user, recentActivities),
      scheduleInactivityNudge(user),
      scheduleWeeklyMotivation(user),
    ]);
  }

  /// Cancels all pending notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Returns a [TimeOfDay] for the best reminder hour (for display in UI).
  TimeOfDay bestReminderTimeOfDay(User user, List<Activity> recentActivities) {
    final hour = getBestReminderHour(user, recentActivities);
    return TimeOfDay(hour: hour, minute: 0);
  }

  NotificationDetails _channelDetails({
    required String id,
    required String name,
    required String desc,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        id,
        name,
        channelDescription: desc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
