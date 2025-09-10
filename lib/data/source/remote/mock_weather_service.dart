import 'dart:math';
import '../../models/weather_model.dart';

/// Mock Weather Service để test khi API không khả dụng
class MockWeatherService {
  static final MockWeatherService instance = MockWeatherService._init();
  final Random _random = Random();

  MockWeatherService._init();

  /// Tạo dữ liệu thời tiết giả cho test
  WeatherModel generateMockWeather() {
    final conditions = ['Clear', 'Clouds', 'Rain', 'Snow', 'Thunderstorm'];
    final locations = ['Hà Nội', 'TP.HCM', 'Đà Nẵng', 'Cần Thơ', 'Hải Phòng'];

    final temperature = 15 + _random.nextDouble() * 25; // 15-40°C
    final condition = conditions[_random.nextInt(conditions.length)];
    final location = locations[_random.nextInt(locations.length)];

    return WeatherModel(
      temperature: temperature,
      humidity: 40 + _random.nextDouble() * 50, // 40-90%
      condition: condition,
      description: _getDescription(condition),
      uvIndex: _random.nextDouble() * 11, // 0-11
      windSpeed: _random.nextDouble() * 20, // 0-20 m/s
      location: location,
      timestamp: DateTime.now(),
    );
  }

  /// Tạo thời tiết dựa trên thời gian (realistic hơn)
  WeatherModel generateTimeBasedWeather() {
    final now = DateTime.now();
    final hour = now.hour;
    final month = now.month;

    // Nhiệt độ dựa vào giờ và tháng
    double baseTemp = _getSeasonalTemp(month);
    double timeModifier = _getHourlyTempModifier(hour);
    double temperature = baseTemp + timeModifier + (_random.nextDouble() - 0.5) * 4;

    // Điều kiện thời tiết dựa vào mùa
    String condition = _getSeasonalCondition(month, temperature);

    return WeatherModel(
      temperature: temperature,
      humidity: _getRealisticHumidity(condition),
      condition: condition,
      description: _getDescription(condition),
      uvIndex: _getUVIndex(hour, condition),
      windSpeed: 2 + _random.nextDouble() * 8,
      location: 'Hà Nội',
      timestamp: DateTime.now(),
    );
  }

  double _getSeasonalTemp(int month) {
    // Nhiệt độ trung bình theo tháng tại Việt Nam
    final monthlyAvg = {
      1: 17.0, 2: 18.0, 3: 22.0, 4: 26.0, 5: 29.0, 6: 30.0,
      7: 30.0, 8: 29.0, 9: 28.0, 10: 25.0, 11: 21.0, 12: 18.0,
    };
    return monthlyAvg[month] ?? 25.0;
  }

  double _getHourlyTempModifier(int hour) {
    // Biến động nhiệt độ theo giờ
    if (hour >= 6 && hour <= 8) return -3.0; // Sáng sớm mát
    if (hour >= 12 && hour <= 15) return 5.0; // Trưa nóng
    if (hour >= 18 && hour <= 20) return 2.0; // Chiều ấm
    if (hour >= 22 || hour <= 5) return -5.0; // Đêm lạnh
    return 0.0;
  }

  String _getSeasonalCondition(int month, double temperature) {
    // Mùa mưa (5-10)
    if (month >= 5 && month <= 10) {
      if (_random.nextDouble() < 0.4) return 'Rain';
      if (_random.nextDouble() < 0.3) return 'Clouds';
      return 'Clear';
    }

    // Mùa khô (11-4)
    if (temperature > 30 && _random.nextDouble() < 0.7) return 'Clear';
    if (_random.nextDouble() < 0.3) return 'Clouds';
    return 'Clear';
  }

  double _getRealisticHumidity(String condition) {
    switch (condition) {
      case 'Rain':
      case 'Thunderstorm':
        return 80 + _random.nextDouble() * 15; // 80-95%
      case 'Clouds':
        return 60 + _random.nextDouble() * 25; // 60-85%
      case 'Clear':
        return 40 + _random.nextDouble() * 30; // 40-70%
      default:
        return 50 + _random.nextDouble() * 30;
    }
  }

  double _getUVIndex(int hour, String condition) {
    if (hour < 6 || hour > 18) return 0.0; // Không có UV ban đêm

    double baseUV = 0.0;
    if (hour >= 10 && hour <= 14) {
      baseUV = 8 + _random.nextDouble() * 3; // UV cao lúc trưa
    } else if (hour >= 8 && hour <= 16) {
      baseUV = 4 + _random.nextDouble() * 4; // UV trung bình
    } else {
      baseUV = 1 + _random.nextDouble() * 2; // UV thấp
    }

    // Giảm UV khi có mây/mưa
    if (condition == 'Clouds') baseUV *= 0.7;
    if (condition == 'Rain' || condition == 'Thunderstorm') baseUV *= 0.3;

    return baseUV;
  }

  String _getDescription(String condition) {
    final descriptions = {
      'Clear': 'Trời quang đãng',
      'Clouds': 'Nhiều mây',
      'Rain': 'Mưa rào',
      'Snow': 'Tuyết rơi',
      'Thunderstorm': 'Dông bão',
      'Drizzle': 'Mưa phùn',
      'Mist': 'Sương mù',
    };
    return descriptions[condition] ?? 'Thời tiết bình thường';
  }

  /// Tạo thời tiết cực đoan để test weather tips
  WeatherModel generateExtremeWeather() {
    final extremeConditions = [
      {'condition': 'Thunderstorm', 'temp': 28.0, 'humidity': 95.0},
      {'condition': 'Clear', 'temp': 38.0, 'humidity': 30.0}, // Nóng cực đoan
      {'condition': 'Rain', 'temp': 15.0, 'humidity': 90.0}, // Lạnh và ướt
      {'condition': 'Clear', 'temp': 8.0, 'humidity': 50.0}, // Lạnh cực đoan
    ];

    final extreme = extremeConditions[_random.nextInt(extremeConditions.length)];

    return WeatherModel(
      temperature: extreme['temp'] as double,
      humidity: extreme['humidity'] as double,
      condition: extreme['condition'] as String,
      description: _getDescription(extreme['condition'] as String),
      uvIndex: extreme['condition'] == 'Clear' ? 11.0 : 2.0,
      windSpeed: 15 + _random.nextDouble() * 10, // Gió mạnh
      location: 'Test Location',
      timestamp: DateTime.now(),
    );
  }
}
