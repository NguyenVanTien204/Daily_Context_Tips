import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../data/models/weather_model.dart';
import '../../data/models/tip_model.dart';

enum WeatherAlertType {
  sunnyLight,
  sunnyIntense,
  rainLight,
  rainHeavy,
  thunderstorm,
}

enum TimeOfDayAlert {
  morning,
  noon,
  afternoon,
}

class WeatherAlert {
  final String name;
  final String icon;
  final WeatherAlertType type;
  final Map<String, dynamic> conditions;
  final List<String> morningTips;
  final List<String> noonTips;
  final List<String> afternoonTips;

  WeatherAlert({
    required this.name,
    required this.icon,
    required this.type,
    required this.conditions,
    required this.morningTips,
    required this.noonTips,
    required this.afternoonTips,
  });

  factory WeatherAlert.fromJson(String key, Map<String, dynamic> json) {
    WeatherAlertType type;
    switch (key) {
      case 'sunny_light':
        type = WeatherAlertType.sunnyLight;
        break;
      case 'sunny_intense':
        type = WeatherAlertType.sunnyIntense;
        break;
      case 'rain_light':
        type = WeatherAlertType.rainLight;
        break;
      case 'rain_heavy':
        type = WeatherAlertType.rainHeavy;
        break;
      case 'thunderstorm':
        type = WeatherAlertType.thunderstorm;
        break;
      default:
        type = WeatherAlertType.sunnyLight;
    }

    return WeatherAlert(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '☀️',
      type: type,
      conditions: json['conditions'] ?? {},
      morningTips: (json['morning_tips'] as List<dynamic>?)?.cast<String>() ?? [],
      noonTips: (json['noon_tips'] as List<dynamic>?)?.cast<String>() ?? [],
      afternoonTips: (json['afternoon_tips'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  List<String> getTipsForTime(TimeOfDayAlert timeOfDay) {
    switch (timeOfDay) {
      case TimeOfDayAlert.morning:
        return morningTips;
      case TimeOfDayAlert.noon:
        return noonTips;
      case TimeOfDayAlert.afternoon:
        return afternoonTips;
    }
  }
}

class TimeSchedule {
  final List<int> timeRange;
  final String name;
  final int priority;

  TimeSchedule({
    required this.timeRange,
    required this.name,
    required this.priority,
  });

  factory TimeSchedule.fromJson(Map<String, dynamic> json) {
    return TimeSchedule(
      timeRange: (json['time_range'] as List<dynamic>?)?.cast<int>() ?? [0, 24],
      name: json['name'] ?? '',
      priority: json['priority'] ?? 1,
    );
  }

  bool isInTimeRange(int hour) {
    return hour >= timeRange[0] && hour < timeRange[1];
  }
}

class SeverityLevel {
  final int priority;
  final String color;
  final String icon;

  SeverityLevel({
    required this.priority,
    required this.color,
    required this.icon,
  });

  factory SeverityLevel.fromJson(Map<String, dynamic> json) {
    return SeverityLevel(
      priority: json['priority'] ?? 1,
      color: json['color'] ?? '#2196F3',
      icon: json['icon'] ?? 'ℹ️',
    );
  }
}

class WeatherAlertService {
  static WeatherAlertService? _instance;
  static WeatherAlertService get instance => _instance ??= WeatherAlertService._();
  WeatherAlertService._();

  Map<String, WeatherAlert>? _weatherAlerts;
  Map<String, TimeSchedule>? _timeSchedules;
  Map<String, SeverityLevel>? _severityLevels;
  bool _isLoaded = false;

  Future<void> loadWeatherAlerts() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/weather_alert_tips.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      // Load weather alerts
      _weatherAlerts = {};
      final alertsData = data['weather_alerts'] as Map<String, dynamic>;
      for (final entry in alertsData.entries) {
        _weatherAlerts![entry.key] = WeatherAlert.fromJson(entry.key, entry.value);
      }

      // Load time schedules
      _timeSchedules = {};
      final schedulesData = data['time_schedules'] as Map<String, dynamic>;
      for (final entry in schedulesData.entries) {
        _timeSchedules![entry.key] = TimeSchedule.fromJson(entry.value);
      }

      // Load severity levels
      _severityLevels = {};
      final severityData = data['severity_levels'] as Map<String, dynamic>;
      for (final entry in severityData.entries) {
        _severityLevels![entry.key] = SeverityLevel.fromJson(entry.value);
      }

      _isLoaded = true;
      print('✅ WeatherAlertService: Loaded ${_weatherAlerts!.length} weather alert types');
    } catch (e) {
      print('❌ WeatherAlertService: Error loading weather alerts: $e');
      rethrow;
    }
  }

  // Generate weather alert tip for current time and conditions
  TipModel? generateWeatherAlertTip(WeatherModel weather, {bool forceGenerate = false}) {
    if (!_isLoaded) {
      print('⚠️ WeatherAlertService not loaded yet');
      return null;
    }

    try {
      final now = DateTime.now();
      final hour = now.hour;

      // Determine time of day
      final timeOfDay = _getCurrentTimeOfDay(hour);
      if (timeOfDay == null) {
        print('⚠️ Current hour $hour is not in any alert time range');
        return null;
      }

      // Check if we should show alert for this time (3 times per day)
      if (!forceGenerate && !_shouldShowAlertNow(hour)) {
        print('⏰ Not time for weather alert yet');
        return null;
      }

      // Determine weather alert type based on conditions
      final alertType = _determineWeatherAlertType(weather);
      final weatherAlert = _weatherAlerts![_getAlertKey(alertType)];

      if (weatherAlert == null) {
        print('⚠️ No weather alert found for type: $alertType');
        return null;
      }

      // Get tips for current time period
      final tips = weatherAlert.getTipsForTime(timeOfDay);
      if (tips.isEmpty) {
        print('⚠️ No tips available for ${alertType.name} at ${timeOfDay.name}');
        return null;
      }

      // Select random tip
      final random = Random();
      final selectedTip = tips[random.nextInt(tips.length)];

      // Determine severity and priority
      final severity = _determineSeverity(alertType);
      final severityInfo = _severityLevels![severity] ?? _severityLevels!['info']!;

      final timeSchedule = _timeSchedules![timeOfDay.name]!;

      return TipModel(
        title: '${weatherAlert.icon} ${weatherAlert.name} - ${timeSchedule.name}',
        content: selectedTip,
        type: TipType.weatherSpecific, // Use existing TipType
        context: {
          'source': 'weather_alert_service',
          'alertType': alertType.name,
          'timeOfDay': timeOfDay.name,
          'severity': severity,
          'weather': {
            'condition': weather.condition,
            'temperature': weather.temperature,
            'humidity': weather.humidity,
            'windSpeed': weather.windSpeed,
            'uvIndex': weather.uvIndex,
          },
          'generatedAt': now.toIso8601String(),
          'isWeatherAlert': true,
          'scheduledTime': '${timeSchedule.timeRange[0]}h-${timeSchedule.timeRange[1]}h',
        },
        createdAt: now,
        priority: severityInfo.priority,
      );

    } catch (e) {
      print('❌ Error generating weather alert tip: $e');
      return null;
    }
  }

  // Get all possible weather alert tips for current weather (for testing)
  List<TipModel> generateAllTimeWeatherAlerts(WeatherModel weather) {
    if (!_isLoaded) return [];

    final alerts = <TipModel>[];
    final alertType = _determineWeatherAlertType(weather);
    final weatherAlert = _weatherAlerts![_getAlertKey(alertType)];

    if (weatherAlert == null) return [];

    final now = DateTime.now();
    final severity = _determineSeverity(alertType);
    final severityInfo = _severityLevels![severity] ?? _severityLevels!['info']!;

    // Generate for all time periods
    for (final timeOfDay in TimeOfDayAlert.values) {
      final tips = weatherAlert.getTipsForTime(timeOfDay);
      final timeSchedule = _timeSchedules![timeOfDay.name]!;

      if (tips.isNotEmpty) {
        final random = Random();
        alerts.add(TipModel(
          title: '${weatherAlert.icon} ${weatherAlert.name} - ${timeSchedule.name}',
          content: tips[random.nextInt(tips.length)],
          type: TipType.weatherSpecific,
          context: {
            'source': 'weather_alert_service',
            'alertType': alertType.name,
            'timeOfDay': timeOfDay.name,
            'severity': severity,
            'isTestGeneration': true,
          },
          createdAt: now,
          priority: severityInfo.priority,
        ));
      }
    }

    return alerts;
  }

  TimeOfDayAlert? _getCurrentTimeOfDay(int hour) {
    for (final entry in _timeSchedules!.entries) {
      if (entry.value.isInTimeRange(hour)) {
        switch (entry.key) {
          case 'morning':
            return TimeOfDayAlert.morning;
          case 'noon':
            return TimeOfDayAlert.noon;
          case 'afternoon':
            return TimeOfDayAlert.afternoon;
        }
      }
    }
    return null;
  }

  bool _shouldShowAlertNow(int hour) {
    // Show alerts at specific times: 7h (morning), 12h (noon), 15h (afternoon)
    final alertTimes = [7, 12, 15];
    return alertTimes.contains(hour);
  }

  WeatherAlertType _determineWeatherAlertType(WeatherModel weather) {
    final condition = weather.condition.toLowerCase();
    final temp = weather.temperature;
    final humidity = weather.humidity;
    final windSpeed = weather.windSpeed;

    // Check for thunderstorm first (highest priority)
    if (condition.contains('thunder') ||
        condition.contains('storm') ||
        condition.contains('sấm') ||
        condition.contains('sét') ||
        windSpeed > 25) {
      return WeatherAlertType.thunderstorm;
    }

    // Check for heavy rain
    if (condition.contains('heavy rain') ||
        condition.contains('mưa to') ||
        condition.contains('mưa rào') ||
        humidity > 90) {
      return WeatherAlertType.rainHeavy;
    }

    // Check for light rain
    if (condition.contains('rain') ||
        condition.contains('mưa') ||
        condition.contains('drizzle') ||
        condition.contains('phùn') ||
        humidity > 80) {
      return WeatherAlertType.rainLight;
    }

    // Check for intense sun
    if (condition.contains('clear') ||
        condition.contains('sunny') ||
        condition.contains('nắng') ||
        temp > 30) {
      return WeatherAlertType.sunnyIntense;
    }

    // Default to light sunny
    return WeatherAlertType.sunnyLight;
  }

  String _getAlertKey(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.sunnyLight:
        return 'sunny_light';
      case WeatherAlertType.sunnyIntense:
        return 'sunny_intense';
      case WeatherAlertType.rainLight:
        return 'rain_light';
      case WeatherAlertType.rainHeavy:
        return 'rain_heavy';
      case WeatherAlertType.thunderstorm:
        return 'thunderstorm';
    }
  }

  String _determineSeverity(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.thunderstorm:
        return 'critical';
      case WeatherAlertType.sunnyIntense:
      case WeatherAlertType.rainHeavy:
        return 'warning';
      case WeatherAlertType.rainLight:
      case WeatherAlertType.sunnyLight:
        return 'info';
    }
  }

  // Getters for debugging
  Map<String, WeatherAlert>? get weatherAlerts => _weatherAlerts;
  Map<String, TimeSchedule>? get timeSchedules => _timeSchedules;
  Map<String, SeverityLevel>? get severityLevels => _severityLevels;
  bool get isLoaded => _isLoaded;

  // Force reload
  Future<void> reload() async {
    _isLoaded = false;
    _weatherAlerts = null;
    _timeSchedules = null;
    _severityLevels = null;
    await loadWeatherAlerts();
  }
}
