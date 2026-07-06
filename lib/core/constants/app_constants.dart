class AppConstants {
  static const String appName = 'Twicely';
  
  // API Configurations
  static const String apiBaseUrl = 'https://api.twicely.com/v1'; // Replace with actual backend API Base URL
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Local Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserEmail = 'user_email';
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyThemeMode = 'theme_mode';

  // Subscriptions & Products (For App Store & Google Play Billing setup)
  static const String monthlySubscriptionId = 'com.twicely.premium.monthly';
  static const String yearlySubscriptionId = 'com.twicely.premium.yearly';
}
