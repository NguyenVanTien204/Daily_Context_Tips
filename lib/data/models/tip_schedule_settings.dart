import 'package:shared_preferences/shared_preferences.dart';

class TipScheduleSettings {
  static const String _enableAutoGenKey = 'enable_auto_gen';
  static const String _dailyTipTimesKey = 'daily_tip_times';
  static const String _weeklyRecapDayKey = 'weekly_recap_day';
  static const String _contextTipFrequencyKey = 'context_tip_frequency';
  static const String _weatherTipEnabledKey = 'weather_tip_enabled';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _smartTipEnabledKey = 'smart_tip_enabled';
  static const String _maxTipsPerDayKey = 'max_tips_per_day';

  final bool enableAutoGen;
  final List<int> dailyTipTimes; // Hours (0-23)
  final int weeklyRecapDay; // 1-7 (Monday-Sunday)
  final int contextTipFrequencyHours; // Hours between context tips
  final bool weatherTipEnabled;
  final bool notificationEnabled;
  final bool smartTipEnabled;
  final int maxTipsPerDay;

  TipScheduleSettings({
    this.enableAutoGen = true,
    this.dailyTipTimes = const [9, 14, 19], // 9 AM, 2 PM, 7 PM
    this.weeklyRecapDay = 7, // Sunday
    this.contextTipFrequencyHours = 4,
    this.weatherTipEnabled = true,
    this.notificationEnabled = true,
    this.smartTipEnabled = true,
    this.maxTipsPerDay = 5,
  });

  static Future<TipScheduleSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return TipScheduleSettings(
      enableAutoGen: prefs.getBool(_enableAutoGenKey) ?? true,
      dailyTipTimes: prefs.getStringList(_dailyTipTimesKey)?.map(int.parse).toList() ?? [9, 14, 19],
      weeklyRecapDay: prefs.getInt(_weeklyRecapDayKey) ?? 7,
      contextTipFrequencyHours: prefs.getInt(_contextTipFrequencyKey) ?? 4,
      weatherTipEnabled: prefs.getBool(_weatherTipEnabledKey) ?? true,
      notificationEnabled: prefs.getBool(_notificationEnabledKey) ?? true,
      smartTipEnabled: prefs.getBool(_smartTipEnabledKey) ?? true,
      maxTipsPerDay: prefs.getInt(_maxTipsPerDayKey) ?? 5,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enableAutoGenKey, enableAutoGen);
    await prefs.setStringList(_dailyTipTimesKey, dailyTipTimes.map((e) => e.toString()).toList());
    await prefs.setInt(_weeklyRecapDayKey, weeklyRecapDay);
    await prefs.setInt(_contextTipFrequencyKey, contextTipFrequencyHours);
    await prefs.setBool(_weatherTipEnabledKey, weatherTipEnabled);
    await prefs.setBool(_notificationEnabledKey, notificationEnabled);
    await prefs.setBool(_smartTipEnabledKey, smartTipEnabled);
    await prefs.setInt(_maxTipsPerDayKey, maxTipsPerDay);
  }

  TipScheduleSettings copyWith({
    bool? enableAutoGen,
    List<int>? dailyTipTimes,
    int? weeklyRecapDay,
    int? contextTipFrequencyHours,
    bool? weatherTipEnabled,
    bool? notificationEnabled,
    bool? smartTipEnabled,
    int? maxTipsPerDay,
  }) {
    return TipScheduleSettings(
      enableAutoGen: enableAutoGen ?? this.enableAutoGen,
      dailyTipTimes: dailyTipTimes ?? this.dailyTipTimes,
      weeklyRecapDay: weeklyRecapDay ?? this.weeklyRecapDay,
      contextTipFrequencyHours: contextTipFrequencyHours ?? this.contextTipFrequencyHours,
      weatherTipEnabled: weatherTipEnabled ?? this.weatherTipEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      smartTipEnabled: smartTipEnabled ?? this.smartTipEnabled,
      maxTipsPerDay: maxTipsPerDay ?? this.maxTipsPerDay,
    );
  }

  bool shouldGenerateAtHour(int hour) {
    return enableAutoGen && dailyTipTimes.contains(hour);
  }

  bool shouldGenerateContextTip(DateTime lastContextTip) {
    final hoursSinceLastTip = DateTime.now().difference(lastContextTip).inHours;
    return enableAutoGen &&
           weatherTipEnabled &&
           hoursSinceLastTip >= contextTipFrequencyHours;
  }

  bool shouldGenerateSmartTip() {
    return enableAutoGen && smartTipEnabled;
  }

  bool shouldSendNotification() {
    return notificationEnabled;
  }
}
