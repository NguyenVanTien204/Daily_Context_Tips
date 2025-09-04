import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class TipCategory {
  final String name;
  final List<int>? timeRange;
  final Map<String, List<String>>? weatherConditions;
  final List<String>? tips;

  TipCategory({
    required this.name,
    this.timeRange,
    this.weatherConditions,
    this.tips,
  });

  factory TipCategory.fromJson(String name, Map<String, dynamic> json) {
    Map<String, List<String>>? weatherConditions;
    if (json['weather_conditions'] != null) {
      final weatherData = json['weather_conditions'] as Map<String, dynamic>;
      weatherConditions = weatherData.map<String, List<String>>(
        (key, value) => MapEntry(key, (value as List).cast<String>()),
      );
    }

    return TipCategory(
      name: name,
      timeRange: json['time_range']?.cast<int>(),
      weatherConditions: weatherConditions,
      tips: json['tips']?.cast<String>() ??
            json['productivity_tips']?.cast<String>() ??
            json['wind_down_tips']?.cast<String>() ??
            json['sleep_tips']?.cast<String>() ??
            json['hydration']?.cast<String>() ??
            json['movement']?.cast<String>() ??
            json['mental_health']?.cast<String>() ??
            json['focus_time']?.cast<String>() ??
            json['break_reminders']?.cast<String>(),
    );
  }
}

class WeatherThreshold {
  final int? min;
  final int? max;
  final String? unit;

  WeatherThreshold({this.min, this.max, this.unit});

  factory WeatherThreshold.fromJson(Map<String, dynamic> json) {
    return WeatherThreshold(
      min: json['min'],
      max: json['max'],
      unit: json['unit'],
    );
  }

  bool isInRange(double value) {
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }
}

class SmartTipCategoryService {
  static SmartTipCategoryService? _instance;
  static SmartTipCategoryService get instance => _instance ??= SmartTipCategoryService._();
  SmartTipCategoryService._();

  Map<String, TipCategory>? _categories;
  Map<String, Map<String, WeatherThreshold>>? _conditions;
  Map<String, dynamic>? _rawData; // Store raw JSON data for complex access
  bool _isLoaded = false;

  Future<void> loadCategories() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/tip_categories.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      _rawData = data; // Store raw data for complex access

      // Load categories
      _categories = {};
      final categoriesData = data['categories'] as Map<String, dynamic>;
      for (final entry in categoriesData.entries) {
        _categories![entry.key] = TipCategory.fromJson(entry.key, entry.value);
      }

      // Load conditions/thresholds
      _conditions = {};
      final conditionsData = data['conditions'] as Map<String, dynamic>;
      for (final conditionType in conditionsData.entries) {
        _conditions![conditionType.key] = {};
        final thresholds = conditionType.value as Map<String, dynamic>;
        for (final threshold in thresholds.entries) {
          _conditions![conditionType.key]![threshold.key] =
              WeatherThreshold.fromJson(threshold.value);
        }
      }

