import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/source/local/database_helper.dart';
import '../../data/source/local/tips_service.dart';
import '../../data/source/remote/weather_service.dart';
import '../../data/source/local/device_usage_service.dart';
import '../../data/services/enhanced_smart_tip_manager.dart';
import '../../core/services/weather_alert_service.dart';
import '../utils/notification_service.dart';
import '../constants/app_constants.dart';

/// Entry point cho WorkManager background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🚀 Background task started: $task');

    try {
      switch (task) {
        case BackgroundTaskManager.dailyTipTaskName:
          await _handleDailyTipTask();
          break;
        case BackgroundTaskManager.weeklyRecapTaskName:
          await _handleWeeklyRecapTask();
          break;
        case BackgroundTaskManager.contextTipTaskName:
          await _handleContextTipTask();
          break;
        case BackgroundTaskManager.smartTipTaskName:
          await _handleSmartTipTask();
          break;
        case BackgroundTaskManager.weatherAlertTaskName:
          await _handleWeatherAlertTask();
          break;
        default:
          print('❌ Unknown task: $task');
          return Future.value(false);
      }

      print('✅ Background task completed: $task');
      return Future.value(true);
    } catch (e, stackTrace) {
      print('❌ Background task error: $task - $e');
      print('📚 Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

class BackgroundTaskManager {
  static const String dailyTipTaskName = "dailyTipTask";
  static const String weeklyRecapTaskName = "weeklyRecapTask";
  static const String contextTipTaskName = "contextTipTask";
  static const String smartTipTaskName = "smartTipTask";
  static const String weatherAlertTaskName = "weatherAlertTask";

  static void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static void scheduleDailyTips() {
    Workmanager().registerPeriodicTask(
      dailyTipTaskName,
      dailyTipTaskName,
      frequency: const Duration(hours: 1), // Check every hour for testing
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static void scheduleWeeklyRecap() {
    Workmanager().registerPeriodicTask(
      weeklyRecapTaskName,
      weeklyRecapTaskName,
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static void scheduleContextTips() {
    Workmanager().registerPeriodicTask(
      contextTipTaskName,
      contextTipTaskName,
      frequency: const Duration(hours: 2), // Check every 2 hours
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static void scheduleSmartTips() {
    Workmanager().registerPeriodicTask(
      smartTipTaskName,
      smartTipTaskName,
      frequency: const Duration(minutes: 30), // Check every 30 minutes for testing
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static void scheduleWeatherAlerts() {
    Workmanager().registerPeriodicTask(
      weatherAlertTaskName,
      weatherAlertTaskName,
      frequency: const Duration(hours: 3), // Check every 3 hours for morning, noon, afternoon
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static void cancelAllTasks() {
    Workmanager().cancelAll();
  }
}

/// Global functions for background tasks
Future<void> _handleDailyTipTask() async {
  final prefs = await SharedPreferences.getInstance();
  final lastTipDate = prefs.getString(AppConstants.lastDailyTipDateKey);
  final today = DateTime.now().toIso8601String().split('T')[0];

  // Only generate tip if we haven't sent one today
  if (lastTipDate != today) {
    final db = DatabaseHelper.instance;
    final tipsService = TipsService.instance;

    // Generate daily tip
    final recentTips = await db.getAllTips();
    final recentTitles = recentTips.map((t) => t.title).toList();
    final tip = tipsService.getRandomDailyTip(recentTitles);

    // Save tip to database
    final tipWithDisplayTime = tip.copyWith(displayedAt: DateTime.now());
    await db.insertTip(tipWithDisplayTime);

    // Send notification
    await NotificationService.instance.showInstantNotification(
      id: AppConstants.dailyTipNotificationId,
      title: tip.title,
      body: tip.content,
      payload: 'daily_tip',
    );

    // Update last tip date
    await prefs.setString(AppConstants.lastDailyTipDateKey, today);
  }
}

Future<void> _handleWeeklyRecapTask() async {
  final now = DateTime.now();

  // Only run on Sunday evening
  if (now.weekday == DateTime.sunday && now.hour >= 18) {
    final prefs = await SharedPreferences.getInstance();
    final lastRecapDate = prefs.getString(AppConstants.lastWeeklyRecapDateKey);
    final thisWeek = "${now.year}-W${_getWeekNumber(now)}";

    if (lastRecapDate != thisWeek) {
      final usageService = DeviceUsageService.instance;
      final tipsService = TipsService.instance;
      final db = DatabaseHelper.instance;

      // Generate weekly recap
      final weeklyUsage = await usageService.getWeeklyUsage();
      final recap = usageService.generateWeeklyRecap(weeklyUsage);
      final challenges = usageService.generateMicroChallenges(recap);

      // Generate tips
      final weeklyTip = tipsService.generateWeeklyRecapTip(recap, challenges);
      final moodTip = tipsService.generateMoodTip(usageService.generateMoodGuess(weeklyUsage));

      // Save tips
      await db.insertTip(weeklyTip.copyWith(displayedAt: DateTime.now()));
      await db.insertTip(moodTip.copyWith(displayedAt: DateTime.now()));

      // Send notification
      await NotificationService.instance.showInstantNotification(
        id: AppConstants.weeklyRecapNotificationId,
        title: "📊 Weekly Recap",
        body: "Xem tổng kết tuần và thử thách mới cho tuần tới!",
        payload: 'weekly_recap',
      );

      // Update last recap date
      await prefs.setString(AppConstants.lastWeeklyRecapDateKey, thisWeek);
    }
  }
}

Future<void> _handleContextTipTask() async {
  final now = DateTime.now();

  // Only generate context tips during active hours (7 AM - 10 PM)
  if (now.hour >= 7 && now.hour <= 22) {
    final weatherService = WeatherService.instance;
    final tipsService = TipsService.instance;
    final db = DatabaseHelper.instance;

    // Check if we already sent a context tip in the last 4 hours
    final recentTips = await db.getAllTips();
    final recentContextTips = recentTips.where((tip) {
      final tipTime = tip.displayedAt ?? tip.createdAt;
      return (tip.type.name.contains('context')) &&
             now.difference(tipTime).inHours < 4;
    }).toList();

    if (recentContextTips.isEmpty) {
      // Try to get weather and generate weather tip
      final weather = await weatherService.getCurrentWeather();
      if (weather != null) {
        final weatherTips = tipsService.generateWeatherTips(weather);
        if (weatherTips.isNotEmpty) {
          final tip = weatherTips.first;

          // Save tip
          await db.insertTip(tip.copyWith(displayedAt: DateTime.now()));

          // Send notification
          await NotificationService.instance.showInstantNotification(
            id: AppConstants.contextTipNotificationId,
            title: tip.title,
            body: tip.content,
            payload: 'context_tip',
          );
        }
      }

      // Generate time-based tip if no weather tip
      if (weather == null) {
        final timeTip = tipsService.generateTimeTip();
        if (timeTip != null) {
          await db.insertTip(timeTip.copyWith(displayedAt: DateTime.now()));

          await NotificationService.instance.showInstantNotification(
            id: AppConstants.contextTipNotificationId,
            title: timeTip.title,
            body: timeTip.content,
            payload: 'time_tip',
          );
        }
      }
    }
  }
}

Future<void> _handleSmartTipTask() async {
  try {
    final enhancedManager = EnhancedSmartTipManager.instance;

    // Xử lý tất cả scheduled tips
    await enhancedManager.processScheduledTips();

    print('Smart tip task completed');
  } catch (e) {
    print('Error in smart tip task: $e');
  }
}

Future<void> _handleWeatherAlertTask() async {
  print('🌤️ Starting weather alert task...');

  try {
    final now = DateTime.now();
    final hour = now.hour;

    // Check if it's time for weather alert (morning: 7-9, noon: 11-13, afternoon: 15-17)
    bool isAlertTime = (hour >= 7 && hour <= 9) ||    // Morning
                       (hour >= 11 && hour <= 13) ||   // Noon
                       (hour >= 15 && hour <= 17);     // Afternoon

    if (!isAlertTime) {
      print('⏰ Not time for weather alert (current: ${hour}h)');
      return;
    }

    // Check if we already sent an alert in this period today
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final periodKey = 'weather_alert_${today}_${_getAlertPeriod(hour)}';
    final alreadySent = prefs.getBool(periodKey) ?? false;

    if (alreadySent) {
      print('⚠️ Weather alert already sent for this period today');
      return;
    }

    // Load weather alert service
    final weatherAlertService = WeatherAlertService.instance;
    await weatherAlertService.loadWeatherAlerts();

    // Get current weather
    final weatherService = WeatherService.instance;
    final weather = await weatherService.getCurrentWeather();

    if (weather == null) {
      print('❌ No weather data available for alert');
      return;
    }

    // Generate weather alert tip
    final alertTip = weatherAlertService.generateWeatherAlertTip(
      weather,
      forceGenerate: true,
    );

    if (alertTip == null) {
      print('⚠️ No weather alert generated');
      return;
    }

    // Save tip to database
    final db = DatabaseHelper.instance;
    final tipWithDisplayTime = alertTip.copyWith(
      displayedAt: DateTime.now(),
      context: {
        ...alertTip.context ?? {},
        'isWeatherAlert': true,
        'alertPeriod': _getAlertPeriod(hour),
        'backgroundGenerated': true,
      },
    );
    await db.insertTip(tipWithDisplayTime);

    // Send notification
    await NotificationService.instance.showInstantNotification(
      id: AppConstants.weatherAlertNotificationId,
      title: '🌤️ Weather Alert',
      body: alertTip.content,
      payload: 'weather_alert_${_getAlertPeriod(hour)}',
    );

    // Mark as sent for this period
    await prefs.setBool(periodKey, true);

    print('✅ Weather alert sent successfully for ${_getAlertPeriod(hour)}');

  } catch (e, stackTrace) {
    print('❌ Error in weather alert task: $e');
    print('📚 Stack trace: $stackTrace');
  }
}

String _getAlertPeriod(int hour) {
  if (hour >= 7 && hour <= 9) return 'morning';
  if (hour >= 11 && hour <= 13) return 'noon';
  if (hour >= 15 && hour <= 17) return 'afternoon';
  return 'other';
}

int _getWeekNumber(DateTime date) {
  int dayOfYear = int.parse(date.strftime("%j"));
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

extension DateTimeStrftime on DateTime {
  String strftime(String format) {
    if (format == "%j") {
      return dayOfYear.toString();
    }
    return toString();
  }

  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}
