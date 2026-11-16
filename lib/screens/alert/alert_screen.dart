// lib/screens/alert/alert_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/device_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';

class AlertScreen extends StatefulWidget {
  final DeviceModel device;
  const AlertScreen({super.key, required this.device});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _strobeCtrl;
  late AnimationController _radarCtrl;
  late AnimationController _pulseCtrl;

  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  double _sliderValue = 0.0;
  bool _isMuted = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();

    // 1. Ambient strobe gradient controller (smooth pulse)
    _strobeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // 2. Radar sweep rotation controller (360 continuous rotation)
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 3. Target blip pulse controller
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // 4. Elapsed incident timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // Haptic feedback alert
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _strobeCtrl.dispose();
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String get _elapsedFormatted {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    final dp = context.read<DeviceProvider>();
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      HapticFeedback.mediumImpact();
      dp.muteSirenTemporarily();
    } else {
      HapticFeedback.mediumImpact();
      dp.unmuteSiren();
    }
  }

  Future<void> _onSliderComplete() async {
    if (_isResetting) return;
    setState(() => _isResetting = true);
    HapticFeedback.heavyImpact();

    try {
      final auth = context.read<AuthProvider>();
      final dp = context.read<DeviceProvider>();
      final uid = auth.userModel?.uid ?? 'unknown';
      await dp.confirmAndReset(widget.device.id, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Status berhasil direset ke AMAN'),
            backgroundColor: AppColors.safe,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResetting = false;
          _sliderValue = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mereset status: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEmergencyContacts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emergency_rounded,
                        color: AppColors.danger, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panggilan Cepat Darurat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Hubungi personel keamanan perkebunan',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildContactItem(
                role: 'Pos Keamanan Utama Kebun',
                number: '0812-3456-7890',
                icon: Icons.shield_rounded,
              ),
              const SizedBox(height: 10),
              _buildContactItem(
                role: 'Mandor Jaga Sektor',
                number: '0821-9876-5432',
                icon: Icons.person_pin_circle_rounded,
              ),
              const SizedBox(height: 10),
              _buildContactItem(
                role: 'Babinsa / Keamanan Desa',
                number: '0852-1122-3344',
                icon: Icons.local_police_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required String role,
    required String number,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amberAccent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  number,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 20),
            tooltip: 'Salin Nomor',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nomor $role disalin!'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF090D16),
        body: AnimatedBuilder(
          animation: _strobeCtrl,
          builder: (_, child) {
            final t = _strobeCtrl.value;
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color.lerp(
                      const Color(0xFF450A0A),
                      const Color(0xFF881337),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFF180505),
                      const Color(0xFF2B0707),
                      t,
                    )!,
                    const Color(0xFF080C14),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  _buildTopBar(),
                  const SizedBox(height: 10),
                  _buildRadarScanner(),
                  const SizedBox(height: 14),
                  _buildAlertHeading(),
                  const SizedBox(height: 14),
                  _buildLocationCard(),
                  const SizedBox(height: 12),
                  _buildSensorTelemetryCard(),
                  const SizedBox(height: 14),
                  _buildActionRow(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: const Color(0xFF090D16),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: _buildSliderDismiss(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Elapsed time chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 14),
                const SizedBox(width: 5),
                Text(
                  _elapsedFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Mute and Alarm siren badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: _isMuted ? Colors.white54 : Colors.amberAccent,
                  size: 20,
                ),
                tooltip: _isMuted ? 'Nyalakan Suara Alarm' : 'Senyapkan Suara Sementara',
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger,
                            blurRadius: 5,
                            spreadRadius: 1.5,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'SIAGA 1: DARURAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarScanner() {
    return AnimatedBuilder(
      animation: Listenable.merge([_radarCtrl, _pulseCtrl]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing aura
            Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(
                      alpha: 0.22 + 0.14 * _pulseCtrl.value,
                    ),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),

            // Radar Custom Canvas
            CustomPaint(
              size: const Size(140, 140),
              painter: _RadarSweepPainter(
                sweepAngle: _radarCtrl.value * 2 * math.pi,
                pulseValue: _pulseCtrl.value,
              ),
            ),

            // Central Pulsing Siren Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFDC2626),
                    Color(0xFF7F1D1D),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.8),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlertHeading() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: const Color(0xFFFCA5A5),
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                _isMuted ? 'ALARM SIRINE DISETEP' : 'ALARM SIRINE AKTIF',
                style: const TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'TERDETEKSI GERAKAN\nDI PERKEBUNAN SAWIT!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.2,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Terdeteksi: ${DateFormatter.toReadable(widget.device.lastUpdated)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final batteryColor = widget.device.baterai > 60
        ? AppColors.batteryHigh
        : widget.device.baterai > 20
            ? AppColors.batteryMid
            : AppColors.batteryLow;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'LOKASI TITIK SENSOR',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.device.id,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.device.namaLokasi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip(
                icon: Icons.battery_charging_full_rounded,
                label: 'Baterai Node',
                value: '${widget.device.baterai}%',
                color: batteryColor,
              ),
              Container(width: 1, height: 22, color: Colors.white12),
              _buildMetricChip(
                icon: Icons.cell_tower_rounded,
                label: 'Sinyal LoRa',
                value: widget.device.sinyalRssi != null
                    ? '${widget.device.sinyalRssi} dBm'
                    : 'Terhubung',
                color: AppColors.accentBlue,
              ),
              Container(width: 1, height: 22, color: Colors.white12),
              _buildMetricChip(
                icon: Icons.shield_rounded,
                label: 'Status Sistem',
                value: 'INTRUSI',
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 9)),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorTelemetryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161224).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_rounded, color: Color(0xFFA78BFA), size: 16),
              SizedBox(width: 7),
              Text(
                'TELEMETRI DUAL-SENSOR IOT',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSensorRow(
            title: 'Sensor PIR (Passive Infrared)',
            subtitle: 'Deteksi radiasi panas tubuh penyusup',
            status: 'TERPICU',
            statusColor: AppColors.danger,
            icon: Icons.sensors_rounded,
          ),
          const SizedBox(height: 7),
          _buildSensorRow(
            title: 'Radar Microwave 5.8 GHz',
            subtitle: 'Deteksi gelombang Doppler gerak fisik',
            status: 'TERPICU',
            statusColor: AppColors.danger,
            icon: Icons.radar_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showEmergencyContacts,
        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
        label: const Text(
          'Panggil Tim Keamanan Kebun',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderDismiss() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxW = math.max(10.0, screenWidth - 32 - 56);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swipe_right_rounded,
                color: Colors.white54, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _isResetting
                    ? 'Sedang mereset status ke AMAN...'
                    : 'Geser ke kanan untuk matikan alarm & reset ke AMAN',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Progress green fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 40),
                width: (_sliderValue / maxW) * (screenWidth - 32),
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.safe.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(27),
                ),
              ),

              // Center guide text
              Center(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _sliderValue > 25 ? 0.0 : 1.0,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GESER UNTUK RESET',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Slider thumb
              Positioned(
                left: _sliderValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    if (_isResetting) return;
                    setState(() {
                      _sliderValue =
                          (_sliderValue + d.delta.dx).clamp(0.0, maxW);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_isResetting) return;
                    if (_sliderValue >= maxW * 0.85) {
                      _onSliderComplete();
                    } else {
                      setState(() => _sliderValue = 0);
                    }
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF059669),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.safe.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isResetting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ─── Custom Radar Sweep Painter ──────────────────────────────────────────────

class _RadarSweepPainter extends CustomPainter {
  final double sweepAngle;
  final double pulseValue;

  _RadarSweepPainter({required this.sweepAngle, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dark base circle
    final bgPaint = Paint()
      ..color = const Color(0xFF100305)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Concentric grid rings
    final ringPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3.0), ringPaint);
    }

    // Outer glow ring
    final outerRing = Paint()
      ..color =
          const Color(0xFFEF4444).withValues(alpha: 0.4 + 0.3 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, radius - 1, outerRing);

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.18)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), crossPaint);

    // Radar rotating sweep sector
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: [
          Colors.transparent,
          const Color(0xFFEF4444).withValues(alpha: 0.0),
          const Color(0xFFEF4444).withValues(alpha: 0.08),
          const Color(0xFFEF4444).withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.65, 0.85, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - 1, sweepPaint);

    // Target blip 1 (Intruder detection point)
    final blipAngle1 = math.pi * 0.28;
    final blipDist1 = radius * 0.68;
    final blipPos1 = Offset(
      center.dx + blipDist1 * math.cos(blipAngle1),
      center.dy + blipDist1 * math.sin(blipAngle1),
    );

    final blipHalo1 = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35 + 0.45 * pulseValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(blipPos1, 8 + 3 * pulseValue, blipHalo1);

    final blipCore1 = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(blipPos1, 3.8, blipCore1);
  }

  @override
  bool shouldRepaint(_RadarSweepPainter old) =>
      old.sweepAngle != sweepAngle || old.pulseValue != pulseValue;
}
