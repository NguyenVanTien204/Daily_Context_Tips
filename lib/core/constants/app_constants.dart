class AppConstants {
  static const String appName = 'Daily Context Tips';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'daily_context_tips.db';
  static const int databaseVersion = 1;

  // Notification IDs
  static const int dailyTipNotificationId = 1001;
  static const int weeklyRecapNotificationId = 1002;
  static const int contextTipNotificationId = 1003;
  static const int weatherAlertNotificationId = 1004;

  // Weather API
  static const String weatherApiKey = 'becbf5a8cae84672bc670824252008'; // Replace with actual API key
  static const String weatherApiBaseUrl = 'http://api.weatherapi.com/v1/';

  // Shared Preferences Keys
  static const String lastDailyTipDateKey = 'last_daily_tip_date';
  static const String lastWeeklyRecapDateKey = 'last_weekly_recap_date';
  static const String userOnboardingCompleteKey = 'user_onboarding_complete';
  static const String appUsagePermissionGrantedKey = 'app_usage_permission_granted';

  // Time Constants
  static const int dailyTipHour = 8; // 8:00 AM
  static const int weeklyRecapHour = 20; // 8:00 PM on Sunday
  static const int weeklyRecapDay = 7; // Sunday

  // Tip Cooldown (in days)
  static const int tipCooldownDays = 7;

  // Maximum tips per day
  static const int maxTipsPerDay = 2;
}
