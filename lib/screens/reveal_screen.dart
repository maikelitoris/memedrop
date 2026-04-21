import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../data/meme_manifest.dart';
import '../models/meme.dart';
import '../models/meme_data.dart';
import '../services/collection_service.dart';
import '../services/drop_service.dart';
import '../widgets/meme_card_3d.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/rarity_edge_glow.dart';

class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({super.key});

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen>
    with TickerProviderStateMixin {
  MemeData? _resultMemeData;
  List<Rarity> _reel = [];
  bool _initialized = false;
  bool _landed = false;
  bool _showBlack = false;
  bool _showCard = false;
  bool _flipDone = false;
  bool _revealComplete = false;
  AddCardResult? _addResult;
  List<int> _unlockedSegments = [];
  int _acquiredAt = 0;
  String _typewriterText = '';
  bool _showEra = false;

  late ScrollController _scrollController;
  final double _tileWidth = 90.0;
  final int _resultIndex = 31;
  final Random _rng = Random();

  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  late AnimationController _levelUpController;
  late Animation<double> _levelUpAnim;
  late AnimationController _screenFlashController;

  static const _odds = [
    (Rarity.normie, '60%'),
    (Rarity.mid, '25%'),
    (Rarity.based, '10%'),
    (Rarity.dank, '4%'),
    (Rarity.sigma, '1%'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _flipDone = true);
        _startTypewriter();
      }
    });

    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _levelUpAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );

    _screenFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initReveal();
  }

  // Select from kMemeManifest directly — no JSON manifest involved
  MemeData _selectRandomMemeData() {
    final roll = _rng.nextDouble() * 100;
    final Rarity rarity;
    if (roll < 60) {
      rarity = Rarity.normie;
    } else if (roll < 85) {
      rarity = Rarity.mid;
    } else if (roll < 95) {
      rarity = Rarity.based;
    } else if (roll < 99) {
      rarity = Rarity.dank;
    } else {
      rarity = Rarity.sigma;
    }
    final pool = kMemeManifest.where((m) => m.rarity == rarity).toList();
    if (pool.isEmpty) return kFallbackMeme;
    return pool[_rng.nextInt(pool.length)];
  }

  Rarity _weightedRandomRarity() {
    final roll = _rng.nextDouble() * 100;
    if (roll < 60) return Rarity.normie;
    if (roll < 85) return Rarity.mid;
    if (roll < 95) return Rarity.based;
    if (roll < 99) return Rarity.dank;
    return Rarity.sigma;
  }

  void _initReveal() {
    final memeData = _selectRandomMemeData();
    setState(() {
      _resultMemeData = memeData;
      _reel = _generateReel(memeData.rarity);
      _acquiredAt = DateTime.now().toUtc().millisecondsSinceEpoch;
      _initialized = true;
    });
    _startSpin();
  }

  List<Rarity> _generateReel(Rarity resultRarity) {
    final reel = <Rarity>[];
    for (int i = 0; i < 29; i++) {
      reel.add(_weightedRandomRarity());
    }
    reel.add(Rarity.mid);    // index 29
    reel.add(Rarity.based);  // index 30
    reel.add(resultRarity);  // index 31 — winning tile, guaranteed match
    for (int i = 0; i < 5; i++) {
      reel.add(_weightedRandomRarity());
    }
    return reel;
  }

  void _startSpin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final targetOffset = (_resultIndex * _tileWidth) -
        (MediaQuery.of(context).size.width / 2) +
        (_tileWidth / 2);

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 5500),
      curve: const Cubic(0.05, 0.8, 0.15, 1.0),
    );

    if (!mounted) return;
    setState(() => _landed = true);

    try {
      final cs = await ref.read(collectionServiceProvider.future);
      if (cs.isHapticsEnabled()) {
        final rarity = _resultMemeData!.rarity;
        if (rarity == Rarity.dank || rarity == Rarity.sigma) {
          await HapticFeedback.heavyImpact();
        } else {
          await HapticFeedback.mediumImpact();
        }
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _showBlack = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await _autoStash();

    setState(() => _showCard = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _flipController.forward();
  }

  Future<void> _autoStash() async {
    final memeData = _resultMemeData;
    if (memeData == null) return;
    try {
      final cs = await ref.read(collectionServiceProvider.future);
      final result = await cs.addCardToGallery(memeData.toMeme());

      final ds = ref.read(dropServiceProvider);
      await ds.recordDropOpened(
        rarity: memeData.rarity.name,
        assetPath: memeData.assetPath,
        memeId: memeData.id,
      );
      await ds.markLastDropStashed();
      await ds.markDropAsOpened();

      final updatedItem = cs
          .getCollection()
          .where((i) => i.cardId == memeData.id)
          .firstOrNull;

      ref.invalidate(collectionServiceProvider);

      if (mounted) {
        setState(() {
          _addResult = result;
          _unlockedSegments = updatedItem?.unlockedLoreSegments ?? [];
        });
      }
    } catch (_) {}
  }

  void _startTypewriter() async {
    final memeData = _resultMemeData;
    if (memeData == null || memeData.isPlaceholder) {
      if (mounted) setState(() => _revealComplete = true);
      _triggerLevelUpAnimation();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));
    final name = memeData.name.toUpperCase();

    for (int i = 0; i <= name.length; i++) {
      if (!mounted) return;
      setState(() => _typewriterText = name.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 40));
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _showEra = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _revealComplete = true);
    _triggerLevelUpAnimation();
  }

  void _triggerLevelUpAnimation() {
    if (_addResult?.levelUp == true) {
      _levelUpController.forward().then((_) => _levelUpController.reverse());
      _screenFlashController.forward().then((_) => _screenFlashController.reverse());
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flipController.dispose();
    _levelUpController.dispose();
    _screenFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_showBlack) _buildReelScreen(),
          if (_showBlack) _buildRevealScreen(),
          if (!_showCard)
            AnimatedOpacity(
              opacity: _showBlack ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(color: Colors.black),
            ),
        ],
      ),
    );
  }

  Widget _buildReelScreen() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Odds pills above reel
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _odds.map((entry) {
                final (rarity, pct) = entry;
                final color = AppColors.forRarity(rarity);
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    '$pct ${rarity.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          // Reel strip
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reel.length,
                  itemBuilder: (context, index) {
                    final rarity = _reel[index];
                    final style = RarityColors.getReelStyle(rarity);
                    final isWinner = _landed && index == _resultIndex;

                    return AnimatedScale(
                      scale: isWinner ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _tileWidth - 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: style['bg'] as Color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: style['border'] as Color,
                            width: isWinner ? 3 : 2,
                          ),
                          boxShadow: [
                            if (style['glow'] != null)
                              BoxShadow(
                                color: (style['glow'] as Color).withValues(
                                    alpha: isWinner ? 0.8 : 0.5),
                                blurRadius: isWinner ? 32 : 16,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: (style['border'] as Color).withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Centre indicator line
              Container(
                width: 3,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'OPENING...',
            style: TextStyle(
              letterSpacing: 8,
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildRevealScreen() {
    return SafeArea(
      child: Stack(
        children: [
          // Screen flash for level-up
          if (_addResult?.levelUp == true)
            AnimatedBuilder(
              animation: _screenFlashController,
              builder: (_, __) => Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: const Color(0xFF00D4AA)
                        .withValues(alpha: 0.12 * _screenFlashController.value),
                  ),
                ),
              ),
            ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_resultMemeData != null)
                  RarityBadge(rarity: _resultMemeData!.rarity),
                const SizedBox(height: 16),

                if (_showCard && !_flipDone)
                  _buildFlipAnimation()
                else if (_flipDone && _resultMemeData != null)
                  RarityEdgeGlow(
                    rarity: _resultMemeData!.rarity,
                    child: MemeCard3D(
                      meme: _resultMemeData!,
                      acquiredAt: _acquiredAt,
                      viewOnly: true,
                      unlockedLoreSegments: _unlockedSegments,
                    ),
                  )
                else
                  const SizedBox(height: 400),

                const SizedBox(height: 20),

                if (_typewriterText.isNotEmpty)
                  Text(
                    _typewriterText,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                if (_showEra && _resultMemeData != null)
                  AnimatedOpacity(
                    opacity: _showEra ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _resultMemeData!.era,
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 2,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                if (_revealComplete) _buildStatusLabel(),

                const SizedBox(height: 32),

                if (_revealComplete)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 4,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipAnimation() {
    final memeData = _resultMemeData;
    if (memeData == null) return const SizedBox(height: 400);

    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (context, _) {
        final angle = _flipAnim.value;
        final showFront = angle >= pi / 2;
        final cardWidth = MediaQuery.of(context).size.width * 0.82;
        final rarityColor = AppColors.forRarity(memeData.rarity);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: showFront
              ? Transform(
                  transform: Matrix4.rotationY(pi),
                  alignment: Alignment.center,
                  child: _buildFrontCard(memeData, cardWidth, rarityColor),
                )
              : _buildQuestionBack(memeData, cardWidth, rarityColor),
        );
      },
    );
  }

  Widget _buildQuestionBack(MemeData memeData, double cardWidth, Color rarityColor) {
    return SizedBox(
      width: cardWidth,
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rarityColor.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: rarityColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(MemeData memeData, double cardWidth, Color rarityColor) {
    return SizedBox(
      width: cardWidth,
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rarityColor.withValues(alpha: 0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: memeData.isPlaceholder
                ? _buildPlaceholderFront(memeData)
                : Image.asset(memeData.assetPath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderFront(MemeData memeData) {
    final bgColor = AppColors.forRarity(memeData.rarity);
    return Container(
      color: bgColor.withValues(alpha: 0.3),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                memeData.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, letterSpacing: 2, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                memeData.era,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9, letterSpacing: 3, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLabel() {
    final result = _addResult;
    if (result == null) {
      return const Text(
        'STASHED',
        style: TextStyle(letterSpacing: 4, color: Colors.white54, fontSize: 11),
      );
    }

    if (result.isNew) {
      return const Text(
        'NEW CARD UNLOCKED',
        style: TextStyle(
          letterSpacing: 4,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
          fontSize: 11,
        ),
      );
    }

    if (result.maxLevel) {
      return Text(
        'ALREADY MAXED! +${result.coinsAwarded} COINS',
        style: const TextStyle(
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
          fontSize: 11,
        ),
      );
    }

    if (result.levelUp) {
      return AnimatedBuilder(
        animation: _levelUpAnim,
        builder: (_, __) => Transform.scale(
          scale: _levelUpAnim.value,
          child: Column(
            children: [
              const Text(
                'LEVEL UP',
                style: TextStyle(
                  letterSpacing: 4,
                  fontSize: 11,
                  color: Color(0xFF00D4AA),
                ),
              ),
              Text(
                'NOW LV ${result.newLevel}',
                style: const TextStyle(
                  letterSpacing: 3,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Text(
      'STASHED',
      style: TextStyle(letterSpacing: 4, color: Colors.white54, fontSize: 11),
    );
  }
}
