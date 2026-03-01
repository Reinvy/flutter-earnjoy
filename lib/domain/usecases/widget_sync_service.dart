import 'package:home_widget/home_widget.dart';
import 'package:earnjoy/data/models/user.dart';

/// Syncs User data into native home screen widget via the home_widget bridge.
///
/// Call [updateWidget] every time points or streak changes in the app.
class WidgetSyncService {
  static const _appGroupId = 'com.example.earnjoy';

  /// Persist user data to SharedPreferences and trigger a widget redraw.
  static Future<void> updateWidget(User user, {double todayPoints = 0.0}) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<double>('points', user.pointBalance);
      await HomeWidget.saveWidgetData<int>('streak', user.streak);
      await HomeWidget.saveWidgetData<double>('daily_target', user.dailyPointTarget);
      await HomeWidget.saveWidgetData<double>('today_points', todayPoints);

      // Trigger update for both widget sizes
      await HomeWidget.updateWidget(
        androidName: 'EarnJoyWidgetProvider',
        iOSName: 'EarnJoyWidget',
        qualifiedAndroidName: 'com.example.earnjoy.EarnJoyWidgetProvider',
      );
      await HomeWidget.updateWidget(
        androidName: 'EarnJoyMediumWidgetProvider',
        iOSName: 'EarnJoyWidget',
        qualifiedAndroidName: 'com.example.earnjoy.EarnJoyMediumWidgetProvider',
      );
    } catch (_) {
      // Widget sync failures are non-critical — silently ignore
    }
  }
}
