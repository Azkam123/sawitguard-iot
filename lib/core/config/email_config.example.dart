// lib/core/config/email_config.example.dart
/// TEMPLATE KONFIGURASI RESMI - SAWITGUARD IOT
/// File ini adalah contoh konfigurasi untuk repository publik.
/// Untuk lingkungan lokal, buat salinan file ini menjadi `email_config.dart`
/// dan masukkan kredensial SMTP Gmail resmi Anda.

class EmailConfig {
  /// Metode aktif: 'smtp' (Google Gmail SMTP Resmi)
  static const String method = 'smtp';

  /// Alamat email pengirim resmi sistem SawitGuard
  static const String senderEmail = 'your_account@gmail.com';
  static const String senderName = 'SawitGuard IoT Security';

  /// Sandi Aplikasi Google 16-digit resmi
  /// Didapatkan dari: Akun Google -> Keamanan -> Sandi Aplikasi (App Passwords)
  static const String senderPassword = 'GANTI_DENGAN_16_DIGIT_APP_PASSWORD';

  /// Metode cadangan: Brevo REST API (Opsional)
  static const String brevoApiKey = 'GANTI_DENGAN_BREVO_API_KEY';

  /// Cek apakah metode pengiriman sudah terkonfigurasi dengan benar
  static bool get isConfigured {
    if (method == 'smtp') {
      return senderPassword.trim().isNotEmpty &&
          senderPassword != 'GANTI_DENGAN_16_DIGIT_APP_PASSWORD';
    }
    return brevoApiKey.trim().isNotEmpty &&
        brevoApiKey != 'GANTI_DENGAN_BREVO_API_KEY';
  }
}
