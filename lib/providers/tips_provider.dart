import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tip_model.dart';
import '../data/source/local/database_helper.dart';
import '../data/source/local/tips_service.dart';
import '../data/source/remote/weather_service.dart';
import '../data/source/local/device_usage_service.dart';

// Tips State
class TipsState {
  final List<TipModel> allTips;
  final List<TipModel> todayTips;
  final bool isLoading;
  final String? error;

  const TipsState({
    this.allTips = const [],
    this.todayTips = const [],
    this.isLoading = false,
    this.error,
  });

  TipsState copyWith({
    List<TipModel>? allTips,
    List<TipModel>? todayTips,
    bool? isLoading,
    String? error,
  }) {
    return TipsState(
      allTips: allTips ?? this.allTips,
      todayTips: todayTips ?? this.todayTips,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Tips Provider
class TipsNotifier extends StateNotifier<TipsState> {
  TipsNotifier() : super(const TipsState());

  final DatabaseHelper _db = DatabaseHelper.instance;
  final TipsService _tipsService = TipsService.instance;
  final WeatherService _weatherService = WeatherService.instance;
  final DeviceUsageService _usageService = DeviceUsageService.instance;

  Future<void> loadTodayTips({bool forceReload = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Initialize tips service with enhanced capabilities
      await _tipsService.initialize();
      await _tipsService.initialize();

      // Load all tips from database
      final allTips = await _db.getAllTips();

      // Get today's tips
      final today = DateTime.now();
      final todayTips = allTips.where((tip) {
        final tipDate = tip.displayedAt ?? tip.createdAt;
        return tipDate.year == today.year &&
               tipDate.month == today.month &&
               tipDate.day == today.day;
      }).toList();

      // Check if we need to generate new tips (only if not force reloading)
      if (!forceReload && _shouldGenerateNewTips(todayTips)) {
        await _generateAndSaveTodayTips();
        // Reload after generating new tips
        final updatedAllTips = await _db.getAllTips();
        final updatedTodayTips = updatedAllTips.where((tip) {
          final tipDate = tip.displayedAt ?? tip.createdAt;
          return tipDate.year == today.year &&
                 tipDate.month == today.month &&
                 tipDate.day == today.day;
        }).toList();

        state = state.copyWith(
          allTips: updatedAllTips,
          todayTips: updatedTodayTips,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          allTips: allTips,
          todayTips: todayTips,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  bool _shouldGenerateNewTips(List<TipModel> todayTips) {
    // Generate new tips if:
    // 1. No tips for today
    // 2. Less than 2 tips and it's morning (before 10 AM)
    // 3. Last tip was generated more than 4 hours ago

    if (todayTips.isEmpty) return true;

    final now = DateTime.now();
    if (todayTips.length < 2 && now.hour < 10) return true;

    final lastTipTime = todayTips
        .map((t) => t.displayedAt ?? t.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    if (now.difference(lastTipTime).inHours >= 4) return true;

    return false;
  }

  Future<void> _generateAndSaveTodayTips() async {
    final newTips = <TipModel>[];

    try {
      // 1. Generate daily life tip
      final recentTips = await _db.getAllTips();
      final recentTitles = recentTips.map((t) => t.title).toList();
      final dailyTip = _tipsService.getRandomDailyTip(recentTitles);
      newTips.add(dailyTip);

      // 2. Generate weather-based tip
      final weather = await _weatherService.getCurrentWeather();
      if (weather != null) {
        final weatherTips = _tipsService.generateWeatherTips(weather);
        if (weatherTips.isNotEmpty) {
          newTips.add(weatherTips.first);
        }
      }

      // 3. Generate time-based tip
      final timeTip = _tipsService.generateTimeTip();
      if (timeTip != null && newTips.length < 2) {
        newTips.add(timeTip);
      }

      // Save tips to database
      for (final tip in newTips) {
        final tipWithDisplayTime = tip.copyWith(displayedAt: DateTime.now());
        await _db.insertTip(tipWithDisplayTime);
      }

    } catch (e) {
      print('Error generating tips: $e');
    }
  }

  Future<void> generateManualTip() async {
    try {
      // Get current weather for enhanced context
      final weather = await _weatherService.getCurrentWeather();

      // Use enhanced smart tip generation
      final tip = await _tipsService.triggerInstantSmartTip(
        weather: weather,
        sendNotification: false, // Don't send notification for manual tips
        debugContext: 'Manual tip generation from FloatingActionButton',
      );

      final tipWithDisplayTime = tip.copyWith(displayedAt: DateTime.now());
      await _db.insertTip(tipWithDisplayTime);

      // Reload tips
      await loadTodayTips(forceReload: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      print('Error generating manual tip: $e');
    }
  }

  Future<void> markTipAsRead(int tipId) async {
    try {
      final tip = state.allTips.firstWhere((t) => t.id == tipId);
      final updatedTip = tip.copyWith(isRead: true);
      await _db.updateTip(updatedTip);

      // Update state
      final updatedAllTips = state.allTips.map((t) {
        return t.id == tipId ? updatedTip : t;
      }).toList();

      final updatedTodayTips = state.todayTips.map((t) {
        return t.id == tipId ? updatedTip : t;
      }).toList();

      state = state.copyWith(
        allTips: updatedAllTips,
        todayTips: updatedTodayTips,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> generateWeeklyRecap() async {
    try {
      // Get weekly usage data
      final weeklyUsage = await _usageService.getWeeklyUsage();
      final recap = _usageService.generateWeeklyRecap(weeklyUsage);
      final challenges = _usageService.generateMicroChallenges(recap);

      // Generate weekly recap tip
      final weeklyTip = _tipsService.generateWeeklyRecapTip(recap, challenges);
      await _db.insertTip(weeklyTip.copyWith(displayedAt: DateTime.now()));

      // Generate mood guess tip
      final moodGuess = _usageService.generateMoodGuess(weeklyUsage);
      final moodTip = _tipsService.generateMoodTip(moodGuess);
      await _db.insertTip(moodTip.copyWith(displayedAt: DateTime.now()));

      // Reload tips
      await loadTodayTips(forceReload: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Add custom tip method
  Future<void> addCustomTip(TipModel tip) async {
    try {
      await _db.insertTip(tip.copyWith(displayedAt: DateTime.now()));
      await loadTodayTips(forceReload: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final tipsProvider = StateNotifierProvider<TipsNotifier, TipsState>((ref) {
  return TipsNotifier();
});
