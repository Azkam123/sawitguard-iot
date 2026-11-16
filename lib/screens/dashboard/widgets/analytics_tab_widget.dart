// lib/screens/dashboard/widgets/analytics_tab_widget.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/device_model.dart';

class AnalyticsTabWidget extends StatelessWidget {
  final List<DeviceModel> devices;

  const AnalyticsTabWidget({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeroMetricCard(),

          const SizedBox(height: 18),

          // 7-Day Trend Chart Card
          _buildWeeklyTrendCard(),

          const SizedBox(height: 18),

          // Node Telemetry Comparison Matrix (Utara, Selatan, Timur, Barat)
          _buildNodeComparisonMatrix(),

          const SizedBox(height: 18),

          // System Specifications & Health
          _buildSystemHealthCard(),
        ],
      ),
    );
  }

  Widget _buildHeroMetricCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.safe.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.safe.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppColors.safe, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Performa Keamanan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.safe.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SIAGA 24/7',
                  style: TextStyle(
                    color: AppColors.safe,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricStat('Uptime Sensor', '99.8%', Icons.verified_user_rounded, AppColors.safe),
              _buildMetricStat('Respon Rata-rata', '1.4 mnt', Icons.timer_rounded, AppColors.accentBlue),
              _buildMetricStat('Cakupan Wilayah', '40 Ha', Icons.landscape_rounded, AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendCard() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final heights = [0.2, 0.4, 0.1, 0.6, 0.3, 0.8, 0.2]; // Relative intensity

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tren Intrusi 7 Hari',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Terkendali (Aman)',
                style: TextStyle(
                  color: AppColors.safe,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final isToday = i == 6;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 80 * heights[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [AppColors.accentBlue, AppColors.safe]
                              : [AppColors.safe.withAlpha(60), AppColors.safe.withAlpha(160)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[i],
                      style: TextStyle(
                        color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeComparisonMatrix() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matriks Kesehatan 4 Node Perimeter',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...devices.map((device) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (device.isIntrusi ? AppColors.danger : AppColors.safe).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          device.directionCode,
                          style: TextStyle(
                            color: device.isIntrusi ? AppColors.danger : AppColors.safe,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.namaLokasi,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${device.id} • ${device.directionName}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.battery_std_rounded,
                            size: 16,
                            color: device.baterai > 50
                                ? AppColors.safe
                                : (device.baterai > 20 ? AppColors.warning : AppColors.danger)),
                        const SizedBox(width: 2),
                        Text(
                          '${device.baterai}%',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.wifi_rounded, size: 16, color: AppColors.accentBlue),
                        const SizedBox(width: 2),
                        Text(
                          '${device.sinyalRssi ?? -95} dBm',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Infrastruktur IoT & Komunikasi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildSpecRow('Protokol Komunikasi', 'LoRaWAN 915 MHz + ESP-NOW'),
          _buildSpecRow('Sensor Utama', 'PIR HC-SR501 & Dual Laser Barrier'),
          _buildSpecRow('Frekuensi Ping', 'Realtime Polling (1.0 Detik)'),
          _buildSpecRow('Cloud Gateway', 'Firebase Realtime Database Asia SE1'),
          _buildSpecRow('Background Daemon', 'Android Foreground Service 24/7 (START_STICKY)'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
