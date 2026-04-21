import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/collection_service.dart';

class CRTOverlay extends ConsumerWidget {
  const CRTOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionServiceAsync = ref.watch(collectionServiceProvider);

    return collectionServiceAsync.when(
      data: (service) {
        if (!service.isCrtEnabled()) return const SizedBox.shrink();

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ScanlinePainter(),
                ),
              ),
              const FlickerOverlay(),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlickerOverlay extends StatefulWidget {
  const FlickerOverlay({super.key});

  @override
  State<FlickerOverlay> createState() => _FlickerOverlayState();
}

class _FlickerOverlayState extends State<FlickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 0.03).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          color: Colors.white.withValues(alpha: _animation.value),
        );
      },
    );
  }
}