      _isLoaded = true;
      print('✅ SmartTipCategoryService: Loaded ${_categories!.length} categories');
    } catch (e) {
      print('❌ SmartTipCategoryService: Error loading categories: $e');
      rethrow;
    }
  }

  List<String> getSmartTips({
    required int hour,
    String? weatherCondition,
    double? temperature,
    double? humidity,
    double? windSpeed,
    int? uvIndex,
    String? specificCategory,
  }) {
    if (!_isLoaded) {
      print('⚠️ Categories not loaded yet');
      return ['Hệ thống đang khởi động, vui lòng chờ một chút...'];
    }

    final List<String> tips = [];
    final random = Random();

    try {
      // 1. Time-based tips
      final timeBasedCategory = _getTimeBasedCategory(hour);
      if (timeBasedCategory != null) {
        // Weather-specific tips for this time period
        if (weatherCondition != null && timeBasedCategory.weatherConditions != null) {
          final weatherTips = timeBasedCategory.weatherConditions![weatherCondition];
          if (weatherTips != null && weatherTips.isNotEmpty) {
            tips.add(weatherTips[random.nextInt(weatherTips.length)]);
          }
        }

        // General time-based tips
        if (timeBasedCategory.tips != null && timeBasedCategory.tips!.isNotEmpty) {
          tips.add(timeBasedCategory.tips![random.nextInt(timeBasedCategory.tips!.length)]);
        }
      }

      // 2. Weather condition-specific tips
      if (temperature != null) {
        final tempCategory = _getTemperatureCategory(temperature);
        if (tempCategory != null) {
          final tempTips = _categories!['weather_specific']?.weatherConditions?[tempCategory];
          if (tempTips != null && tempTips.isNotEmpty) {
            tips.add(tempTips[random.nextInt(tempTips.length)]);
          }
        }
      }

      // 3. Health & wellness tips (always include some)
      final healthTips = _getHealthTips(random);
      if (healthTips.isNotEmpty) {
        tips.addAll(healthTips);
      }

      // 4. Work productivity tips (during work hours)
      if (hour >= 8 && hour <= 18) {
        final workTips = _getWorkTips(random);
        if (workTips.isNotEmpty) {
          tips.addAll(workTips);
        }
      }

      // 5. Specific weather condition tips
      if (humidity != null && humidity > 80) {
        final humidityTips = _getSpecialWeatherTips('high_humidity', random);
        if (humidityTips.isNotEmpty) {
          tips.addAll(humidityTips);
        }
      }

      if (windSpeed != null && windSpeed > 12) {
        final windTips = _getSpecialWeatherTips('windy', random);
        if (windTips.isNotEmpty) {
          tips.addAll(windTips);
        }
      }

      if (temperature != null && temperature > 38) {
        final heatTips = _getSpecialWeatherTips('extreme_heat', random);
        if (heatTips.isNotEmpty) {
          tips.addAll(heatTips);
        }
      }

      // 6. Specific category request
      if (specificCategory != null) {
        final category = _categories![specificCategory];
        if (category?.tips != null && category!.tips!.isNotEmpty) {
          tips.add(category.tips![random.nextInt(category.tips!.length)]);
        }
      }

    } catch (e) {
      print('❌ Error getting smart tips: $e');
      return ['Có lỗi khi tải gợi ý. Hãy thử lại sau.'];
    }

    // Return tips or fallback
    if (tips.isEmpty) {
      return _getFallbackTips(hour);
    }

    // Limit to 2-3 tips to avoid overwhelming
    tips.shuffle();
    return tips.take(3).toList();
  }

  TipCategory? _getTimeBasedCategory(int hour) {
    for (final category in _categories!.values) {
      if (category.timeRange != null &&
          category.timeRange!.length == 2 &&
          hour >= category.timeRange![0] &&
          hour <= category.timeRange![1]) {
        return category;
      }
    }
    return null;
  }

  String? _getTemperatureCategory(double temperature) {
    final tempThresholds = _conditions!['temperature_thresholds'];
    if (tempThresholds == null) return null;

    for (final entry in tempThresholds.entries) {
      if (entry.value.isInRange(temperature)) {
        return entry.key;
      }
    }
    return null;
  }

  List<String> _getHealthTips(Random random) {
    if (_rawData == null) return [];

    try {
      final healthData = _rawData!['categories']['health_wellness'] as Map<String, dynamic>;
      final healthSubcategories = ['hydration', 'movement', 'mental_health'];
      final selectedSubcat = healthSubcategories[random.nextInt(healthSubcategories.length)];
      final subcatTips = healthData[selectedSubcat] as List<dynamic>?;

      if (subcatTips != null && subcatTips.isNotEmpty) {
        return [subcatTips[random.nextInt(subcatTips.length)]];
      }
    } catch (e) {
      print('❌ Error getting health tips: $e');
    }
    return [];
  }

  List<String> _getWorkTips(Random random) {
    if (_rawData == null) return [];

    try {
      final workData = _rawData!['categories']['work_productivity'] as Map<String, dynamic>;
      final workSubcategories = ['focus_time', 'break_reminders'];
      final selectedSubcat = workSubcategories[random.nextInt(workSubcategories.length)];
      final workTips = workData[selectedSubcat] as List<dynamic>?;

      if (workTips != null && workTips.isNotEmpty) {
        return [workTips[random.nextInt(workTips.length)]];
      }
    } catch (e) {
      print('❌ Error getting work tips: $e');
    }
    return [];
  }

  List<String> _getSpecialWeatherTips(String weatherType, Random random) {
    if (_rawData == null) return [];

    try {
      final weatherData = _rawData!['categories']['weather_specific'] as Map<String, dynamic>;
      final weatherTips = weatherData[weatherType] as List<dynamic>?;

      if (weatherTips != null && weatherTips.isNotEmpty) {
        return [weatherTips[random.nextInt(weatherTips.length)]];
      }
    } catch (e) {
      print('❌ Error getting special weather tips: $e');
    }
    return [];
  }

  List<String> _getFallbackTips(int hour) {
    if (hour >= 6 && hour < 12) {
      return ['Chào buổi sáng! Hãy bắt đầu ngày mới với năng lượng tích cực.'];
    } else if (hour >= 12 && hour < 18) {
      return ['Buổi chiều tốt lành! Đừng quên uống nước và nghỉ ngơi giữa giờ.'];
    } else if (hour >= 18 && hour < 23) {
      return ['Buổi tối dễ chịu! Thời gian tuyệt vời để thư giãn và gặp gỡ người thân.'];
    } else {
      return ['Đã khuya rồi! Hãy chuẩn bị nghỉ ngơi để có một giấc ngủ ngon.'];
    }
  }

  // Getter methods for debugging
  Map<String, TipCategory>? get categories => _categories;
  Map<String, Map<String, WeatherThreshold>>? get conditions => _conditions;
  bool get isLoaded => _isLoaded;

  // Force reload (useful for debugging)
  Future<void> reload() async {
    _isLoaded = false;
    _categories = null;
    _conditions = null;
    _rawData = null;
    await loadCategories();
  }
}
