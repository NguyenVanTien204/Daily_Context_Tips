import 'dart:math';
import '../../models/tip_model.dart';
import '../../models/weather_model.dart';
import '../../../core/services/smart_tip_category_service.dart';
import '../../../core/utils/notification_service.dart';

class TipsService {
  static final TipsService instance = TipsService._init();
  final Random _random = Random();
  final SmartTipCategoryService _smartTipService = SmartTipCategoryService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  TipsService._init();

  // Initialize smart tip service
  Future<void> initialize() async {
    await _smartTipService.loadCategories();
    await _notificationService.initialize();
  }

  // Enhanced smart tip generation with advanced context awareness
  Future<List<TipModel>> generateSmartContextTips({
    WeatherModel? weather,
    bool includeLocation = true,
    bool forceGenerate = false,
  }) async {
    final tips = <TipModel>[];
    final now = DateTime.now();
    final hour = now.hour;

    try {
      // Enhanced smart tip request with comprehensive context
      final smartTips = _smartTipService.getSmartTips(
        hour: hour,
        weatherCondition: weather != null ? _mapWeatherCondition(weather.condition) : null,
        temperature: weather?.temperature.toDouble(),
        humidity: weather?.humidity.toDouble(),
        windSpeed: weather?.windSpeed,
        uvIndex: weather?.uvIndex.toInt(),
      );

      // Generate prioritized tips based on current context
      final priorities = _calculateTipPriorities(hour, weather);

      for (final tipText in smartTips.take(3)) {
        final tipType = _determineTipType(tipText, hour, weather);
        final priority = priorities[tipType] ?? 1;

        tips.add(TipModel(
          title: _generateContextualTitle(tipType, weather),
          content: tipText,
          type: tipType,
          context: _buildEnhancedContext(hour, weather, tipType),
          createdAt: now,
          priority: priority,
        ));
      }

      // Add time-specific enhancement tips
      final timeTip = _generateEnhancedTimeTip(hour, weather);
      if (timeTip != null) {
        tips.add(timeTip);
      }

      // Add weather-specific safety/comfort tips
      if (weather != null) {
        final weatherTips = _generateEnhancedWeatherTips(weather);
        tips.addAll(weatherTips);
      }

    } catch (e) {
      print('❌ Error generating smart context tips: $e');
      // Fallback to basic tip
      tips.add(_generateFallbackTip(hour, weather));
    }

    return tips;
  }

