// lib/core/widgets/agro_motion_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AgroMotionVariant {
  login,
  dashboard,
  minimal,
}

/// A state-of-the-art animated cyber-agro background for SawitGuard IoT.
/// Features glowing ambient plasma orbs, cybernetic telemetry grid,
/// and drifting IoT sensor mesh particles with zero rebuild overhead on children.
class AgroMotionBackground extends StatefulWidget {
  final Widget child;
  final AgroMotionVariant variant;
  final bool isIntrusionAlert;

  const AgroMotionBackground({
    super.key,
    required this.child,
    this.variant = AgroMotionVariant.dashboard,
    this.isIntrusionAlert = false,
  });

  @override
  State<AgroMotionBackground> createState() => _AgroMotionBackgroundState();
}

class _AgroMotionBackgroundState extends State<AgroMotionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SensorParticle> _particles;
  final math.Random _random = math.Random(42); // Deterministic seed for aesthetic balance

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final count = widget.variant == AgroMotionVariant.minimal ? 12 : 24;
    _particles = List.generate(count, (index) => _SensorParticle.random(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Static base gradient for battery efficiency & deep contrast
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF060B14), // Deep Obsidian Forest
                Color(0xFF09111F), // Tactical Navy Slate
                Color(0xFF050912), // Midnight Ground
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // 2. Animated Canvas: Dynamic Ambient Orbs, Mesh Grid, Radar Sweep & Particles
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _AgroMotionPainter(
                  progress: _controller.value,
                  particles: _particles,
                  variant: widget.variant,
                  isIntrusion: widget.isIntrusionAlert,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 3. Child Screen Content (rendered on top without being repainted by canvas)
        widget.child,
      ],
    );
  }
}

class _SensorParticle {
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  double vx; // Velocity X
  double vy; // Velocity Y
  double radius;
  double phase;
  double baseAlpha;

  _SensorParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.phase,
    required this.baseAlpha,
  });

  factory _SensorParticle.random(math.Random r) {
    return _SensorParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      vx: (r.nextDouble() - 0.5) * 0.04,
      vy: -0.015 - (r.nextDouble() * 0.035), // gentle upward drift like telemetry
      radius: 1.2 + r.nextDouble() * 2.2,
      phase: r.nextDouble() * math.pi * 2,
      baseAlpha: 0.25 + r.nextDouble() * 0.45,
    );
  }

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;

    // Wrap around boundaries smoothly
    if (x < -0.05) x = 1.05;
    if (x > 1.05) x = -0.05;
    if (y < -0.05) y = 1.05;
    if (y > 1.05) y = -0.05;
  }
}

class _AgroMotionPainter extends CustomPainter {
  final double progress;
  final List<_SensorParticle> particles;
  final AgroMotionVariant variant;
  final bool isIntrusion;

  _AgroMotionPainter({
    required this.progress,
    required this.particles,
    required this.variant,
    required this.isIntrusion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Time variables
    final t = progress * math.pi * 2;

    // ── 1. AMBIENT GLOW ORBS (Liquid Plasma Aurora) ──
    _drawAmbientOrbs(canvas, size, t);

    // ── 2. CYBERNETIC TELEMETRY GRID & RADAR RINGS ──
    if (variant != AgroMotionVariant.minimal) {
      _drawCyberGrid(canvas, size, t);
    }

    // ── 3. IOT SENSOR MESH PARTICLES & CONNECTIONS ──
    _drawParticlesAndMesh(canvas, size, t);
  }

  void _drawAmbientOrbs(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // Primary Emerald / Green Glow (or Crimson if intrusion)
    final primaryGlow = isIntrusion ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final secondaryGlow = isIntrusion ? const Color(0xFFF97316) : const Color(0xFF06B6D4);
    final tertiaryGlow = isIntrusion ? const Color(0xFF7F1D1D) : const Color(0xFFD97706);

    final orb1Radius = w * (variant == AgroMotionVariant.login ? 0.95 : 0.85);
    final orb1Center = Offset(
      w * 0.5 + math.sin(t) * (w * 0.15),
      h * 0.22 + math.cos(t * 0.7) * (h * 0.08),
    );

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlow.withValues(alpha: isIntrusion ? 0.22 : (variant == AgroMotionVariant.login ? 0.16 : 0.10)),
          primaryGlow.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, paint1);

    // Secondary Cyber Cyan / Teal Glow
    final orb2Radius = w * 0.8;
    final orb2Center = Offset(
      w * 0.2 + math.cos(t * 0.8) * (w * 0.12),
      h * 0.72 + math.sin(t * 0.9) * (h * 0.1),
    );

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryGlow.withValues(alpha: isIntrusion ? 0.16 : (variant == AgroMotionVariant.login ? 0.12 : 0.07)),
          secondaryGlow.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, paint2);

