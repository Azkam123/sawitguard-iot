// lib/data/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

/// Top-level background handler (must be top-level, not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart isolate
  // Show a local notification to wake device
  await FcmService._showLocalNotification(message);
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Initialize local notifications channel & FCM listeners
  Future<void> initialize({
    required void Function(RemoteMessage) onForegroundMessage,
    required void Function(RemoteMessage?) onMessageOpenedApp,
  }) async {
    // Request permission (Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Configure Android notification channel (Emergency, max importance)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.fcmChannelId,
      AppConstants.fcmChannelName,
      description: AppConstants.fcmChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Init local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (details) {
        // Navigate to AlertScreen on tap
      },
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(onForegroundMessage);

    // Tapped from background
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    // App opened from terminated state
    final initial = await _fcm.getInitialMessage();
    onMessageOpenedApp(initial);

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Get device FCM token
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  /// Listen for token refresh and call callback
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  /// Show a local notification (used both from foreground and background)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      message.hashCode,
      notification.title ?? '⚠️ PERINGATAN SAWITGUARD',
      notification.body ?? 'Terdeteksi intrusi pada perkebunan!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.fcmChannelId,
          AppConstants.fcmChannelName,
          channelDescription: AppConstants.fcmChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          ongoing: false,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Call this from foreground handler to also show a local notification banner
  Future<void> showForegroundBanner(RemoteMessage message) async {
    await _showLocalNotification(message);
  }
}
