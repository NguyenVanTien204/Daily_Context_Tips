import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/device_usage_model.dart';
import '../data/source/local/device_usage_service.dart';
import '../data/source/local/database_helper.dart';

// Device Usage State
class DeviceUsageState {
  final DeviceUsageModel? todayUsage;
  final List<DeviceUsageModel> weeklyUsage;
  final bool isLoading;
  final String? error;

  const DeviceUsageState({
    this.todayUsage,
    this.weeklyUsage = const [],
    this.isLoading = false,
    this.error,
  });

  DeviceUsageState copyWith({
    DeviceUsageModel? todayUsage,
    List<DeviceUsageModel>? weeklyUsage,
    bool? isLoading,
    String? error,
  }) {
    return DeviceUsageState(
      todayUsage: todayUsage ?? this.todayUsage,
      weeklyUsage: weeklyUsage ?? this.weeklyUsage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Device Usage Provider
class DeviceUsageNotifier extends StateNotifier<DeviceUsageState> {
  DeviceUsageNotifier() : super(const DeviceUsageState());

  final DeviceUsageService _usageService = DeviceUsageService.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> loadTodayUsage() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get today's usage data
      final usage = await _usageService.getTodayUsage();
      
      if (usage != null) {
        // Try to save to database (will update if already exists)
        try {
          await _db.insertDeviceUsage(usage);
        } catch (e) {
          // Ignore if already exists for today
          print('Usage data may already exist for today: $e');
        }
        
        state = state.copyWith(todayUsage: usage, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Không thể lấy dữ liệu sử dụng thiết bị',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi tải dữ liệu sử dụng: ${e.toString()}',
      );
    }
  }

  Future<void> loadWeeklyUsage() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get weekly usage data
      final weeklyUsage = await _usageService.getWeeklyUsage();
      
      // Save each day's data to database
      for (final usage in weeklyUsage) {
        try {
          await _db.insertDeviceUsage(usage);
        } catch (e) {
          // Ignore if already exists
          print('Usage data may already exist: $e');
        }
      }
      
      state = state.copyWith(weeklyUsage: weeklyUsage, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi tải dữ liệu tuần: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getWeeklyRecap() async {
    try {
      final weeklyUsage = await _usageService.getWeeklyUsage();
      return _usageService.generateWeeklyRecap(weeklyUsage);
    } catch (e) {
      return {};
    }
  }

  Future<List<String>> getMicroChallenges() async {
    try {
      final weeklyUsage = await _usageService.getWeeklyUsage();
      final recap = _usageService.generateWeeklyRecap(weeklyUsage);
      return _usageService.generateMicroChallenges(recap);
    } catch (e) {
      return [];
    }
  }

  String getMoodGuess() {
    if (state.weeklyUsage.isNotEmpty) {
      return _usageService.generateMoodGuess(state.weeklyUsage);
    }
    return 'Cần thêm dữ liệu để phân tích tâm trạng';
  }
}

final deviceUsageProvider = StateNotifierProvider<DeviceUsageNotifier, DeviceUsageState>((ref) {
  return DeviceUsageNotifier();
});
