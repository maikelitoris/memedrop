import 'dart:math';
import 'package:flutter/material.dart';

class FanfareParticle {
  final Offset initialVelocity;
  final double radius;
  final Color color;

  const FanfareParticle({
    required this.initialVelocity,
    required this.radius,
    required this.color,
  });
}

class FanfarePainter extends CustomPainter {
  final double progress;
  final List<FanfareParticle> particles;
  final Offset origin;

  const FanfarePainter({
    required this.progress,
    required this.particles,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gravity = 280.0;
    final t = progress * 1.2;

    for (final p in particles) {
      final x = origin.dx + p.initialVelocity.dx * t;
      final y = origin.dy + p.initialVelocity.dy * t + 0.5 * gravity * t * t;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(FanfarePainter old) => old.progress != progress;
}

List<FanfareParticle> generateLegendaryParticles(int count) {
  final random = Random(42);
  return List.generate(count, (i) {
    final angle = (2 * pi * i / count) + random.nextDouble() * 0.6;
    final speed = 80.0 + random.nextDouble() * 220.0;
    const colors = [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFEC8B)];
    return FanfareParticle(
      initialVelocity: Offset(
        cos(angle) * speed,
        sin(angle) * speed - 140,
      ),
      radius: 2.5 + random.nextDouble() * 3.5,
      color: colors[i % colors.length],
    );
  });
}
