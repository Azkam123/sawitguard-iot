// lib/core/constants/app_constants.dart
class AppConstants {
  // Firebase Paths
  static const String usersPath = 'users';
  static const String devicesPath = 'devices';
  static const String historyLogsPath = 'history_logs';

  // Device Status
  static const String statusAman = 'AMAN';
  static const String statusIntrusi = 'INTRUSI';

  // Notification
  static const String fcmChannelId = 'sawitguard_emergency_channel';
  static const String fcmChannelName = 'SawitGuard Peringatan Darurat';
  static const String fcmChannelDesc =
      'Notifikasi kritis saat terdeteksi intrusi pada perkebunan.';

  // App Info
  static const String appName = 'SawitGuard IoT';
  static const String appVersion = '1.0.0';

  // Asset Paths
  static const String sirenAudio = 'assets/audio/siren.mp3';
  static const String logoSvg = 'assets/images/logo.svg';
  static const String emptyLottie = 'assets/lottie/empty_state.json';
  static const String alertLottie = 'assets/lottie/alert_pulse.json';
  static const String safeLottie = 'assets/lottie/safe_shield.json';
}
