package com.example.earnjoy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * AppWidgetProvider for both the small (2×2) and medium (4×2) EarnJoy widgets.
 *
 * Data is written by [WidgetSyncService] in Dart via home_widget's SharedPreferences
 * bridge, so this class only reads values and populates RemoteViews.
 */
class EarnJoyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val points = prefs.getFloat("points", 0f).toInt()
            val streak = prefs.getInt("streak", 0)
            val dailyTarget = prefs.getFloat("daily_target", 300f)
            val todayPoints = prefs.getFloat("today_points", 0f)
            val progressPct = if (dailyTarget > 0) ((todayPoints / dailyTarget) * 100).toInt().coerceIn(0, 100) else 0

            // Determine which layout is being used by trying both
            val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
            val isSmall = widgetInfo?.initialLayout == R.layout.earnjoy_widget_small

            if (isSmall) {
                val views = RemoteViews(context.packageName, R.layout.earnjoy_widget_small)
                views.setTextViewText(R.id.widget_points, "$points pts")
                views.setTextViewText(R.id.widget_streak, "🔥 Day $streak")

                // Tap anywhere → open app home
                val openIntent = buildOpenIntent(context, "earnjoy://home")
                views.setOnClickPendingIntent(R.id.widget_log_btn, openIntent)
                val tapIntent = buildOpenIntent(context, "earnjoy://home")
                views.setOnClickPendingIntent(R.id.widget_app_label, tapIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } else {
                val views = RemoteViews(context.packageName, R.layout.earnjoy_widget_medium)
                views.setTextViewText(R.id.widget_points_med, "$points pts")
                views.setTextViewText(R.id.widget_streak_med, "$streak hari")
                views.setProgressBar(R.id.widget_progress, 100, progressPct, false)
                views.setTextViewText(R.id.widget_progress_pct, "$progressPct%")

                // Quick-log buttons — open app with deep-link
                views.setOnClickPendingIntent(
                    R.id.widget_btn_study,
                    buildOpenIntent(context, "earnjoy://quick_log?title=Study&category=Study&duration=30")
                )
                views.setOnClickPendingIntent(
                    R.id.widget_btn_work,
                    buildOpenIntent(context, "earnjoy://quick_log?title=Work&category=Work&duration=60")
                )
                views.setOnClickPendingIntent(
                    R.id.widget_btn_gym,
                    buildOpenIntent(context, "earnjoy://quick_log?title=Gym&category=Health&duration=45")
                )

                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }

        private fun buildOpenIntent(context: Context, uri: String): PendingIntent {
            return HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(uri)
            )
        }
    }
}
