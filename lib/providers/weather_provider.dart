import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/weather_model.dart';
import '../data/source/remote/weather_service.dart';
import '../data/source/local/database_helper.dart';

// Weather State
class WeatherState {
  final WeatherModel? weather;
  final bool isLoading;
  final String? error;

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    WeatherModel? weather,
    bool? isLoading,
    String? error,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Weather Provider
class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());

  final WeatherService _weatherService = WeatherService.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> loadCurrentWeather() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Try to get cached weather data first
      final cachedWeather = await _db.getLatestWeatherData();
      
      // Check if cached data is still fresh (less than 1 hour old)
      if (cachedWeather != null && 
          DateTime.now().difference(cachedWeather.timestamp).inHours < 1) {
        state = state.copyWith(weather: cachedWeather, isLoading: false);
        return;
      }
      
      // Fetch fresh weather data
      final weather = await _weatherService.getCurrentWeather();
      
      if (weather != null) {
        // Save to database
        await _db.insertWeatherData(weather);
        state = state.copyWith(weather: weather, isLoading: false);
      } else {
        // Use cached data if available, even if old
        if (cachedWeather != null) {
          state = state.copyWith(weather: cachedWeather, isLoading: false);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Không thể lấy dữ liệu thời tiết',
          );
        }
      }
    } catch (e) {
      // Try to use cached data
      final cachedWeather = await _db.getLatestWeatherData();
      if (cachedWeather != null) {
        state = state.copyWith(weather: cachedWeather, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Lỗi khi tải dữ liệu thời tiết: ${e.toString()}',
        );
      }
    }
  }

  Future<void> refreshWeather() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final weather = await _weatherService.getCurrentWeather();
      
      if (weather != null) {
        await _db.insertWeatherData(weather);
        state = state.copyWith(weather: weather, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Không thể làm mới dữ liệu thời tiết',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi làm mới thời tiết: ${e.toString()}',
      );
    }
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
