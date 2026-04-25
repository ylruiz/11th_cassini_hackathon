import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_issue_scenario.dart';

class SimulationViewport extends StatefulWidget {
  const SimulationViewport({
    super.key,
    required this.issue,
    required this.accentColor,
  });

  final WaterIssueType issue;
  final Color accentColor;

  @override
  State<SimulationViewport> createState() => _SimulationViewportState();
}

class _SimulationViewportState extends State<SimulationViewport>
    with TickerProviderStateMixin {
  late AnimationController _ambient;
  late AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambient, _progress]),
      builder: (context, _) {
        return Container(
          height: 185,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SizedBox.expand(
                child: CustomPaint(
                  painter: _ScenePainter(
                    issue: widget.issue,
                    ambient: _ambient.value,
                    progress: _progress.value,
                    accent: widget.accentColor,
                  ),
                ),
              ),
              _SceneOverlay(
                issue: widget.issue,
                accent: widget.accentColor,
                progress: _progress.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.issue,
    required this.ambient,
    required this.progress,
    required this.accent,
  });

  final WaterIssueType issue;
  final double ambient;
  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    switch (issue) {
      case WaterIssueType.pollution:
        _paintPollution(canvas, size);
      case WaterIssueType.flooding:
        _paintFlooding(canvas, size);
      case WaterIssueType.drought:
        _paintDrought(canvas, size);
      case WaterIssueType.heatStress:
        _paintHeatStress(canvas, size);
    }
  }

  // ── Pollution ──────────────────────────────────────────────────────────────

  void _paintPollution(Canvas canvas, Size size) {
    _fillGrad(canvas, Rect.fromLTWH(0, 0, size.width, size.height),
        const Color(0xFF04111E), const Color(0xFF071828));

    final bankH = size.height * 0.22;
    _fillGrad(canvas, Rect.fromLTWH(0, 0, size.width, bankH),
        const Color(0xFF0F2A12), const Color(0xFF0A1C0C));
    _fillGrad(
        canvas,
        Rect.fromLTWH(0, size.height - bankH, size.width, bankH),
        const Color(0xFF0A1C0C),
        const Color(0xFF0F2A12));

    final riverRect =
        Rect.fromLTWH(0, bankH, size.width, size.height - bankH * 2);
    _fillGrad(canvas, riverRect, const Color(0xFF0D3A5C), const Color(0xFF061A2E));

    // Flow lines
    final flowPaint = Paint()
      ..color = const Color(0xFF1A6A9A).withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final y = riverRect.top + riverRect.height * (i + 1) / 5;
      final offset = (ambient * size.width * 0.4) % 60;
      for (double x = -offset; x < size.width + 60; x += 60) {
        canvas.drawLine(Offset(x, y), Offset(x + 30, y), flowPaint);
      }
    }

    // Contamination plume
    final spread = math.min(progress * 1.3, 1.0);
    final plumeW = size.width * 0.15 + size.width * 0.5 * spread;
    final plumeCenter = Offset(plumeW * 0.5, riverRect.center.dy);
    final plumePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.orangeAccent.withValues(alpha: 0.65),
          Colors.orange.withValues(alpha: 0.30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: plumeCenter, radius: plumeW * 0.7));
    canvas.drawOval(
      Rect.fromCenter(center: plumeCenter, width: plumeW * 1.1, height: riverRect.height * 0.75),
      plumePaint,
    );

    // Toxic particles
    final rand = math.Random(42);
    final particlePaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.7);
    for (int i = 0; i < 14; i++) {
      final seed = i / 14.0;
      final px = ((seed + ambient * 0.25) % 1.0) * plumeW;
      final wave = math.sin(seed * math.pi * 3 + ambient * math.pi * 2);
      final py = riverRect.top +
          riverRect.height * 0.15 +
          (0.35 + wave * 0.25) * riverRect.height * 0.7;
      canvas.drawCircle(Offset(px, py), 1.5 + rand.nextDouble() * 2.5, particlePaint);
    }
  }

  // ── Flooding ───────────────────────────────────────────────────────────────

  void _paintFlooding(Canvas canvas, Size size) {
    _fillGrad(canvas, Rect.fromLTWH(0, 0, size.width, size.height),
        const Color(0xFF060F1A), const Color(0xFF0A1828));

    // Hills
    final hillPaint = Paint()..color = const Color(0xFF0A2010);
    final hill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.30,
          size.width * 0.30, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.60,
          size.width * 0.55, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.70, size.height * 0.18,
          size.width * 0.80, size.height * 0.40)
      ..quadraticBezierTo(size.width * 0.90, size.height * 0.55,
          size.width, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, hillPaint);

    // Rising water
    final waterLevel = size.height * (0.30 + progress * 0.45);
    final waterRect = Rect.fromLTWH(0, size.height - waterLevel, size.width, waterLevel);
    _fillGrad(canvas, waterRect,
        const Color(0xFF0A3C6E).withValues(alpha: 0.92), const Color(0xFF051428));

    // Waves on surface
    final wavePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final wave1 = Path()..moveTo(0, size.height - waterLevel);
    for (double x = 0; x <= size.width; x++) {
      wave1.lineTo(
          x,
          size.height -
              waterLevel +
              math.sin((x / size.width * math.pi * 4) + ambient * math.pi * 2) * 4);
    }
    canvas.drawPath(wave1, wavePaint);

    final wave2Paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final wave2 = Path()..moveTo(0, size.height - waterLevel + 8);
    for (double x = 0; x <= size.width; x++) {
      wave2.lineTo(
          x,
          size.height -
              waterLevel +
              8 +
              math.sin((x / size.width * math.pi * 5) + ambient * math.pi * 2 + 1.2) * 3);
    }
    canvas.drawPath(wave2, wave2Paint);

    // Debris dots
    final rand = math.Random(17);
    final debrisPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    for (int i = 0; i < 10; i++) {
      final seed = i / 10.0;
      final px = ((seed + ambient * 0.12) % 1.0) * size.width;
      final py = size.height - waterLevel + 10 + rand.nextDouble() * (waterLevel * 0.3);
      canvas.drawCircle(Offset(px, py), 2.0, debrisPaint);
    }
  }

  // ── Drought ────────────────────────────────────────────────────────────────

  void _paintDrought(Canvas canvas, Size size) {
    _fillGrad(canvas, Rect.fromLTWH(0, 0, size.width, size.height),
        const Color(0xFF1A0E04), const Color(0xFF271408));

    // Cracked earth
    final earthPaint = Paint()..color = const Color(0xFF3D2010).withValues(alpha: 0.8);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65), earthPaint);

    final crackPaint = Paint()
      ..color = const Color(0xFF1A0A02).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cracks = [
      [0.10, 0.45, 0.22, 0.60, 0.18, 0.75],
      [0.35, 0.50, 0.50, 0.38, 0.60, 0.55],
      [0.65, 0.48, 0.78, 0.65, 0.85, 0.55],
      [0.20, 0.70, 0.38, 0.82, 0.30, 0.92],
      [0.55, 0.75, 0.70, 0.60, 0.80, 0.80],
      [0.05, 0.55, 0.15, 0.68],
      [0.45, 0.60, 0.55, 0.78, 0.48, 0.88],
    ];
    for (final c in cracks) {
      final p = Path()..moveTo(c[0] * size.width, c[1] * size.height);
      if (c.length == 6) {
        p.quadraticBezierTo(c[2] * size.width, c[3] * size.height,
            c[4] * size.width, c[5] * size.height);
      } else {
        p.lineTo(c[2] * size.width, c[3] * size.height);
      }
      canvas.drawPath(p, crackPaint);
    }

    // Shrinking pool
    final shrink = progress * 0.55;
    final poolRx = size.width * (0.28 - shrink * 0.18);
    final poolRy = size.height * (0.12 - shrink * 0.07);
    if (poolRx > 2 && poolRy > 2) {
      final center = Offset(size.width * 0.5, size.height * 0.22);
      final poolPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF1A6A9A).withValues(alpha: 0.9),
            const Color(0xFF0A3A5C).withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCenter(center: center, width: poolRx * 2, height: poolRy * 2));
      canvas.drawOval(
          Rect.fromCenter(center: center, width: poolRx * 2, height: poolRy * 2), poolPaint);
    }

    // Heat shimmer lines
    final shimmerPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final xBase = size.width * (0.1 + i * 0.15);
      final p = Path()..moveTo(xBase, size.height * 0.05);
      for (double dy = 0; dy < size.height * 0.28; dy += 2) {
        p.lineTo(
            xBase + math.sin(dy * 0.3 + ambient * math.pi * 2 + i * 0.7) * 4,
            size.height * 0.05 + dy);
      }
      canvas.drawPath(p, shimmerPaint);
    }
  }

  // ── Heat Stress ────────────────────────────────────────────────────────────

  void _paintHeatStress(Canvas canvas, Size size) {
    _fillGrad(canvas, Rect.fromLTWH(0, 0, size.width, size.height),
        const Color(0xFF0F0804), const Color(0xFF1A0C06));

    final bankH = size.height * 0.22;
    _fillGrad(canvas, Rect.fromLTWH(0, 0, size.width, bankH),
        const Color(0xFF1A1208), const Color(0xFF110C05));
    _fillGrad(canvas,
        Rect.fromLTWH(0, size.height - bankH, size.width, bankH),
        const Color(0xFF110C05), const Color(0xFF1A1208));

    final riverColor =
        Color.lerp(const Color(0xFF0D4A6E), const Color(0xFF4A1A0A), progress * 0.6)!;
    final riverRect =
        Rect.fromLTWH(0, bankH, size.width, size.height - bankH * 2);
    _fillGrad(canvas, riverRect, riverColor, riverColor.withValues(alpha: 0.8));

    // Heat shimmer above river
    final shimPaint = Paint()
      ..color = Colors.deepOrangeAccent.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final xBase = size.width * (0.05 + i * 0.12);
      final p = Path()..moveTo(xBase, riverRect.top - 2);
      for (double dy = 0; dy < bankH * 0.85; dy += 2) {
        p.lineTo(
            xBase + math.sin(dy * 0.25 + ambient * math.pi * 2 + i) * 5,
            riverRect.top - 2 - dy);
      }
      canvas.drawPath(p, shimPaint);
    }

    // Algae blooms
    final algaePaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.25 + progress * 0.2);
    final rand = math.Random(99);
    for (int i = 0; i < 8; i++) {
      final seed = i / 8.0;
      final px = size.width * (0.05 + seed * 0.85);
      final py = riverRect.center.dy +
          math.sin(seed * math.pi * 2) * riverRect.height * 0.25;
      canvas.drawCircle(
          Offset(px, py), 6 + rand.nextDouble() * 10 + progress * 8, algaePaint);
    }

    // Edge glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.transparent,
          Colors.deepOrangeAccent.withValues(alpha: progress * 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _fillGrad(Canvas canvas, Rect rect, Color top, Color bottom) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.ambient != ambient || old.progress != progress || old.issue != issue;
}

