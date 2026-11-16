// lib/screens/dashboard/widgets/settings_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/audio_alert_service.dart';
import '../../../providers/auth_provider.dart';

class SettingsTabWidget extends StatefulWidget {
  const SettingsTabWidget({super.key});

  @override
  State<SettingsTabWidget> createState() => _SettingsTabWidgetState();
}

class _SettingsTabWidgetState extends State<SettingsTabWidget> {
  final AudioAlertService _audioService = AudioAlertService();
  bool _isTestingSiren = false;

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  void _toggleSirenTest() async {
    if (_isTestingSiren) {
      await _audioService.stopSiren();
      setState(() => _isTestingSiren = false);
    } else {
      setState(() => _isTestingSiren = true);
      await _audioService.playSiren();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userModel = auth.userModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.safe, Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safe.withAlpha(80),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel?.nama ?? user?.displayName ?? 'Mandor / Pengelola Kebun',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? (userModel?.noHp.isNotEmpty == true ? userModel!.noHp : 'petani@sawitguard.id'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.safe.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.safe.withAlpha(80)),
                        ),
                        child: const Text(
                          'PETANI RESMI (TERVERIFIKASI)',
                          style: TextStyle(
                            color: AppColors.safe,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Background Service 24/7 Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.safe.withAlpha(90)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded, color: AppColors.safe, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daemon Pemantau Latar Belakang',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Aktif 24/7 dengan proteksi anti-freeze Infinix XOS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 22),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Audio Siren Testing Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.volume_up_rounded, color: AppColors.warning, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Uji Coba Alarm & Getaran',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uji suara sirine pemadam kebakaran untuk memastikan speaker HP berfungsi dengan optimal saat terjadi intrusi.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _toggleSirenTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTestingSiren ? AppColors.danger : AppColors.surface,
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: _isTestingSiren ? AppColors.danger : AppColors.safe,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_isTestingSiren ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_isTestingSiren ? 'Hentikan Uji Sirine' : 'Bunyikan Uji Sirine (Demo)'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Emergency Hotlines Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.contact_phone_rounded, color: AppColors.accentBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Kontak Darurat Terintegrasi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildContactTile(
                  title: 'Pos Keamanan Satpam Kebun',
                  subtitle: 'Regu Jaga Malam Blok A-D',
                  phone: '0812-7890-4321',
                  icon: Icons.shield_rounded,
                  color: AppColors.safe,
                ),
                const Divider(color: AppColors.borderSubtle, height: 20),
                _buildContactTile(
                  title: 'Bhabinkamtibmas / Polsek',
                  subtitle: 'Sentra Pelayanan Kepolisian (SPKT)',
                  phone: '110 / 0811-2233-4455',
                  icon: Icons.local_police_rounded,
                  color: AppColors.accentBlue,
                ),
                const Divider(color: AppColors.borderSubtle, height: 20),
                _buildContactTile(
                  title: 'Regu Pemadam Kebakaran & BPBD',
                  subtitle: 'Siaga Karhutla & Evakuasi Darurat',
                  phone: '113 / 112',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                await auth.signOut();
                nav.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Keluar dari Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'SawitGuard IoT v2.1.0 • Enterprise Plantation Edition',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required String title,
    required String subtitle,
    required String phone,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Text(
            phone,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
