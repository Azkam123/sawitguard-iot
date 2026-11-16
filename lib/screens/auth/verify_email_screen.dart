// lib/screens/auth/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _isChecking = false;
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
    _startCountdown();
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final auth = context.read<AuthProvider>();
      final isVerified = await auth.checkEmailVerified();
      if (isVerified && mounted) {
        _timer?.cancel();
        _countdownTimer?.cancel();
        _onVerificationSuccess();
      }
    });
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _manualCheck() async {
    setState(() => _isChecking = true);
    final auth = context.read<AuthProvider>();
    final isVerified = await auth.checkEmailVerified();
    setState(() => _isChecking = false);

    if (!mounted) return;

    if (isVerified) {
      _timer?.cancel();
      _countdownTimer?.cancel();
      _onVerificationSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Email belum terverifikasi. Mohon klik link pada email yang dikirimkan ke Gmail Anda.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCountdown > 0) return;

    final auth = context.read<AuthProvider>();
    await auth.resendVerificationEmail();
    _startCountdown();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email verifikasi baru telah dikirimkan! Silakan cek Gmail Anda.'),
          backgroundColor: AppColors.safe,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _onVerificationSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Expanded(child: Text('Verifikasi Berhasil! Selamat datang di SawitGuard.')),
          ],
        ),
        backgroundColor: AppColors.safe,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/dashboard',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final targetEmail = widget.email ?? auth.currentUser?.email ?? 'Gmail Anda';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Mail Envelope Badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.safe.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.safe.withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 52,
                  color: AppColors.safe,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut),

              const SizedBox(height: 28),

              Text(
                'Cek Email Anda',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              Text(
                'Tautan verifikasi resmi dari Firebase telah dikirimkan ke:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 14),

              // Email Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_outline, size: 18, color: AppColors.safe),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        targetEmail,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: AppColors.accentBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Buka aplikasi Gmail Anda lalu klik tombol/link verifikasi. Layar ini akan otomatis beralih ke Dasbor setelah diverifikasi (cek juga folder Spam).',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const Spacer(),

              // Primary Action: Manual Check Button
              ElevatedButton(
                onPressed: _isChecking ? null : _manualCheck,
                child: _isChecking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text('Saya Sudah Klik Link Verifikasi'),
                        ],
                      ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 12),

              // Resend Button
              OutlinedButton(
                onPressed: _resendCountdown > 0 ? null : _resendEmail,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(
                    color: _resendCountdown > 0 ? AppColors.borderSubtle : AppColors.safe,
                  ),
                ),
                child: Text(
                  _resendCountdown > 0
                      ? 'Kirim Ulang Email ($_resendCountdown s)'
                      : 'Kirim Ulang Email Verifikasi',
                  style: TextStyle(
                    color: _resendCountdown > 0 ? AppColors.textMuted : AppColors.safe,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 8),

              // Cancel / Sign out
              TextButton(
                onPressed: () async {
                  _timer?.cancel();
                  _countdownTimer?.cancel();
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                child: const Text(
                  'Ganti Akun / Batal',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