  // Instant smart tip trigger for debug/testing
  Future<TipModel> triggerInstantSmartTip({
    WeatherModel? weather,
    bool sendNotification = true,
    String? debugContext,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;

    print('🔥 INSTANT SMART TIP TRIGGER:');
    print('⏰ Time: ${hour}h (${_getTimeOfDayVietnamese(hour)})');
    if (weather != null) {
      print('🌤️ Weather: ${weather.condition}, ${weather.temperature.round()}°C, ${weather.humidity.round()}%');
      print('💨 Wind: ${weather.windSpeed.round()}km/h');
      print('☀️ UV: ${weather.uvIndex.round()}');
    }
    if (debugContext != null) {
      print('🐛 Debug Context: $debugContext');
    }

    // Get most relevant tip for current context
    final smartTips = _smartTipService.getSmartTips(
      hour: hour,
      weatherCondition: weather != null ? _mapWeatherCondition(weather.condition) : null,
      temperature: weather?.temperature.toDouble(),
      humidity: weather?.humidity.toDouble(),
      windSpeed: weather?.windSpeed,
    );

    final selectedTip = smartTips.isNotEmpty ? smartTips.first : _getFallbackMessage(hour);

    print('💡 Selected tip: ${selectedTip.substring(0, selectedTip.length.clamp(0, 50))}...');

    final tip = TipModel(
      title: '⚡ Instant Smart Tip',
      content: selectedTip,
      type: TipType.contextTime,
      context: _buildEnhancedContext(hour, weather, TipType.contextTime)
        ..addAll({
          'isInstantTrigger': true,
          'debugContext': debugContext,
          'triggerTime': now.toIso8601String(),
        }),
      createdAt: now,
      priority: 3, // High priority for instant tips
    );

    // Send immediate notification if requested
    if (sendNotification) {
      try {
        await _notificationService.showInstantNotification(
          id: now.millisecondsSinceEpoch,
          title: '⚡ Smart Tip Alert',
          body: selectedTip,
          payload: 'instant_tip_${tip.type.name}',
        );
        print('✅ Notification sent successfully');
      } catch (e) {
        print('❌ Error sending notification: $e');
      }
    }

    return tip;
  }

  // Enhanced weather tip priority calculation
  Map<TipType, int> _calculateTipPriorities(int hour, WeatherModel? weather) {
    final priorities = <TipType, int>{
      TipType.daily: 1,
      TipType.contextTime: 2,
      TipType.contextWeather: 1,
      TipType.weatherSpecific: 1,
    };

    // Boost priorities based on context
    if (weather != null) {
      final temp = weather.temperature;
      final humidity = weather.humidity;

      // Extreme weather gets higher priority
      if (temp < 5 || temp > 35) {
        priorities[TipType.contextWeather] = 3;
      }

      if (humidity > 80 || humidity < 30) {
        priorities[TipType.contextWeather] = 3;
      }
    }

    // Work hours get productivity boost
    if (hour >= 8 && hour <= 18) {
      priorities[TipType.daily] = 2;
    }

    // Evening/night gets wellness boost
    if (hour >= 18 || hour <= 6) {
      priorities[TipType.contextTime] = 3;
    }

    return priorities;
  }

  // Enhanced context building
  Map<String, dynamic> _buildEnhancedContext(int hour, WeatherModel? weather, TipType tipType) {
    final context = <String, dynamic>{
      'hour': hour,
      'timeOfDay': _getTimeOfDay(hour),
      'dayOfWeek': DateTime.now().weekday,
      'isWeekend': DateTime.now().weekday >= 6,
      'source': 'enhanced_smart_tip_service',
      'generatedAt': DateTime.now().toIso8601String(),
      'tipType': tipType.name,
    };

    if (weather != null) {
      context.addAll({
        'weather': {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'condition': weather.condition,
          'location': weather.location,
          'windSpeed': weather.windSpeed,
          'uvIndex': weather.uvIndex,
          'description': weather.description,
        },
        'weatherCategory': _mapWeatherCondition(weather.condition),
        'isExtremeWeather': _isExtremeWeather(weather),
      });
    }

    return context;
  }

  // Determine tip type based on content and context
  TipType _determineTipType(String tipContent, int hour, WeatherModel? weather) {
    final lowerContent = tipContent.toLowerCase();

    if (weather != null && (lowerContent.contains('thời tiết') ||
        lowerContent.contains('nhiệt độ') ||
        lowerContent.contains('mưa') ||
        lowerContent.contains('nắng'))) {
      return TipType.contextWeather;
    }

    if (lowerContent.contains('buổi') ||
        lowerContent.contains('sáng') ||
        lowerContent.contains('chiều') ||
        lowerContent.contains('tối')) {
      return TipType.contextTime;
    }

    return TipType.daily;
  }

  // Generate contextual titles
  String _generateContextualTitle(TipType tipType, WeatherModel? weather) {
    switch (tipType) {
      case TipType.contextWeather:
        if (weather != null) {
          return '🌤️ Tips cho ${weather.condition} (${weather.temperature.round()}°C)';
        }
        return '🌤️ Tips thời tiết';
      case TipType.contextTime:
        return '⏰ Tips ${_getTimeOfDayVietnamese(DateTime.now().hour)}';
      case TipType.weatherSpecific:
        return '📍 Tips thời tiết đặc biệt';
      default:
        return '💡 Smart Tips';
    }
  }

  // Enhanced time-based tip generation
  TipModel? _generateEnhancedTimeTip(int hour, WeatherModel? weather) {
    try {
      String? timeTip;
      String timeContext = _getTimeOfDay(hour);

      // Context-aware time tips
      if (timeContext == 'morning' && weather != null && weather.temperature < 15) {
        timeTip = 'Buổi sáng lạnh, hãy mặc ấm và uống nước ấm để khởi động ngày mới!';
      } else if (timeContext == 'afternoon' && weather != null && weather.temperature > 30) {
        timeTip = 'Buổi chiều nóng, tìm chỗ râm mát và uống nhiều nước để giữ cơ thể mát mẻ.';
      } else if (timeContext == 'evening') {
        timeTip = 'Buổi tối là lúc thích hợp để thư giãn và chuẩn bị cho giấc ngủ ngon.';
      } else if (timeContext == 'night') {
        timeTip = 'Đã khuya, hãy tắt thiết bị điện tử và chuẩn bị nghỉ ngơi.';
      }

      if (timeTip != null) {
        return TipModel(
          title: '⏰ Tips thời gian thông minh',
          content: timeTip,
          type: TipType.contextTime,
          context: _buildEnhancedContext(hour, weather, TipType.contextTime),
          createdAt: DateTime.now(),
          priority: 2,
        );
      }
    } catch (e) {
      print('❌ Error generating enhanced time tip: $e');
    }
    return null;
  }

  // Enhanced weather tips with safety considerations
  List<TipModel> _generateEnhancedWeatherTips(WeatherModel weather) {
    final tips = <TipModel>[];

    try {
      // Temperature-based tips
      if (weather.temperature > 35) {
        tips.add(TipModel(
          title: '🌡️ Cảnh báo nhiệt độ cao',
          content: 'Nhiệt độ ${weather.temperature.round()}°C rất cao! Tránh ra ngoài trưa, uống nhiều nước, và ở nơi mát mẻ.',
          type: TipType.contextWeather,
          context: _buildEnhancedContext(DateTime.now().hour, weather, TipType.contextWeather),
          createdAt: DateTime.now(),
          priority: 3,
        ));
      } else if (weather.temperature < 5) {
        tips.add(TipModel(
          title: '🧥 Cảnh báo thời tiết lạnh',
          content: 'Nhiệt độ ${weather.temperature.round()}°C rất lạnh! Mặc nhiều lớp áo, đeo găng tay và giữ ấm cơ thể.',
          type: TipType.contextWeather,
          context: _buildEnhancedContext(DateTime.now().hour, weather, TipType.contextWeather),
          createdAt: DateTime.now(),
          priority: 3,
        ));
      }

      // Humidity-based tips
      if (weather.humidity > 85) {
        tips.add(TipModel(
          title: '💧 Độ ẩm cao',
          content: 'Độ ẩm ${weather.humidity}% rất cao! Sử dụng quạt, tránh hoạt động nặng, và giữ khô ráo.',
          type: TipType.contextWeather,
          context: _buildEnhancedContext(DateTime.now().hour, weather, TipType.contextWeather),
          createdAt: DateTime.now(),
          priority: 2,
        ));
      }

      // Wind-based tips
      if (weather.windSpeed > 15) {
        tips.add(TipModel(
          title: '💨 Gió mạnh',
          content: 'Gió ${weather.windSpeed.round()}km/h khá mạnh! Cẩn thận khi di chuyển và cố định đồ vật.',
          type: TipType.contextWeather,
          context: _buildEnhancedContext(DateTime.now().hour, weather, TipType.contextWeather),
          createdAt: DateTime.now(),
          priority: 2,
        ));
      }

    } catch (e) {
      print('❌ Error generating enhanced weather tips: $e');
    }

    return tips;
  }

  // Utility methods
  bool _isExtremeWeather(WeatherModel weather) {
    return weather.temperature < 5 ||
           weather.temperature > 35 ||
           weather.humidity > 85 ||
           weather.windSpeed > 15;
  }

  String _getTimeOfDayVietnamese(int hour) {
    if (hour >= 6 && hour < 12) return 'buổi sáng';
    if (hour >= 12 && hour < 18) return 'buổi chiều';
    if (hour >= 18 && hour < 22) return 'buổi tối';
    return 'đêm khuya';
  }

  String _getFallbackMessage(int hour) {
    if (hour >= 6 && hour < 12) {
      return 'Chào buổi sáng! Hãy bắt đầu ngày mới với tinh thần tích cực.';
    } else if (hour >= 12 && hour < 18) {
      return 'Buổi chiều tốt lành! Đừng quên uống nước và nghỉ ngơi.';
    } else if (hour >= 18 && hour < 23) {
      return 'Buổi tối dễ chịu! Thời gian để thư giãn và gặp gỡ người thân.';
    } else {
      return 'Đã khuya rồi! Hãy chuẩn bị nghỉ ngơi cho một giấc ngủ ngon.';
    }
  }

  TipModel _generateFallbackTip(int hour, WeatherModel? weather) {
    return TipModel(
      title: '💡 Tips cơ bản',
      content: _getFallbackMessage(hour),
      type: TipType.daily,
      context: _buildEnhancedContext(hour, weather, TipType.daily),
      createdAt: DateTime.now(),
      priority: 1,
    );
  }

  // Existing methods (backward compatibility)
  TipModel getRandomDailyTip([List<String>? recentTitles]) {
    final tips = _smartTipService.getSmartTips(
      hour: DateTime.now().hour,
      specificCategory: 'health_wellness',
    );

    final selectedTip = tips.isNotEmpty ? tips.first : 'Hãy có một ngày tốt lành!';

    return TipModel(
      title: '💡 Tips hằng ngày',
      content: selectedTip,
      type: TipType.daily,
      context: {
        'source': 'smart_tip_service',
        'time': DateTime.now().hour,
      },
      createdAt: DateTime.now(),
      priority: 1,
    );
  }

  List<TipModel> generateWeatherTips(WeatherModel weather) {
    final tips = <TipModel>[];

    try {
      final weatherCondition = _mapWeatherCondition(weather.condition);
      final smartTips = _smartTipService.getSmartTips(
        hour: DateTime.now().hour,
        weatherCondition: weatherCondition,
        temperature: weather.temperature.toDouble(),
        humidity: weather.humidity.toDouble(),
      );

      for (int i = 0; i < smartTips.length && i < 2; i++) {
        tips.add(TipModel(
          title: '🌤️ Tips thời tiết',
          content: smartTips[i],
          type: TipType.contextWeather,
          context: {
            'temperature': weather.temperature,
            'humidity': weather.humidity,
            'condition': weather.condition,
            'location': weather.location,
            'source': 'smart_tip_service',
          },
          createdAt: DateTime.now(),
          priority: 2,
        ));
      }
    } catch (e) {
      print('Error generating weather tips: $e');
      tips.add(TipModel(
        title: '🌤️ Thời tiết hôm nay',
        content: 'Thời tiết ${weather.condition}, ${weather.temperature.round()}°C. Hãy chăm sóc sức khỏe nhé!',
        type: TipType.contextWeather,
        context: {
          'temperature': weather.temperature,
          'humidity': weather.humidity,
          'condition': weather.condition,
          'location': weather.location,
          'source': 'fallback',
        },
        createdAt: DateTime.now(),
        priority: 2,
      ));
    }

    return tips;
  }

  TipModel? generateTimeTip() {
    try {
      final smartTips = _smartTipService.getSmartTips(
        hour: DateTime.now().hour,
      );

      if (smartTips.isNotEmpty) {
        return TipModel(
          title: '⏰ Tips theo thời gian',
          content: smartTips.first,
          type: TipType.contextTime,
          context: {
            'hour': DateTime.now().hour,
            'timeOfDay': _getTimeOfDay(DateTime.now().hour),
            'source': 'smart_tip_service',
          },
          createdAt: DateTime.now(),
          priority: 2,
        );
      }
    } catch (e) {
      print('Error generating time tip: $e');
    }

    return null;
  }

  TipModel generateMoodTip(String moodGuess) {
    return TipModel(
      title: '🎭 Weekly Insight',
      content: moodGuess,
      type: TipType.moodGuess,
      context: {
        'generatedAt': DateTime.now().toIso8601String(),
      },
      createdAt: DateTime.now(),
      priority: 1,
    );
  }

  TipModel generateWeeklyRecapTip(Map<String, dynamic> recap, List<String> challenges) {
    final screenTime = recap['totalScreenTimeHours'] ?? 'N/A';
    final unlocks = recap['totalUnlocks'] ?? 'N/A';
    final moodGuess = recap['moodGuess'] ?? '';

    final randomChallenge = challenges.isNotEmpty
        ? challenges[_random.nextInt(challenges.length)]
        : 'Thử dành thời gian cho bản thân nhiều hơn tuần tới! 🌟';

    final content = '''
📊 Tổng kết tuần:
• Thời gian màn hình: ${screenTime}h
• Số lần mở máy: $unlocks lần

$moodGuess

💡 Thử thách tuần tới:
$randomChallenge
''';

    return TipModel(
      title: '📈 Weekly Recap',
      content: content,
      type: TipType.weekly,
      context: recap,
      createdAt: DateTime.now(),
      priority: 3,
    );
  }

  String _mapWeatherCondition(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('rain') || lowerCondition.contains('mưa')) {
      return 'rainy';
    } else if (lowerCondition.contains('sun') || lowerCondition.contains('clear')) {
      return 'sunny';
    } else if (lowerCondition.contains('cloud') || lowerCondition.contains('overcast')) {
      return 'cloudy';
    } else {
      return 'clear';
    }
  }

  String _getTimeOfDay(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  bool shouldShowTipsToday(List<TipModel> recentTips) {
    final today = DateTime.now();
    final todayTips = recentTips.where((tip) {
      final tipDate = tip.displayedAt ?? tip.createdAt;
      return tipDate.year == today.year &&
             tipDate.month == today.month &&
             tipDate.day == today.day;
    }).toList();

    return todayTips.length < 3; // Max 3 tips per day
  }
}
