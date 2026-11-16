// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/agro_motion_background.dart';
import '../../data/models/device_model.dart';
import '../../providers/device_provider.dart';
import '../alert/alert_screen.dart';
import '../history/history_screen.dart';
import 'widgets/analytics_tab_widget.dart';
import 'widgets/perimeter_radar_widget.dart';
import 'widgets/settings_tab_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;
  String _selectedFilter = 'Semua';
  bool _alertShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().syncAllFourNodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    final hasIntrusion = deviceProvider.hasActiveIntrusion;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AgroMotionBackground(
        variant: AgroMotionVariant.dashboard,
        isIntrusionAlert: hasIntrusion,
        child: StreamBuilder<List<DeviceModel>>(
          stream: deviceProvider.streamDevices(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.safe),
              );
            }

            final devices = snapshot.data!;

            // Auto-navigate to alert screen on intrusion
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (deviceProvider.isAlarmActive &&
                  !_alertShowing &&
                  deviceProvider.activeAlertDevice != null) {
                _alertShowing = true;
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => AlertScreen(
                      device: deviceProvider.activeAlertDevice!,
                    ),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 250),
                  ),
                ).then((_) => _alertShowing = false);
              }
            });

            return IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildPerimeterMonitoringTab(context, deviceProvider, devices),
                const HistoryScreen(isEmbedded: true),
                AnalyticsTabWidget(devices: devices),
                const SettingsTabWidget(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(deviceProvider),
    );
  }

  /// ─── Professional Bottom Navigation Bar ────────────────────────────────────
  Widget _buildBottomNavigationBar(DeviceProvider dp) {
    final hasIntrusion = dp.hasActiveIntrusion;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1322).withValues(alpha: 0.90),
        border: Border(
          top: BorderSide(
            color: (hasIntrusion ? AppColors.danger : AppColors.safe).withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.shield_rounded,
                inactiveIcon: Icons.shield_outlined,
                label: 'Perimeter',
                badgeCount: hasIntrusion ? dp.intrusionCount : 0,
                badgeColor: AppColors.danger,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_rounded,
                inactiveIcon: Icons.history_toggle_off_rounded,
                label: 'Riwayat',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.analytics_rounded,
                inactiveIcon: Icons.analytics_outlined,
                label: 'Analitik',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.settings_rounded,
                inactiveIcon: Icons.settings_outlined,
                label: 'Pengaturan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    int badgeCount = 0,
    Color badgeColor = AppColors.safe,
  }) {
    final isSelected = _currentTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.safe.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.safe.withAlpha(80), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? icon : inactiveIcon,
                  size: 22,
                  color: isSelected ? AppColors.safe : AppColors.textMuted,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 14),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.safe : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ─── Tab 0: Perimeter Monitoring ──────────────────────────────────────────
  Widget _buildPerimeterMonitoringTab(BuildContext context,
      DeviceProvider deviceProvider, List<DeviceModel> devices) {
    // Filter devices based on chip
    final filteredDevices = devices.where((d) {
      if (_selectedFilter == 'Intrusi') return d.isIntrusi;
      if (_selectedFilter == 'Aman') return !d.isIntrusi;
      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.safe,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () async {
        await deviceProvider.syncAllFourNodes();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Executive Top Bar
          SliverToBoxAdapter(child: _buildExecutiveAppBar(context)),

          // Hero Status Banner
          SliverToBoxAdapter(
            child: _buildHeroStatusBanner(context, deviceProvider, devices),
          ),

          // 4-Point Quick Telemetry Strip
          SliverToBoxAdapter(
            child: _buildQuickTelemetryStrip(devices),
          ),

          // Interactive Cardinal Radar Compass
          SliverToBoxAdapter(
            child: PerimeterRadarWidget(
              devices: devices,
              onNodeSelected: (selectedDevice) {
                _showNodeDetailSheet(context, selectedDevice);
              },
            ),
          ),

          // Section Title & Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Blok Perimeter',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.safe.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${devices.length} Node',
                            style: const TextStyle(
                              color: AppColors.safe,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFilterChips(devices),
                ],
              ),
            ),
          ),

          // List of Node Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DeviceCard(
                    device: filteredDevices[i],
                    index: i,
                    onTap: () => _showNodeDetailSheet(context, filteredDevices[i]),
                  ),
                ),
                childCount: filteredDevices.length,
              ),
            ),
          ),

          if (filteredDevices.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState()),
        ],
      ),
    );
  }

  /// ─── Executive App Bar ────────────────────────────────────────────────────
  Widget _buildExecutiveAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            // Logo Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.safe.withAlpha(90),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SawitGuard IoT',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accentBlue.withAlpha(90)),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Perimeter 4 Titik Mata Angin',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Realtime Online Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.safe.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.safe.withAlpha(70)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_tethering_rounded, color: AppColors.safe, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'ONLINE',
                    style: TextStyle(
                      color: AppColors.safe,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ─── Hero Status Banner ───────────────────────────────────────────────────
  Widget _buildHeroStatusBanner(
      BuildContext ctx, DeviceProvider dp, List<DeviceModel> devices) {
    final hasIntrusion = dp.hasActiveIntrusion;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasIntrusion
              ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
              : [const Color(0xFF064E3B), const Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasIntrusion
              ? AppColors.danger.withAlpha(140)
              : AppColors.safe.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasIntrusion ? AppColors.danger : AppColors.safe)
                .withAlpha(70),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _PulseIcon(
            icon: hasIntrusion
                ? Icons.warning_amber_rounded
                : Icons.verified_user_rounded,
            color: Colors.white,
            pulse: hasIntrusion,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasIntrusion
                          ? '⚠️ PERINGATAN INTRUSI!'
                          : '✅ SEMUA TITIK AMAN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasIntrusion
                      ? '${dp.intrusionCount} blok perimeter mendeteksi aktivitas mencurigakan!'
                      : '${devices.length} node aktif (Utara, Selatan, Timur, Barat)',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasIntrusion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'BAHAYA',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ─── Quick Telemetry Strip ────────────────────────────────────────────────
  Widget _buildQuickTelemetryStrip(List<DeviceModel> devices) {
    final int safeCount = devices.where((d) => !d.isIntrusi).length;
    final int intrusionCount = devices.where((d) => d.isIntrusi).length;
    final double avgBattery = devices.isEmpty
        ? 0
        : devices.fold<int>(0, (sum, d) => sum + d.baterai) / devices.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Titik Aman',
              value: '$safeCount / ${devices.length}',
              icon: Icons.check_circle_outline,
              color: AppColors.safe,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Intrusi Aktif',
              value: '$intrusionCount Node',
              icon: Icons.warning_amber_rounded,
              color: intrusionCount > 0 ? AppColors.danger : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Rata2 Baterai',
              value: '${avgBattery.toInt()}%',
              icon: Icons.battery_charging_full_rounded,
              color: AppColors.batteryHigh,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              label: 'Perimeter',
              value: '100% OK',
              icon: Icons.all_inclusive_rounded,
              color: AppColors.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// ─── Filter Chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips(List<DeviceModel> devices) {
    final int intrusionCount = devices.where((d) => d.isIntrusi).length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterItem('Semua', 'Semua'),
        const SizedBox(width: 6),
        _buildFilterItem(
          'Aman',
          'Aman',
        ),
        if (intrusionCount > 0) ...[
          const SizedBox(width: 6),
          _buildFilterItem('Intrusi', '⚠️ $intrusionCount'),
        ],
      ],
    );
  }

  Widget _buildFilterItem(String key, String display) {
    final isSelected = _selectedFilter == key;

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = key);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.safe
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.safe : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          display,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ─── Node Detail Bottom Sheet ─────────────────────────────────────────────
  void _showNodeDetailSheet(BuildContext context, DeviceModel device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (device.isIntrusi ? AppColors.danger : AppColors.safe)
                          .withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.directionCode,
                      style: TextStyle(
                        color: device.isIntrusi
                            ? AppColors.danger
                            : AppColors.safe,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.namaLokasi,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${device.zoneBadge} • ID: ${device.id}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (device.isIntrusi
                              ? AppColors.danger
                              : AppColors.safe)
                          .withAlpha(35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      device.status,
                      style: TextStyle(
                        color: device.isIntrusi
                            ? AppColors.danger
                            : AppColors.safe,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildSheetRow('Sinyal LoRa (RSSI)', '${device.sinyalRssi ?? -98} dBm (${device.signalQuality})'),
              _buildSheetRow('Kapasitas Baterai', '${device.baterai}% • Tegangan ~3.8V Li-ion'),
              _buildSheetRow('Sensor PIR Gerak', device.pirStatus ?? 'Standby (Normal)'),
              _buildSheetRow('Sensor Laser Perimeter', device.laserStatus ?? 'Terhubung (Normal)'),
              _buildSheetRow('Ping Terakhir', DateFormatter.toReadable(device.lastUpdated)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Tutup Detail Node'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.sensors_off_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada node yang sesuai',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah filter di bagian atas.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            const Text('Gagal terhubung ke database',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(error,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// ─── Ultra-Premium Device Card ───────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final int index;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.index,
    required this.onTap,
  });

  Color _getCardinalColor(String code) {
    switch (code) {
      case 'U':
        return const Color(0xFF3B82F6); // Blue
      case 'S':
        return const Color(0xFF10B981); // Emerald
      case 'T':
        return const Color(0xFFF59E0B); // Amber
      case 'B':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return AppColors.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIntrusi = device.isIntrusi;
    final cardinalColor = _getCardinalColor(device.directionCode);

    final batteryColor = device.baterai > 60
        ? AppColors.batteryHigh
        : device.baterai > 25
            ? AppColors.batteryMid
            : AppColors.batteryLow;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: isIntrusi
              ? AppColors.danger.withAlpha(25)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isIntrusi
                ? AppColors.danger.withAlpha(150)
                : AppColors.borderSubtle,
            width: isIntrusi ? 1.5 : 1,
          ),
          boxShadow: isIntrusi
              ? [
                  BoxShadow(
                    color: AppColors.danger.withAlpha(60),
                    blurRadius: 18,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Cardinal Badge + Location + Status Chip
              Row(
                children: [
                  // Direction Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardinalColor.withAlpha(35),
                      border: Border.all(
                        color: isIntrusi ? AppColors.danger : cardinalColor,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      device.directionCode,
                      style: TextStyle(
                        color: isIntrusi ? AppColors.danger : cardinalColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Zone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                device.namaLokasi,
                                style: const TextStyle(
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: cardinalColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                device.zoneBadge,
                                style: TextStyle(
                                  color: cardinalColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ID: ${device.id}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isIntrusi ? AppColors.danger : AppColors.safe)
                          .withAlpha(40),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isIntrusi ? AppColors.danger : AppColors.safe)
                            .withAlpha(120),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isIntrusi) ...[
                          const Icon(Icons.crisis_alert_rounded,
                              size: 12, color: AppColors.danger),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          device.status,
                          style: TextStyle(
                            color: isIntrusi ? AppColors.danger : AppColors.safe,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dual-Sensor State Bar (PIR & Laser)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    // PIR
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.motion_photos_on_rounded,
                              size: 13,
                              color: isIntrusi
                                  ? AppColors.danger
                                  : AppColors.safe),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'PIR: ${device.pirStatus ?? 'Standby'}',
                              style: TextStyle(
                                color: isIntrusi
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      color: AppColors.borderSubtle,
                    ),
                    const SizedBox(width: 8),
                    // Laser
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.stream_rounded,
                              size: 13,
                              color: isIntrusi
                                  ? AppColors.danger
                                  : AppColors.accentBlue),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Laser: ${device.laserStatus ?? 'Terhubung'}',
                              style: TextStyle(
                                color: isIntrusi
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Telemetry Metrics Row (Battery, RSSI, Ping)
              Row(
                children: [
                  _CardMetric(
                    icon: Icons.battery_std_rounded,
                    label: 'Baterai',
                    value: '${device.baterai}%',
                    color: batteryColor,
                  ),
                  const SizedBox(width: 16),
                  if (device.sinyalRssi != null)
                    _CardMetric(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'RSSI LoRa',
                      value: '${device.sinyalRssi} dBm',
                      color: AppColors.accentBlue,
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Ping Terakhir',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        DateFormatter.toRelative(device.lastUpdated),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Battery Gauge Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (device.baterai / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * index))
        .slideY(begin: 0.04, end: 0);
  }
}

class _CardMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ─── Pulse Icon Widget ────────────────────────────────────────────────────────

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool pulse;

  const _PulseIcon({
    required this.icon,
    required this.color,
    this.pulse = false,
  });

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseIcon old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: widget.pulse ? 0.4 + 0.6 * _ctrl.value : 1.0,
        child: Icon(widget.icon, color: widget.color, size: 36),
      ),
    );
  }
}
