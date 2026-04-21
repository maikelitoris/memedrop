import 'dart:ui';
import 'package:flutter/material.dart';

class LoreSegment extends StatelessWidget {
  final String title;
  final String content;
  final bool isLocked;
  final int unlockLevel;

  const LoreSegment({
    super.key,
    required this.title,
    required this.content,
    required this.isLocked,
    this.unlockLevel = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 8,
              letterSpacing: 3,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  content.isEmpty ? '—' : content,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFAAAAAA),
                    height: 1.55,
                  ),
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: Colors.black.withOpacity(0.60),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF444444),
                                size: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LV $unlockLevel TO UNLOCK',
                                style: const TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 2,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
