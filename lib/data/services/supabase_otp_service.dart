// lib/data/services/supabase_otp_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/email_config.dart';
import '../../core/config/supabase_config.dart';
import 'email_otp_service.dart';

/// Layanan Pengiriman & Verifikasi OTP SawitGuard IoT
/// Menggunakan Google Gmail SMTP Resmi (100% Masuk Kotak Masuk Utama)
/// dengan dukungan fallback Supabase Auth & Brevo Cloud.
class SupabaseOtpService {
  final EmailOtpService _otpService = EmailOtpService();

  /// Mengirim kode OTP ke email tujuan pendaftar
  Future<String?> sendOtpToEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Prioritas Utama: Google Gmail SMTP Resmi (500 email/hari, 100% Inbox Utama)
    if (EmailConfig.isConfigured && EmailConfig.method == 'smtp') {
      debugPrint('[OtpService] Mengirim OTP via Google Gmail SMTP Resmi ke: $cleanEmail');
      return await _otpService.sendOtpToEmail(cleanEmail);
    }

    // 2. Jika Supabase dikonfigurasi, gunakan Supabase Auth OTP
    if (SupabaseConfig.isConfigured) {
      try {
        debugPrint('[OtpService] Mengirim OTP via Supabase ke: $cleanEmail');
        await Supabase.instance.client.auth.signInWithOtp(
          email: cleanEmail,
          shouldCreateUser: true,
        );
        debugPrint('[OtpService] OTP Supabase berhasil diminta untuk: $cleanEmail');
        return 'SUPABASE_SENT';
      } catch (e) {
        debugPrint('[OtpService] Supabase pengiriman terkendala ($e). Mengalihkan ke EmailOtpService...');
      }
    }

    // 3. Fallback ke EmailOtpService
    return await _otpService.sendOtpToEmail(cleanEmail);
  }

  /// Memverifikasi kode OTP yang dimasukkan pengguna
  Future<bool> verifyOtp({
    required String email,
    required String enteredOtp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = enteredOtp.replaceAll(RegExp(r'\D'), '').trim();

    // 1. Verifikasi kode OTP melalui internal storage & cache lokal/RTDB
    final localVerified = await _otpService.verifyOtp(
      email: cleanEmail,
      enteredOtp: cleanOtp,
    );
    if (localVerified) {
      debugPrint('[OtpService] Verifikasi OTP Google SMTP/Lokal BERHASIL untuk: $cleanEmail');
      return true;
    }

    // 2. Cek verifikasi ke Supabase jika aktif
    if (SupabaseConfig.isConfigured) {
      try {
        debugPrint('[OtpService] Memverifikasi OTP Supabase untuk $cleanEmail...');
        final response = await Supabase.instance.client.auth.verifyOTP(
          email: cleanEmail,
          token: cleanOtp,
          type: OtpType.email,
        );

        if (response.user != null || response.session != null) {
          debugPrint('[OtpService] Verifikasi OTP Supabase BERHASIL!');
          return true;
        }
      } catch (e) {
        debugPrint('[OtpService] Verifikasi Supabase gagal/bukan token Supabase: $e');
      }
    }

    return false;
  }

  /// Mendapatkan kode OTP aktif untuk akses cepat bantuan di aplikasi
  Future<String?> getLatestActiveOtp(String email) async {
    return await _otpService.getLatestActiveOtp(email);
  }
}
