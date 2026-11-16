// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/supabase_otp_service.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final SupabaseOtpService _otpService = SupabaseOtpService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _userModel;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userModel = null;
    } else {
      _userModel = await _authService.getUserProfile(user.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  User? get currentUser => _authService.currentUser;
  bool get isEmailVerified => _authService.currentUser?.emailVerified ?? false;

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Request and send 6-digit OTP code to Gmail
  Future<String?> requestOtp(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final otp = await _otpService.sendOtpToEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return otp;
    } catch (e) {
      _errorMessage = 'Gagal mengirim kode OTP: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    }
  }

  /// Ambil OTP aktif terakhir untuk email tertentu
  Future<String?> getLatestActiveOtp(String email) async {
    return await _otpService.getLatestActiveOtp(email);
  }

  /// Verify entered OTP and finalize account registration
  Future<bool> verifyOtpAndRegister({
    required String email,
    required String enteredOtp,
    required String password,
    required String nama,
    required String noHp,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final isValid = await _otpService.verifyOtp(
        email: email,
        enteredOtp: enteredOtp,
      );

      if (!isValid) {
        _errorMessage = 'Kode OTP salah atau telah kedaluwarsa.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // OTP Valid -> Daftarkan ke Firebase Auth & RTDB
      await _authService.signUp(
        email: email,
        password: password,
        nama: nama,
        noHp: noHp,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Pendaftaran gagal: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nama,
    required String noHp,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        nama: nama,
        noHp: noHp,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mendaftar: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    return await _authService.checkEmailVerified();
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendVerificationEmail();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    await _authService.saveFcmToken(uid, token);
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      default:
        return 'Terjadi kesalahan ($code). Silakan coba lagi.';
    }
  }
}
