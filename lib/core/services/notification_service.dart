import 'dart:developer';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Cloud Messaging settings
  Future<void> initialize() async {
    try {
      // 1. Request notifications permissions
      await requestPermissions();

      // 2. Fetch FCM Token (Mocked here, to be wired with Firebase messaging package)
      _fcmToken = "mock_fcm_token_twicely_${DateTime.now().millisecondsSinceEpoch}";
      log("FCM Token initialized: $_fcmToken");

      // 3. Register background & foreground messaging listeners
      _setupNotificationListeners();
    } catch (e) {
      log("Failed to initialize notification service: $e");
    }
  }

  /// Request permissions on Android / iOS
  Future<bool> requestPermissions() async {
    // In production, invoke: FirebaseMessaging.instance.requestPermission()
    log("Requested notification permission from user.");
    return true;
  }

  /// Register listeners for incoming notification messages
  void _setupNotificationListeners() {
    log("Registered notification message stream listeners.");
    // In production:
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) { ... });
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) { ... });
  }

  /// Send device FCM token to backend database to target this device
  Future<bool> registerTokenWithBackend() async {
    if (_fcmToken == null) return false;
    log("Sending token $_fcmToken to Twicely Backend server...");
    // Perform API post to: /users/register-fcm
    return true;
  }
}
