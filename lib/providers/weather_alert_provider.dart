import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tip_model.dart';
import '../data/source/local/database_helper.dart';
import '../data/source/remote/weather_service.dart';
import '../core/services/weather_alert_service.dart';
import '../core/utils/notification_service.dart';
import '../core/constants/app_constants.dart';

// Weather Alert State
class WeatherAlertState {
  final List<TipModel> alertTips;
  final TipModel? currentAlert;
  final bool isLoading;
  final String? error;
  final DateTime? lastAlertTime;

  const WeatherAlertState({
    this.alertTips = const [],
    this.currentAlert,
    this.isLoading = false,
    this.error,
    this.lastAlertTime,
  });

  WeatherAlertState copyWith({
    List<TipModel>? alertTips,
    TipModel? currentAlert,
    bool? isLoading,
    String? error,
    DateTime? lastAlertTime,
  }) {
    return WeatherAlertState(
      alertTips: alertTips ?? this.alertTips,
      currentAlert: currentAlert ?? this.currentAlert,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastAlertTime: lastAlertTime ?? this.lastAlertTime,
    );
  }
}

// Weather Alert Provider
class WeatherAlertNotifier extends StateNotifier<WeatherAlertState> {
  WeatherAlertNotifier() : super(const WeatherAlertState());

  final DatabaseHelper _db = DatabaseHelper.instance;
  final WeatherService _weatherService = WeatherService.instance;
  final WeatherAlertService _alertService = WeatherAlertService.instance;

  Future<void> initialize() async {
    try {
      await _alertService.loadWeatherAlerts();
      print('✅ WeatherAlertProvider initialized');
    } catch (e) {
      print('❌ Error initializing WeatherAlertProvider: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> checkAndGenerateWeatherAlert({bool forceGenerate = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current weather
      final weather = await _weatherService.getCurrentWeather();
      if (weather == null) {
        print('⚠️ No weather data available for alert generation');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Check if we need to generate alert based on time schedule
      final now = DateTime.now();
      if (!forceGenerate && !_shouldGenerateAlert(now)) {
        print('⏰ Not time for weather alert generation');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Generate weather alert tip
      final alertTip = _alertService.generateWeatherAlertTip(
        weather,
        forceGenerate: forceGenerate,
      );

      if (alertTip != null) {
        // Save to database with special marker
        final tipWithDisplayTime = alertTip.copyWith(
          displayedAt: now,
          context: {
            ...alertTip.context ?? {},
            'isWeatherAlert': true,
            'alertGeneratedAt': now.toIso8601String(),
          },
        );

        await _db.insertTip(tipWithDisplayTime);

        // Send notification for weather alert (not for debug/force generate)
        if (!forceGenerate) {
          try {
            await NotificationService.instance.showInstantNotification(
              id: AppConstants.weatherAlertNotificationId,
              title: '🌤️ Weather Alert',
              body: alertTip.content,
              payload: 'weather_alert_${alertTip.type.name}',
            );
            print('📧 Weather alert notification sent');
          } catch (e) {
            print('❌ Error sending weather alert notification: $e');
          }
        }

        // Update state
        final updatedAlerts = [tipWithDisplayTime, ...state.alertTips];
        state = state.copyWith(
          alertTips: updatedAlerts,
          currentAlert: tipWithDisplayTime,
          lastAlertTime: now,
          isLoading: false,
        );

        print('✅ Weather alert generated: ${alertTip.title}');
      } else {
        print('⚠️ No weather alert generated for current conditions');
        state = state.copyWith(isLoading: false);
      }

    } catch (e) {
      print('❌ Error generating weather alert: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadTodayWeatherAlerts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Load weather alerts from database for today
      final allTips = await _db.getAllTips();
      final todayAlerts = allTips.where((tip) {
        final isWeatherAlert = tip.context?['isWeatherAlert'] == true;
        final isToday = tip.createdAt.isAfter(todayStart) &&
                        tip.createdAt.isBefore(todayEnd);
        return isWeatherAlert && isToday;
      }).toList();

      // Sort by creation time (newest first)
      todayAlerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        alertTips: todayAlerts,
        currentAlert: todayAlerts.isNotEmpty ? todayAlerts.first : null,
        isLoading: false,
      );

      print('📋 Loaded ${todayAlerts.length} weather alerts for today');

    } catch (e) {
      print('❌ Error loading today weather alerts: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> generateTestWeatherAlerts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _weatherService.getCurrentWeather();
      if (weather == null) {
        throw Exception('No weather data available');
      }

      // Generate alerts for all time periods
      final testAlerts = _alertService.generateAllTimeWeatherAlerts(weather);

      for (final alert in testAlerts) {
        await _db.insertTip(alert.copyWith(
          displayedAt: DateTime.now(),
          context: {
            ...alert.context ?? {},
            'isTestAlert': true,
          },
        ));
      }

      // Reload alerts
      await loadTodayWeatherAlerts();

      print('🧪 Generated ${testAlerts.length} test weather alerts');

    } catch (e) {
      print('❌ Error generating test weather alerts: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> markAlertAsRead(int alertId) async {
    try {
      final alert = state.alertTips.firstWhere((a) => a.id == alertId);
      final updatedAlert = alert.copyWith(isRead: true);
      await _db.updateTip(updatedAlert);

      // Update state
      final updatedAlerts = state.alertTips.map((a) {
        return a.id == alertId ? updatedAlert : a;
      }).toList();

      state = state.copyWith(alertTips: updatedAlerts);

    } catch (e) {
      print('❌ Error marking alert as read: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  bool _shouldGenerateAlert(DateTime now) {
    final hour = now.hour;

    // Generate alerts at 7h (morning), 12h (noon), 15h (afternoon)
    final alertHours = [7, 12, 15];

    if (!alertHours.contains(hour)) {
      return false;
    }

    // Check if we already generated alert in this hour
    if (state.lastAlertTime != null) {
      final lastHour = state.lastAlertTime!.hour;
      final lastDate = DateTime(
        state.lastAlertTime!.year,
        state.lastAlertTime!.month,
        state.lastAlertTime!.day,
      );
      final todayDate = DateTime(now.year, now.month, now.day);

      // If same day and same hour, don't generate again
      if (lastDate == todayDate && lastHour == hour) {
        return false;
      }
    }

    return true;
  }

  // Get stats for debug
  Map<String, int> getAlertStats() {
    final stats = <String, int>{};

    for (final alert in state.alertTips) {
      final alertType = alert.context?['alertType'] as String? ?? 'unknown';
      stats[alertType] = (stats[alertType] ?? 0) + 1;
    }

    return stats;
  }

  // Clear all alerts (for testing)
  Future<void> clearAllAlerts() async {
    try {
      // This would require a method in DatabaseHelper to delete weather alerts specifically
      // For now, just clear the state
      state = state.copyWith(
        alertTips: [],
        currentAlert: null,
        lastAlertTime: null,
      );
      print('🗑️ Cleared all weather alerts from state');
    } catch (e) {
      print('❌ Error clearing alerts: $e');
    }
  }
}

// Provider instance
final weatherAlertProvider = StateNotifierProvider<WeatherAlertNotifier, WeatherAlertState>((ref) {
  return WeatherAlertNotifier();
});
