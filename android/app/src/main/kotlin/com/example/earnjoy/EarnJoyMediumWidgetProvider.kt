package com.example.earnjoy

import android.appwidget.AppWidgetManager
import android.content.Context

/**
 * Medium (4×2) widget provider — delegates to [EarnJoyWidgetProvider.updateWidget].
 */
class EarnJoyMediumWidgetProvider : android.appwidget.AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // Re-use the companion logic; medium layout is the default fallback
            val views = android.widget.RemoteViews(context.packageName, R.layout.earnjoy_widget_medium)
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val points = prefs.getFloat("points", 0f).toInt()
            val streak = prefs.getInt("streak", 0)
            val dailyTarget = prefs.getFloat("daily_target", 300f)
            val todayPoints = prefs.getFloat("today_points", 0f)
            val progressPct = if (dailyTarget > 0)
                ((todayPoints / dailyTarget) * 100).toInt().coerceIn(0, 100) else 0

            views.setTextViewText(R.id.widget_points_med, "$points pts")
            views.setTextViewText(R.id.widget_streak_med, "$streak hari")
            views.setProgressBar(R.id.widget_progress, 100, progressPct, false)
            views.setTextViewText(R.id.widget_progress_pct, "$progressPct%")

            val openStudy = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java,
                android.net.Uri.parse("earnjoy://quick_log?title=Study&category=Study&duration=30")
            )
            val openWork = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java,
                android.net.Uri.parse("earnjoy://quick_log?title=Work&category=Work&duration=60")
            )
            val openGym = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java,
                android.net.Uri.parse("earnjoy://quick_log?title=Gym&category=Health&duration=45")
            )

            views.setOnClickPendingIntent(R.id.widget_btn_study,
                android.app.PendingIntent.getActivity(context, 1, openStudy,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE))
            views.setOnClickPendingIntent(R.id.widget_btn_work,
                android.app.PendingIntent.getActivity(context, 2, openWork,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE))
            views.setOnClickPendingIntent(R.id.widget_btn_gym,
                android.app.PendingIntent.getActivity(context, 3, openGym,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
