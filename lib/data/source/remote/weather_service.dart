import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/weather_model.dart';
import '../../../core/constants/app_constants.dart';

class WeatherService {
  static final WeatherService instance = WeatherService._init();
  final Dio _dio = Dio();

  WeatherService._init();

  Future<WeatherModel?> getCurrentWeather() async {
    try {
      // Get current location
      final position = await _getCurrentPosition();
      if (position == null) {
        // Fallback to default location if GPS not available
        print('Location not available, using default location: Hanoi');
        return await getWeatherByCity('Hanoi');
      }

      // Get city name from coordinates using reverse geocoding
      String cityName = await _getCityNameFromCoordinates(position);
      print('🌍 GPS Location: ${position.latitude}, ${position.longitude}');
      print('🏙️ Detected city: $cityName');

      // Fetch weather data from WeatherAPI using coordinates for accuracy
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}current.json',
        queryParameters: {
          'key': AppConstants.weatherApiKey,
          'q': '${position.latitude},${position.longitude}',
          'aqi': 'no',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final current = data['current'];
        final location = data['location'];

        return WeatherModel(
          temperature: current['temp_c'].toDouble(),
          humidity: current['humidity'].toDouble(),
          condition: current['condition']['text'],
          description: current['condition']['text'],
          uvIndex: current['uv'].toDouble(),
          windSpeed: current['wind_kph'].toDouble() / 3.6, // Convert km/h to m/s
          location: '$cityName, ${location['region']}', // Use detected city name + region
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error fetching weather: $e');
      // Fallback to default location on error
      return await getWeatherByCity('Hanoi');
    }
    return null;
  }

  Future<WeatherModel?> getWeatherByCity(String cityName) async {
    try {
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}current.json',
        queryParameters: {
          'key': AppConstants.weatherApiKey,
          'q': cityName,
          'aqi': 'no',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final current = data['current'];
        final location = data['location'];

        return WeatherModel(
          temperature: current['temp_c'].toDouble(),
          humidity: current['humidity'].toDouble(),
          condition: current['condition']['text'],
          description: current['condition']['text'],
          uvIndex: current['uv'].toDouble(),
          windSpeed: current['wind_kph'].toDouble() / 3.6, // Convert km/h to m/s
          location: location['name'],
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error fetching weather for city $cityName: $e');
    }
    return null;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Get position with proper settings
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<String> _getCityNameFromCoordinates(Position position) async {
    try {
      print('🔍 Reverse geocoding: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Try different field combinations to get the best city name
        String cityName = place.locality ??
                         place.subAdministrativeArea ??
                         place.administrativeArea ??
                         'Unknown Location';

        print('📍 Geocoding result:');
        print('  - Locality: ${place.locality}');
        print('  - SubAdmin: ${place.subAdministrativeArea}');
        print('  - Admin: ${place.administrativeArea}');
        print('  - Country: ${place.country}');
        print('  - Selected: $cityName');

        return cityName;
      } else {
        print('⚠️ No placemarks found for coordinates');
        return 'Unknown Location';
      }
    } catch (e) {
      print('❌ Error in reverse geocoding: $e');
      return 'Unknown Location';
    }
  }

  // Generate context-aware tips based on weather
  List<String> generateWeatherTips(WeatherModel weather) {
    final tips = <String>[];

    // Temperature-based tips
    if (weather.temperature > 30) {
      tips.add('Trời nóng ${weather.temperature.round()}°C! Nhớ uống nhiều nước và tránh ra ngoài lúc trưa.');
      tips.add('UV cao, nhớ bôi kem chống nắng nếu ra ngoài.');
    } else if (weather.temperature < 15) {
      tips.add('Trời lạnh ${weather.temperature.round()}°C! Mặc ấm khi ra ngoài.');
      tips.add('Thời tiết se lạnh, uống nước ấm để giữ sức khỏe.');
    }

    // Humidity-based tips
    if (weather.humidity > 80) {
      tips.add('Độ ẩm cao ${weather.humidity.round()}%! Dễ bị khó chịu, hãy ở nơi thoáng mát.');
      tips.add('Độ ẩm cao, nhớ giữ da khô ráo và thoáng khí.');
    } else if (weather.humidity < 40) {
      tips.add('Không khí khô ${weather.humidity.round()}%! Uống nhiều nước và dưỡng ẩm da.');
    }

    // Condition-based tips
    switch (weather.condition.toLowerCase()) {
      case 'rain':
        tips.add('Trời mưa! Hoàn hảo để ở nhà đọc sách hoặc nghe nhạc thư giãn.');
        tips.add('Mưa rồi, nhớ mang theo ô khi ra ngoài.');
        break;
      case 'clouds':
        tips.add('Trời âm u, ánh sáng yếu. Hãy bật đèn hoặc ra ngoài hít thở không khí trong lành.');
        break;
      case 'clear':
        tips.add('Trời quang đãng! Thời điểm tuyệt vời để đi dạo hoặc tập thể dục ngoài trời.');
        break;
      case 'snow':
        tips.add('Tuyết rơi! Cẩn thận khi di chuyển và giữ ấm cơ thể.');
        break;
    }

    // Wind-based tips
    if (weather.windSpeed > 20) {
      tips.add('Gió mạnh ${weather.windSpeed.round()} km/h! Cẩn thận khi ra đường.');
    }

    return tips;
  }
}
