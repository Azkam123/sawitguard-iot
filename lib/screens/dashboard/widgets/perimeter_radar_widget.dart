// lib/screens/dashboard/widgets/perimeter_radar_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/device_model.dart';

class PerimeterRadarWidget extends StatefulWidget {
  final List<DeviceModel> devices;
  final ValueChanged<DeviceModel>? onNodeSelected;

  const PerimeterRadarWidget({
    super.key,
    required this.devices,
    this.onNodeSelected,
  });

  @override
  State<PerimeterRadarWidget> createState() => _PerimeterRadarWidgetState();
}

class _PerimeterRadarWidgetState extends State<PerimeterRadarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  DeviceModel? _findNode(String direction) {
    try {
      return widget.devices.firstWhere(
        (d) => d.directionName.toLowerCase() == direction.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final utaraNode = _findNode('Utara');
    final selatanNode = _findNode('Selatan');
    final timurNode = _findNode('Timur');
    final baratNode = _findNode('Barat');

    final bool hasIntrusion = widget.devices.any((d) => d.isIntrusi);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasIntrusion
              ? AppColors.danger.withAlpha(140)
              : Colors.white.withValues(alpha: 0.09),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasIntrusion
                ? AppColors.danger.withAlpha(40)
                : Colors.black.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasIntrusion
                            ? AppColors.danger.withAlpha(40)
                            : AppColors.safe.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        color: hasIntrusion ? AppColors.danger : AppColors.safe,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Radar Perimeter Kebun',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            hasIntrusion
                                ? 'Peringatan: Anomali!'
                                : '4 Penjuru Mata Angin',
                            style: TextStyle(
                              color: hasIntrusion
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasIntrusion
                      ? AppColors.danger.withAlpha(30)
                      : AppColors.safe.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasIntrusion
                        ? AppColors.danger.withAlpha(100)
                        : AppColors.safe.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: hasIntrusion ? AppColors.danger : AppColors.safe,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasIntrusion ? 'INTRUSI' : 'ONLINE',
                      style: TextStyle(
                        color: hasIntrusion ? AppColors.danger : AppColors.safe,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Radar Circle with Compass Nodes
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar Rings Custom Paint
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(230, 230),
                      painter: _RadarBackgroundPainter(
                        animationValue: _pulseController.value,
                        hasIntrusion: hasIntrusion,
                      ),
                    );
                  },
                ),

                // Center Core (Pusat Kebun Sawit)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F172A),
                    border: Border.all(
                      color: AppColors.safe.withAlpha(120),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safe.withAlpha(60),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.park_rounded,
                      color: AppColors.safe,
                      size: 26,
                    ),
                  ),
                ),

                // Node UTARA (Atas)
                Positioned(
                  top: 4,
                  child: _buildNodeBadge(
                    node: utaraNode,
                    label: 'U',
                    direction: 'Utara',
                  ),
                ),

                // Node SELATAN (Bawah)
                Positioned(
                  bottom: 4,
                  child: _buildNodeBadge(
                    node: selatanNode,
                    label: 'S',
                    direction: 'Selatan',
                  ),
                ),

                // Node BARAT (Kiri)
                Positioned(
                  left: 4,
                  child: _buildNodeBadge(
                    node: baratNode,
                    label: 'B',
                    direction: 'Barat',
                  ),
                ),

                // Node TIMUR (Kanan)
                Positioned(
                  right: 4,
                  child: _buildNodeBadge(
                    node: timurNode,
                    label: 'T',
                    direction: 'Timur',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Legend Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Utara', utaraNode?.isIntrusi ?? false),
              _buildLegendItem('Selatan', selatanNode?.isIntrusi ?? false),
              _buildLegendItem('Timur', timurNode?.isIntrusi ?? false),
              _buildLegendItem('Barat', baratNode?.isIntrusi ?? false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeBadge({
    required DeviceModel? node,
    required String label,
    required String direction,
  }) {
    final bool isIntruded = node?.isIntrusi ?? false;
    final Color color = isIntruded ? AppColors.danger : AppColors.safe;

    return GestureDetector(
      onTap: () {
        if (node != null && widget.onNodeSelected != null) {
          widget.onNodeSelected!(node);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(isIntruded ? 255 : 140),
            width: isIntruded ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isIntruded ? 90 : 35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  direction,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  isIntruded ? 'INTRUSI' : 'AMAN',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, bool isIntruded) {
    final color = isIntruded ? AppColors.danger : AppColors.safe;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(120),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: isIntruded ? AppColors.danger : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool hasIntrusion;

  _RadarBackgroundPainter({
    required this.animationValue,
    required this.hasIntrusion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 12;

    final primaryColor = hasIntrusion ? AppColors.danger : AppColors.safe;

    // Draw Static Grid Rings
    final ringPaint = Paint()
      ..color = primaryColor.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), ringPaint);
    }

    // Crosshairs
    final crossPaint = Paint()
      ..color = primaryColor.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
        Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius),
        crossPaint);
    canvas.drawLine(
        Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy),
        crossPaint);

    // Animated Pulse Wave
    final pulseRadius = maxRadius * animationValue;
    final pulsePaint = Paint()
      ..color = primaryColor.withAlpha(((1.0 - animationValue) * 70).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Sweeping Radar Beam Angle
    final sweepAngle = animationValue * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          primaryColor.withAlpha(hasIntrusion ? 70 : 45),
          Colors.transparent,
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hasIntrusion != hasIntrusion;
  }
}
