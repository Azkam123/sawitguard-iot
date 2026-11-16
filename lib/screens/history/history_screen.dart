// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/agro_motion_background.dart';
import '../../data/models/log_model.dart';
import '../../providers/device_provider.dart';

class HistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  const HistoryScreen({super.key, this.isEmbedded = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().loadHistoryLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DeviceProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Riwayat Intrusi'),
              leading: const BackButton(color: AppColors.textPrimary),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Segarkan',
                  onPressed: () => dp.loadHistoryLogs(),
                ),
              ],
            ),
      body: widget.isEmbedded
          ? SafeArea(
              top: true,
              child: dp.isLoadingHistory
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.safe))
                  : dp.historyLogs.isEmpty
                      ? Column(
                          children: [
                            _buildEmbeddedHeader(dp),
                            Expanded(child: _buildEmpty()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildEmbeddedHeader(dp),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: dp.historyLogs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (ctx, i) =>
                                    _LogCard(log: dp.historyLogs[i], index: i),
                              ),
                            ),
                          ],
                        ),
            )
          : AgroMotionBackground(
              variant: AgroMotionVariant.minimal,
              child: SafeArea(
                top: false,
                child: dp.isLoadingHistory
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.safe))
            : dp.historyLogs.isEmpty
                ? Column(
                    children: [
                      if (widget.isEmbedded) _buildEmbeddedHeader(dp),
                      Expanded(child: _buildEmpty()),
                    ],
                  )
                : Column(
                    children: [
                      if (widget.isEmbedded) _buildEmbeddedHeader(dp),
                      _buildSummaryBanner(dp.historyLogs.length),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: dp.historyLogs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _LogCard(
                            log: dp.historyLogs[i],
                            index: i,
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
            ),
    );
  }

  Widget _buildEmbeddedHeader(DeviceProvider dp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.safe.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded,
                    color: AppColors.safe, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Intrusi',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Catatan insiden & waktu kejadian',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.safe),
            tooltip: 'Segarkan',
            onPressed: () => dp.loadHistoryLogs(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Text(
            'Total $count kejadian tercatat dalam database',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_toggle_off_rounded,
              size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat intrusi',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistem berhasil memantau tanpa kejadian\nIntrusi akan dicatat secara otomatis',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ─── Log Card ─────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final HistoryLogModel log;
  final int index;
  const _LogCard({required this.log, required this.index});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = log.dikonfirmasiOleh != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConfirmed
              ? AppColors.safe.withValues(alpha: 0.3)
              : AppColors.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    log.lokasi,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                // Confirmation status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isConfirmed ? AppColors.safe : AppColors.warning)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isConfirmed ? '✓ Direset' : 'Belum dikonfirmasi',
                    style: TextStyle(
                      color: isConfirmed ? AppColors.safe : AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Keterangan
            Text(
              log.keterangan,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),

            // Bottom row: timestamps
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.toReadable(log.timestamp),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
                if (isConfirmed && log.waktuReset != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle_outline,
                      size: 13, color: AppColors.safe),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.toShortTime(log.waktuReset!),
                    style: const TextStyle(
                        color: AppColors.safe, fontSize: 11),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.deviceId,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * index))
        .slideY(begin: 0.04, end: 0);
  }
}
