// lib/data/services/email_otp_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/email_config.dart';

class _OtpCacheEntry {
  final String otp;
  final int expiresAt;
  bool verified = false;

  _OtpCacheEntry({
    required this.otp,
    required this.expiresAt,
  });
}

class EmailOtpService {
  late final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://sawitguard-iot-prod-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// In-memory cache agar OTP tetap bekerja instan
  static final Map<String, List<_OtpCacheEntry>> _localOtpCache = {};

  /// Durasi berlaku OTP: 30 menit (1800 detik) agar pengguna tidak terburu-buru
  static const int _otpValiditySeconds = 1800;

  /// Sanitize email for Firebase Realtime Database path & persistent key
  String _sanitizeKey(String email) {
    return email
        .trim()
        .toLowerCase()
        .replaceAll('.', '_')
        .replaceAll('@', '_at_');
  }

  String _buildHtmlTemplate(String otp) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kode Verifikasi SawitGuard</title>
</head>
<body style="margin: 0; padding: 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f1f5f9; color: #1e293b;">
  <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; border: 1px solid #e2e8f0; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);">
    <div style="background-color: #064e3b; padding: 24px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 22px; font-weight: 700;">SawitGuard IoT</h1>
      <p style="color: #6ee7b7; margin: 4px 0 0; font-size: 13px;">Sistem Keamanan Kebun Sawit Terintegrasi</p>
    </div>
    <div style="padding: 28px 24px; text-align: center;">
      <p style="font-size: 15px; color: #334155; line-height: 1.5; margin: 0 0 20px;">
        Gunakan kode verifikasi berikut untuk menyelesaikan pendaftaran akun kebun Anda:
      </p>
      <div style="background-color: #f0fdf4; border: 1.5px solid #a7f3d0; border-radius: 10px; padding: 16px 24px; display: inline-block; margin-bottom: 20px;">
        <span style="font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #047857; font-family: monospace;">$otp</span>
      </div>
      <p style="font-size: 13px; color: #64748b; line-height: 1.4; margin: 0;">
        Kode verifikasi ini berlaku selama <strong>30 menit</strong>.
      </p>
    </div>
    <div style="background-color: #f8fafc; padding: 16px 24px; text-align: center; border-top: 1px solid #e2e8f0; font-size: 12px; color: #94a3b8;">
      Universitas Islam Madura &bull; SawitGuard IoT Security &bull; Indonesia
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Kirim email via Brevo REST API (dengan optimasi anti-spam & deliverability)
  Future<void> _sendViaBrevo(String recipientEmail, String otp) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('https://api.brevo.com/v3/smtp/email'));
      request.headers.set('accept', 'application/json');
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('api-key', EmailConfig.brevoApiKey.trim());

      final body = jsonEncode({
        'sender': {
          'name': 'SawitGuard IoT',
          'email': EmailConfig.senderEmail,
        },
        'to': [
          {'email': recipientEmail}
        ],
        'replyTo': {
          'email': EmailConfig.senderEmail,
          'name': 'SawitGuard Support',
        },
        'subject': 'Kode Verifikasi Pendaftaran SawitGuard IoT: $otp',
        'textContent': '''Halo Pengelola Kebun Sawit,

Terima kasih telah mendaftar di SawitGuard IoT.
Kode verifikasi pendaftaran akun Anda adalah: $otp

Kode ini berlaku selama 30 menit.

Salam hormat,
Tim SawitGuard IoT - Universitas Islam Madura''',
        'htmlContent': _buildHtmlTemplate(otp),
        'headers': {
          'X-Entity-Ref-ID': '$otp-${DateTime.now().millisecondsSinceEpoch}',
        },
      });

      request.add(utf8.encode(body));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[Brevo API] Email OTP berhasil dikirim ke $recipientEmail! ($responseBody)');
      } else {
        debugPrint('[Brevo API Error] Status: ${response.statusCode}, Body: $responseBody');
        throw Exception('Brevo API Error (${response.statusCode}): $responseBody');
      }
    } finally {
      client.close();
    }
  }

  /// Ambil OTP aktif terakhir untuk email tertentu (bantuan verifikasi)
  Future<String?> getLatestActiveOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final key = _sanitizeKey(cleanEmail);
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 1. Cek memory
    final localList = _localOtpCache[key];
    if (localList != null && localList.isNotEmpty) {
      for (final entry in localList.reversed) {
        if (nowTs <= entry.expiresAt && !entry.verified) {
          return entry.otp;
        }
      }
    }

    // 2. Cek SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'sg_otp_$key';
      final existingJson = prefs.getStringList(prefKey) ?? [];
      for (final raw in existingJson.reversed) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final otp = map['otp']?.toString().trim();
          final expiresAt = (map['expiresAt'] as num?)?.toInt() ?? 0;
          final isVerified = map['verified'] == true;
          if (otp != null && nowTs <= expiresAt && !isVerified) {
            return otp;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  /// Kirim email via Gmail SMTP
  Future<void> _sendViaGmailSmtp(String recipientEmail, String otp) async {
    final smtpServer = gmail(
      EmailConfig.senderEmail,
      EmailConfig.senderPassword.replaceAll(' ', ''),
    );

    final message = Message()
      ..from = Address(EmailConfig.senderEmail, EmailConfig.senderName)
      ..recipients.add(recipientEmail)
      ..subject = 'Kode Verifikasi Pendaftaran SawitGuard IoT: $otp'
      ..text = 'Kode OTP SawitGuard IoT Anda adalah: $otp (berlaku 30 menit).'
      ..html = _buildHtmlTemplate(otp);

    await send(message, smtpServer);
    debugPrint('[SMTP] Email OTP berhasil terkirim ke $recipientEmail');
  }

  /// Simpan OTP ke SharedPreferences (kebal restart/kill app dari sistem Android)
  Future<void> _persistOtp(String email, String otp, int expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sg_otp_${_sanitizeKey(email)}';
      final existingJson = prefs.getStringList(key) ?? [];
      final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Filter yang masih berlaku dan tambahkan OTP baru
      final List<Map<String, dynamic>> list = [];
      for (final raw in existingJson) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final exp = (map['expiresAt'] as num?)?.toInt() ?? 0;
          if (exp > nowTs) {
            list.add(map);
          }
        } catch (_) {}
      }

      list.add({
        'otp': otp,
        'expiresAt': expiresAt,
        'verified': false,
      });

      // Simpan maksimal 10 riwayat OTP terbaru
      final toSave = list.reversed.take(10).toList().reversed
          .map((m) => jsonEncode(m))
          .toList();

      await prefs.setStringList(key, toSave);
      debugPrint('[OTP Storage] OTP $otp berhasil disimpan ke disk lokal untuk $email');
    } catch (e) {
      debugPrint('[OTP Storage Error] Gagal persist OTP: $e');
    }
  }

  /// Generate 6-digit OTP, simpan ke persistent disk & memory, lalu kirim email
  Future<String> sendOtpToEmail(String recipientEmail) async {
    final cleanEmail = recipientEmail.trim().toLowerCase();

    // 1. Generate 6-digit random number
    final otp = (100000 + Random().nextInt(900000)).toString();
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = nowTs + _otpValiditySeconds; // 30 menit
    final key = _sanitizeKey(cleanEmail);

    // 2. Simpan ke memory cache
    _localOtpCache.putIfAbsent(key, () => []);
    _localOtpCache[key]!.add(_OtpCacheEntry(
      otp: otp,
      expiresAt: expiresAt,
    ));

    // 3. Simpan ke disk lokal (SharedPreferences) - kebal kill process Infinix
    await _persistOtp(cleanEmail, otp, expiresAt);

    // 4. Cadangkan ke Firebase Realtime Database jika diizinkan
    try {
      await _db.ref('otp_verifications/$key').set({
        'otp': otp,
        'email': cleanEmail,
        'created_at': nowTs,
        'expires_at': expiresAt,
        'verified': false,
      }).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[OTP RTDB Note] RTDB write fallback to local storage: $e');
    }

    debugPrint('=========================================');
    debugPrint('[OTP GENERATED] Email: $cleanEmail -> KODE OTP: $otp (Berlaku 30 Menit)');
    debugPrint('=========================================');

    // 5. Kirim email nyata ke inbox Gmail pendaftar
    if (EmailConfig.isConfigured) {
      try {
        if (EmailConfig.method == 'brevo') {
          await _sendViaBrevo(cleanEmail, otp);
        } else {
          await _sendViaGmailSmtp(cleanEmail, otp);
        }
      } catch (e) {
        debugPrint('[Email Send Warning] Pengiriman email eksternal terkendala: $e');
        // Jangan lempar exception agar pengguna tetap dapat melanjutkan verifikasi via OTP aktif
      }
    } else {
      debugPrint('[Email Info] API Key belum diset. Kode OTP: $otp');
    }

    return otp;
  }

  /// Verifikasi kode OTP secara komprehensif (Memory + SharedPreferences + RTDB)
  Future<bool> verifyOtp({
    required String email,
    required String enteredOtp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final key = _sanitizeKey(cleanEmail);
    // Bersihkan karakter non-digit dan spasi dari kode yang dimasukkan
    final cleanEntered = enteredOtp.replaceAll(RegExp(r'\D'), '').trim();
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    debugPrint('[OTP Verify] Memverifikasi kode: "$cleanEntered" untuk email: $cleanEmail');

    if (cleanEntered.length != 6) {
      debugPrint('[OTP Verify] Format OTP tidak valid (panjang: ${cleanEntered.length})');
      return false;
    }

    // 1. Cek dari memory cache
    final localList = _localOtpCache[key];
    if (localList != null) {
      for (final entry in localList.reversed) {
        if (entry.otp == cleanEntered && nowTs <= entry.expiresAt && !entry.verified) {
          entry.verified = true;
          debugPrint('[OTP Verify Success] Validasi berhasil via memory cache!');
          await _markOtpVerified(cleanEmail, cleanEntered);
          return true;
        }
      }
    }

    // 2. Cek dari SharedPreferences (Disk lokal yang bertahan meski aplikasi ditutup)
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefKey = 'sg_otp_$key';
      final existingJson = prefs.getStringList(prefKey) ?? [];

      bool foundValid = false;
      final List<Map<String, dynamic>> updatedList = [];

      for (final raw in existingJson) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final savedOtp = map['otp']?.toString().trim();
          final expiresAt = (map['expiresAt'] as num?)?.toInt() ?? 0;
          final isVerified = map['verified'] == true;

          if (savedOtp == cleanEntered && nowTs <= expiresAt && !isVerified && !foundValid) {
            foundValid = true;
            map['verified'] = true;
          }
          updatedList.add(map);
        } catch (_) {}
      }

      if (foundValid) {
        final toSave = updatedList.map((m) => jsonEncode(m)).toList();
        await prefs.setStringList(prefKey, toSave);
        debugPrint('[OTP Verify Success] Validasi berhasil via SharedPreferences persistent storage!');
        await _markOtpVerified(cleanEmail, cleanEntered);
        return true;
      }
    } catch (e) {
      debugPrint('[OTP Verify Prefs Warning] $e');
    }

    // 3. Cek dari Realtime Database jika ada
    try {
      final snap = await _db
          .ref('otp_verifications/$key')
          .get()
          .timeout(const Duration(seconds: 3));

      if (snap.exists && snap.value != null) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final savedOtp = data['otp']?.toString().trim();
        final expiresAt = (data['expires_at'] as num?)?.toInt() ?? 0;

        if (savedOtp == cleanEntered && nowTs <= expiresAt) {
          debugPrint('[OTP Verify Success] Validasi berhasil via RTDB!');
          await _markOtpVerified(cleanEmail, cleanEntered);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[OTP RTDB Verify Warning] $e');
    }

    debugPrint('[OTP Verify Failed] Kode $cleanEntered tidak cocok atau telah kedaluwarsa.');
    return false;
  }

  Future<void> _markOtpVerified(String cleanEmail, String otp) async {
    final key = _sanitizeKey(cleanEmail);
    try {
      await _db
          .ref('otp_verifications/$key')
          .update({'verified': true})
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
