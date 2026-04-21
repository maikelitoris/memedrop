import 'package:flutter/material.dart';
import '../models/meme.dart';
import '../constants.dart';

class RarityEdgeGlow extends StatefulWidget {
  final Rarity rarity;
  final Widget child;

  const RarityEdgeGlow({
    super.key,
    required this.rarity,
    required this.child,
  });

  @override
  State<RarityEdgeGlow> createState() => _RarityEdgeGlowState();
}

class _RarityEdgeGlowState extends State<RarityEdgeGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  bool get _isSigma => widget.rarity == Rarity.sigma;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(
      begin: _isSigma ? 0.20 : 0.12,
      end: _isSigma ? 0.35 : 0.22,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRarity(widget.rarity);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _opacityAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _EdgeGlowPainter(
                    color: color,
                    opacity: _opacityAnim.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _EdgeGlowPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final c = color.withOpacity(opacity);
    const topH = 120.0;
    const sideW = 80.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, topH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c, Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, topH)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - topH, size.width, topH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [c, Colors.transparent],
        ).createShader(
            Rect.fromLTWH(0, size.height - topH, size.width, topH)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, sideW, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [c, Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, sideW, size.height)),
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width - sideW, 0, sideW, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [c, Colors.transparent],
        ).createShader(
            Rect.fromLTWH(size.width - sideW, 0, sideW, size.height)),
    );
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter old) =>
      old.opacity != opacity || old.color != color;
}
