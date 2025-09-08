import '../../models/device_usage_model.dart';

class DeviceUsageService {
  static final DeviceUsageService instance = DeviceUsageService._init();

  DeviceUsageService._init();

  Future<DeviceUsageModel?> getTodayUsage() async {
    try {
      final today = DateTime.now();
      final isWeekend = today.weekday == DateTime.saturday || today.weekday == DateTime.sunday;
      
      // Simulate device usage data (in real app, you would use platform channels)
      final mockData = _generateMockUsageData(today, isWeekend);
      
      return mockData;
    } catch (e) {
      print('Error getting device usage: $e');
      return null;
    }
  }

  Future<List<DeviceUsageModel>> getWeeklyUsage() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));
    
    final weeklyData = <DeviceUsageModel>[];
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final usage = _generateMockUsageData(date, isWeekend);
      weeklyData.add(usage);
    }
    
    return weeklyData;
  }

  DeviceUsageModel _generateMockUsageData(DateTime date, bool isWeekend) {
    // This is mock data - in a real app, you would get actual usage stats
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    return DeviceUsageModel(
      date: date,
      unlockCount: isWeekend ? 45 + random % 30 : 60 + random % 40,
      screenTimeMinutes: isWeekend ? 180 + random % 120 : 240 + random % 180,
      appUsageMinutes: {
        'Social Media': isWeekend ? 60 + random % 30 : 45 + random % 25,
        'Entertainment': isWeekend ? 90 + random % 60 : 60 + random % 30,
        'Productivity': isWeekend ? 20 + random % 15 : 80 + random % 40,
        'Games': isWeekend ? 40 + random % 30 : 20 + random % 15,
        'Others': 30 + random % 20,
      },
      peakUsageTime: _calculatePeakUsageTime(date),
      isWeekend: isWeekend,
      createdAt: DateTime.now(),
    );
  }

  String _calculatePeakUsageTime(DateTime date) {
    final hour = date.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  // Generate mood guess based on usage patterns
  String generateMoodGuess(List<DeviceUsageModel> weeklyData) {
    if (weeklyData.isEmpty) return '';

    final avgScreenTime = weeklyData
        .map((e) => e.screenTimeMinutes)
        .reduce((a, b) => a + b) / weeklyData.length;
    
    final avgUnlocks = weeklyData
        .map((e) => e.unlockCount)
        .reduce((a, b) => a + b) / weeklyData.length;

    final nightUsageCount = weeklyData
        .where((e) => e.peakUsageTime == 'night')
        .length;

    final socialMediaTime = weeklyData
        .map((e) => e.appUsageMinutes['Social Media'] ?? 0)
        .reduce((a, b) => a + b) / weeklyData.length;

    // Generate insights based on patterns
    final insights = <String>[];

    if (avgScreenTime > 300) {
      insights.add('Tuần này bạn dành khá nhiều thời gian trên thiết bị 📱');
    }

    if (avgUnlocks > 80) {
      insights.add('Có vẻ bạn hay kiểm tra điện thoại thường xuyên 🔄');
    }

    if (nightUsageCount >= 4) {
      insights.add('Có vẻ tuần này bạn hơi "cú đêm" 🦉');
    }

    if (socialMediaTime > 60) {
      insights.add('Bạn dành khá nhiều thời gian cho mạng xã hội 📲');
    }

    return insights.isNotEmpty ? insights.first : 'Tuần này bạn có vẻ cân bằng khá tốt! 😊';
  }

  // Generate weekly recap
  Map<String, dynamic> generateWeeklyRecap(List<DeviceUsageModel> weeklyData) {
    if (weeklyData.isEmpty) return {};

    final totalScreenTime = weeklyData
        .map((e) => e.screenTimeMinutes)
        .reduce((a, b) => a + b);
    
    final totalUnlocks = weeklyData
        .map((e) => e.unlockCount)
        .reduce((a, b) => a + b);

    final avgScreenTime = totalScreenTime / weeklyData.length;
    final avgUnlocks = totalUnlocks / weeklyData.length;

    final mostUsedApps = <String, int>{};
    for (final day in weeklyData) {
      day.appUsageMinutes.forEach((app, time) {
        mostUsedApps[app] = (mostUsedApps[app] ?? 0) + time;
      });
    }

    final sortedApps = mostUsedApps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalScreenTimeHours': (totalScreenTime / 60).toStringAsFixed(1),
      'totalUnlocks': totalUnlocks,
      'avgScreenTimeHours': (avgScreenTime / 60).toStringAsFixed(1),
      'avgUnlocks': avgUnlocks.round(),
      'mostUsedApp': sortedApps.isNotEmpty ? sortedApps.first.key : 'N/A',
      'mostUsedAppTime': sortedApps.isNotEmpty ? 
          (sortedApps.first.value / 60).toStringAsFixed(1) : '0',
      'moodGuess': generateMoodGuess(weeklyData),
    };
  }

  // Generate micro challenges
  List<String> generateMicroChallenges(Map<String, dynamic> weeklyRecap) {
    final challenges = <String>[];

    final avgScreenTime = double.tryParse(weeklyRecap['avgScreenTimeHours'] ?? '0') ?? 0;
    final avgUnlocks = weeklyRecap['avgUnlocks'] ?? 0;

    if (avgScreenTime > 5) {
      challenges.add('Thử giảm 30 phút thời gian màn hình mỗi ngày tuần tới 📱');
    }

    if (avgUnlocks > 80) {
      challenges.add('Thử tắt thông báo không cần thiết để giảm số lần mở máy 🔕');
    }

    challenges.add('Thử đặt điện thoại xa giường 30 phút trước khi ngủ 🛏️');
    challenges.add('Dành 15 phút mỗi ngày để đọc sách thay vì lướt mạng xã hội 📚');
    challenges.add('Thử "digital detox" 1 giờ mỗi ngày cuối tuần 🌿');

    return challenges;
  }
}
