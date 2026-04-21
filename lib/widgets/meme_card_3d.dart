import 'dart:math' show pi, cos;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models/meme_data.dart';
import '../models/meme.dart';
import 'lore_segment.dart';

class MemeCard3D extends StatefulWidget {
  final MemeData meme;
  final int acquiredAt;
  final bool viewOnly;
  final List<int> unlockedLoreSegments;
  final VoidCallback? onFirstFlip;
  final bool initiallyFlipped;
  final Duration? autoFlipAfter;

  const MemeCard3D({
    super.key,
    required this.meme,
    required this.acquiredAt,
    required this.viewOnly,
    this.unlockedLoreSegments = const [],
    this.onFirstFlip,
    this.initiallyFlipped = false,
    this.autoFlipAfter,
  });

  @override
  State<MemeCard3D> createState() => _MemeCard3DState();
}

class _MemeCard3DState extends State<MemeCard3D> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  bool _isPanning = false;
  bool _hasFlippedOnce = false;

  double _dragX = 0.0;
  double _dragY = 0.0;

  late AnimationController _snapController;
  late Tween<double> _snapXTween;
  late Tween<double> _snapYTween;

  late AnimationController _glowController;

  static const double _maxTilt = 0.25;
  static const double _perspective = 0.0008;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.initiallyFlipped) {
      _isFlipped = true;
      _flipController.value = 1.0;
    }

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _snapXTween = Tween(begin: 0.0, end: 0.0);
    _snapYTween = Tween(begin: 0.0, end: 0.0);
    _snapController.addListener(() {
      setState(() {
        _dragX = _snapXTween.evaluate(_snapController);
        _dragY = _snapYTween.evaluate(_snapController);
      });
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.autoFlipAfter != null) {
      Future.delayed(widget.autoFlipAfter!, () {
        if (mounted) _flip();
      });
    }
  }

  void _flip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
      if (!_hasFlippedOnce) {
        _hasFlippedOnce = true;
        widget.onFirstFlip?.call();
      }
    }
    _isFlipped = !_isFlipped;
    HapticFeedback.lightImpact();
  }

  void _onPanStart(DragStartDetails _) {
    _snapController.stop();
    setState(() => _isPanning = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragX = (_dragX + d.delta.dx * 0.012).clamp(-_maxTilt, _maxTilt);
      _dragY = (_dragY - d.delta.dy * 0.012).clamp(-_maxTilt, _maxTilt);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _isPanning = false);
    _snapXTween = Tween(begin: _dragX, end: 0.0);
    _snapYTween = Tween(begin: _dragY, end: 0.0);
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.82;
    final rarityColor = AppColors.forRarity(widget.meme.rarity);

    return GestureDetector(
      onTap: _flip,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnim, _glowController]),
        builder: (context, _) {
          final totalYRotation = _dragX + (_flipAnim.value * pi);
          final showBack = cos(totalYRotation) < 0;

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateX(_dragY)
            ..rotateY(totalYRotation);

          final specX = (_dragX / _maxTilt + 1) / 2;
          final specY = (_dragY / _maxTilt + 1) / 2;

          double glowOpacity = 0;
          if (widget.meme.rarity == Rarity.sigma) {
            glowOpacity = 0.3 + (_glowController.value * 0.4);
          } else if (widget.meme.rarity == Rarity.dank) {
            glowOpacity = 0.2 + (_glowController.value * 0.3);
          }

          return Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: SizedBox(
              width: cardWidth,
              child: AspectRatio(
                aspectRatio: 2.5 / 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: _buildBorder(rarityColor),
                    boxShadow: _buildShadow(rarityColor, glowOpacity),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        showBack
                            ? Transform(
                                transform: Matrix4.rotationY(pi),
                                alignment: Alignment.center,
                                child: _buildBackFace(),
                              )
                            : _buildFrontFace(),
                        if (_isPanning)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment(
                                    specX * 2 - 1,
                                    specY * 2 - 1,
                                  ),
                                  radius: 0.8,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.10),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Border _buildBorder(Color rarityColor) {
    return Border.all(
      color: rarityColor.withValues(
        alpha: widget.meme.rarity == Rarity.normie ? 0.4 : 0.8,
      ),
      width: widget.meme.rarity == Rarity.sigma ? 2.0 : 1.5,
    );
  }

  List<BoxShadow> _buildShadow(Color rarityColor, double glowOpacity) {
    if (widget.meme.rarity == Rarity.normie) return [];
    final baseOpacity = {
      Rarity.mid: 0.4,
      Rarity.based: 0.5,
      Rarity.dank: 0.6,
      Rarity.sigma: glowOpacity,
    }[widget.meme.rarity] ??
        0.4;
    final blurRadius = {
      Rarity.mid: 10.0,
      Rarity.based: 14.0,
      Rarity.dank: 18.0,
      Rarity.sigma: 24.0,
    }[widget.meme.rarity] ??
        10.0;
    return [
      BoxShadow(
        color: rarityColor.withValues(alpha: baseOpacity),
        blurRadius: blurRadius,
        spreadRadius: 2,
      ),
    ];
  }

  Widget _buildFrontFace() {
    final meme = widget.meme;
    return Stack(
      children: [
        Positioned.fill(
          child: meme.isPlaceholder
              ? _buildPlaceholder()
              : Image.asset(meme.assetPath, fit: BoxFit.cover),
        ),
        if (!meme.isPlaceholder)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    meme.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.forRarity(meme.rarity),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final (bgColor, textColor) = switch (widget.meme.rarity) {
      Rarity.sigma => (const Color(0xFFFFD700), Colors.black),
      Rarity.dank => (const Color(0xFFFF7043), Colors.black),
      Rarity.based => (const Color(0xFFAB47BC), Colors.white),
      Rarity.mid => (const Color(0xFF4FC3F7), Colors.black),
      Rarity.normie => (const Color(0xFF2A2A2A), const Color(0xFF808080)),
    };

    return Container(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.meme.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.meme.era,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 3,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackFace() {
    final meme = widget.meme;
    final rarityColor = AppColors.forRarity(meme.rarity);
    final acquired = DateTime.fromMillisecondsSinceEpoch(
      widget.acquiredAt,
      isUtc: true,
    );
    final dateStr = '${acquired.month.toString().padLeft(2, '0')}.'
        '${acquired.day.toString().padLeft(2, '0')}.'
        '${(acquired.year % 100).toString().padLeft(2, '0')}';

    final segs = widget.unlockedLoreSegments;

    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top strip: rarity + era
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: rarityColor, width: 1),
                ),
                child: Text(
                  meme.rarity.name.toUpperCase(),
                  style: TextStyle(
                      fontSize: 7, letterSpacing: 3, color: rarityColor),
                ),
              ),
              Text(
                meme.era,
                style: const TextStyle(
                    fontSize: 7, letterSpacing: 2, color: Color(0xFF555555)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meme.name.toUpperCase(),
            style: const TextStyle(
                fontSize: 15,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 1,
            color: rarityColor.withValues(alpha: 0.4),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoreSegment(
                    title: 'ORIGIN',
                    content: meme.origin,
                    isLocked: !segs.contains(0),
                    unlockLevel: 2,
                  ),
                  LoreSegment(
                    title: 'LORE',
                    content: meme.lore,
                    isLocked: !segs.contains(1),
                    unlockLevel: 3,
                  ),
                  LoreSegment(
                    title: 'PEAK MOMENT',
                    content: meme.peakEvent,
                    isLocked: !segs.contains(2),
                    unlockLevel: 4,
                  ),
                  // Tags segment
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TAGS',
                          style: TextStyle(
                              fontSize: 8, letterSpacing: 3, color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: meme.tags
                                  .map((t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: rarityColor.withValues(alpha: 0.15),
                                          border: Border.all(
                                              color: rarityColor.withValues(alpha: 0.4),
                                              width: 1),
                                        ),
                                        child: Text(
                                          t.toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 7,
                                              letterSpacing: 2,
                                              color: rarityColor.withValues(alpha: 0.8)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            if (!segs.contains(3))
                              Positioned.fill(
                                child: AbsorbPointer(
                                  child: ClipRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.60),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.lock_outline,
                                                color: Color(0xFF444444), size: 18),
                                            SizedBox(height: 4),
                                            Text(
                                              'LV 5 TO UNLOCK',
                                              style: TextStyle(
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ACQUIRED $dateStr',
            style: const TextStyle(
                fontSize: 7, letterSpacing: 2, color: Color(0xFF3A3A3A)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _snapController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}