    // Tertiary Golden Palm / Energy Glow (Subtle accent)
    if (!isIntrusion) {
      final orb3Radius = w * 0.65;
      final orb3Center = Offset(
        w * 0.85 + math.sin(t * 0.6) * (w * 0.08),
        h * 0.48 + math.cos(t * 0.5) * (h * 0.09),
      );

      final paint3 = Paint()
        ..shader = RadialGradient(
          colors: [
            tertiaryGlow.withValues(alpha: 0.05),
            tertiaryGlow.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
      canvas.drawCircle(orb3Center, orb3Radius, paint3);
    }
  }

  void _drawCyberGrid(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    const gridSize = 48.0;

    // Draw horizontal tactical scanlines
    for (double y = 0; y <= h; y += gridSize) {
      // Fade out at extreme top and bottom
      final relY = (y / h - 0.5).abs() * 2.0; // 0 center, 1 edges
      final alpha = (1.0 - relY).clamp(0.0, 1.0) * 0.25;
      if (alpha > 0.02) {
        gridPaint.color = const Color(0xFF334155).withValues(alpha: alpha);
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    }

    // Draw vertical lines
    for (double x = 0; x <= w; x += gridSize) {
      final relX = (x / w - 0.5).abs() * 2.0;
      final alpha = (1.0 - relX).clamp(0.0, 1.0) * 0.18;
      if (alpha > 0.02) {
        gridPaint.color = const Color(0xFF334155).withValues(alpha: alpha);
        canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      }
    }

    // Concentric Radar Pulse Arcs (Command Center ambiance)
    final radarCenter = Offset(w * 0.5, h * (variant == AgroMotionVariant.login ? 0.22 : 0.35));
    final sweepProgress = (progress * 1.5) % 1.0;
    final sweepRadius = sweepProgress * (w * 1.1);

    final sweepPaint = Paint()
      ..color = (isIntrusion ? AppColors.danger : AppColors.safe)
          .withValues(alpha: (1.0 - sweepProgress) * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(radarCenter, sweepRadius, sweepPaint);
  }

  void _drawParticlesAndMesh(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // Update particles slightly
    const dt = 0.016; // ~60fps step
    for (final p in particles) {
      p.update(dt);
    }

    final pColor = isIntrusion ? AppColors.danger : AppColors.safe;

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    // Draw mesh connection lines between neighboring sensor nodes
    final maxDist = w * 0.26;
    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      final pos1 = Offset(p1.x * w, p1.y * h);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final pos2 = Offset(p2.x * w, p2.y * h);

        final dist = (pos1 - pos2).distance;
        if (dist < maxDist) {
          final lineAlpha = (1.0 - (dist / maxDist)) * 0.15;
          linePaint.color = pColor.withValues(alpha: lineAlpha);
          canvas.drawLine(pos1, pos2, linePaint);
        }
      }
    }

    // Draw sensor node points with breathing pulse
    for (final p in particles) {
      final pos = Offset(p.x * w, p.y * h);
      final pulse = (math.sin(t * 2.5 + p.phase) + 1.0) * 0.5; // 0.0 to 1.0
      final alpha = (p.baseAlpha * (0.6 + 0.4 * pulse)).clamp(0.05, 0.85);

      // Outer soft glow
      dotPaint.color = pColor.withValues(alpha: alpha * 0.35);
      canvas.drawCircle(pos, p.radius * 2.4, dotPaint);

      // Core point
      dotPaint.color = Colors.white.withValues(alpha: alpha * 0.85);
      canvas.drawCircle(pos, p.radius * 0.85, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AgroMotionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isIntrusion != isIntrusion ||
        oldDelegate.variant != variant;
  }
}