// ─── Overlay ──────────────────────────────────────────────────────────────────

class _SceneOverlay extends StatelessWidget {
  const _SceneOverlay({
    required this.issue,
    required this.accent,
    required this.progress,
  });

  final WaterIssueType issue;
  final Color accent;
  final double progress;

  String get _title => switch (issue) {
        WaterIssueType.pollution => 'CONTAMINATION SPREAD',
        WaterIssueType.flooding => 'FLOOD LEVEL RISING',
        WaterIssueType.drought => 'WATER DEPLETION',
        WaterIssueType.heatStress => 'THERMAL STRESS',
      };

  String get _source => switch (issue) {
        WaterIssueType.pollution => 'Nitrate plume · Copernicus Sentinel-2',
        WaterIssueType.flooding => 'Active inundation · Copernicus EMS',
        WaterIssueType.drought => 'Soil moisture deficit · C3S Climate',
        WaterIssueType.heatStress => 'River temperature · Sentinel-3',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _liveBadge(),
              const Spacer(),
              _severityBadge(),
            ],
          ),
          const Spacer(),
          Text(
            _title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              shadows: [const Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _source,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 10,
              shadows: [const Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE SIM',
            style: GoogleFonts.spaceGrotesk(
              color: accent,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityBadge() {
    final severity = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'SEVERITY  $severity%',
        style: GoogleFonts.spaceGrotesk(
          color: accent,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
