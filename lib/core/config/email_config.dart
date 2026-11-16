// lib/core/config/email_config.dart
/// Konfigurasi Pengiriman Email OTP SawitGuard via Google SMTP Resmi.
class EmailConfig {
  /// Metode aktif: 'smtp' (Google Gmail SMTP Resmi, 100% Masuk Inbox Utama)
  static const String method = 'smtp';

  /// Alamat email pengirim resmi
  static const String senderEmail = 'mohhasan9998@gmail.com';
  static const String senderName = 'SawitGuard IoT Security';

  /// Sandi Aplikasi Google 16-digit resmi (Gunakan sandi aktif di lingkungan lokal)
  static const String senderPassword = 'GANTI_DENGAN_16_DIGIT_APP_PASSWORD';

  /// === METODE CADANGAN: BREVO REST API ===
  static const String brevoApiKey = 'GANTI_DENGAN_BREVO_API_KEY';

  /// Cek apakah metode pengiriman sudah siap
  static bool get isConfigured {
    if (method == 'smtp') {
      return senderPassword.trim().isNotEmpty &&
          senderPassword != 'GANTI_DENGAN_16_DIGIT_APP_PASSWORD';
    }
    return brevoApiKey.trim().isNotEmpty &&
        brevoApiKey != 'GANTI_DENGAN_BREVO_API_KEY';
  }
}
