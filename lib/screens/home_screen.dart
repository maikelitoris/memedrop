import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/rotation_state.dart';
import '../services/drop_service.dart';
import '../services/streak_service.dart';
import '../services/collection_service.dart';
import '../widgets/sealed_container.dart';
import '../widgets/countdown_timer.dart';
import 'reveal_screen.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _canOpen = false;
  int _streak = 0;
  bool _activated = false;

  // Available container models (3D assets)
  static const List<String> _containerModels = [
    'brain',
    'pepe_compressed',
    '67',
    'lantern',
    'gigachad',
    'trollcube',
    'sus',
  ];
  String _selectedContainer = 'brain'; // default model, updated in _refresh()

  // Physics
  static const double _sphereSize = 160.0;
  static const double _maxThrowSpeed = 600.0;
  static const double _maxSpinDegPerSec = 360.0;
  static const double _minSpinDegPerSec = 20.0;
  static const double _idleSpinDegPerSec = 15.0; // Slow idle spin speed

  final _posNotifier = ValueNotifier(const Offset(80, 160));
  final _spinNotifier = ValueNotifier(const RotationState());
  Offset _vel = const Offset(90, 68);
  late Ticker _ticker;
  Duration? _lastTick;
  bool _posReady = false;

  // Spin state
  double _pitchDeg = 0.0;
  double _yawDeg = 0.0;
  Offset _spinAxis = const Offset(0.0, 1.0); // default: pure Y-axis idle (yaw)
  DateTime? _panStartTime;
  int _tickLogCount = 0;

  // Sphere centering + cancel-position animation (one-shot, reused)
  late AnimationController _centerCtrl;
  Animation<Offset>? _centerAnim;

  // Floating sine-wave while activated
  late AnimationController _floatCtrl;

  // Roulette + cancel button visibility
  late AnimationController _buttonCtrl;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = createTicker(_onTick)..start();

    _centerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _buttonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _buttonOpacity = _buttonCtrl;
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      _posNotifier.value = Offset(
        (size.width - _sphereSize) / 2,
        (size.height - _sphereSize) / 2,
      );
      _posReady = true;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _posNotifier.dispose();
    _spinNotifier.dispose();
    _centerCtrl.dispose();
    _floatCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  // ── Bounce + spin physics ────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (!_posReady) return;
    final prev = _lastTick;
    _lastTick = elapsed;
    if (prev == null) return;

    final dt = (elapsed - prev).inMicroseconds / 1e6;
    final size = MediaQuery.of(context).size;
    final maxX = size.width - _sphereSize;
    final maxY = size.height - _sphereSize;

    var pos = _posNotifier.value;
    var vx = _vel.dx;
    var vy = _vel.dy;

    var nx = pos.dx + vx * dt;
    var ny = pos.dy + vy * dt;

    if (nx <= 0) {
      nx = 0;
      vx = vx.abs();
    } else if (nx >= maxX) {
      nx = maxX;
      vx = -vx.abs();
    }
    if (ny <= 0) {
      ny = 0;
      vy = vy.abs();
    } else if (ny >= maxY) {
      ny = maxY;
      vy = -vy.abs();
    }

    const friction = 0.992;
    const minSpeed = 60.0;
    var newVel = Offset(vx * friction, vy * friction);
    final speed = newVel.distance;
    if (speed < minSpeed && speed > 0) {
      newVel = newVel / speed * minSpeed;
    }
    _vel = newVel;
    _posNotifier.value = Offset(nx, ny);

    // ── Spin: linked to linear velocity, axis lerps toward idle on decay ──
    final speedRatio = (_vel.distance / _maxThrowSpeed).clamp(0.0, 1.0);
    
    // Use idle spin speed when moving very slowly, otherwise interpolate
    final spinDeg = speedRatio < 0.01 
        ? _idleSpinDegPerSec 
        : _minSpinDegPerSec + speedRatio * (_maxSpinDegPerSec - _minSpinDegPerSec);

    // Quadratic ease: as brain slows, axis smoothly shifts to idle (0,1)=Y-yaw
    final lerpT = (1.0 - speedRatio) * (1.0 - speedRatio);
    var effX = _spinAxis.dx * (1.0 - lerpT);
    var effY = _spinAxis.dy * (1.0 - lerpT) + lerpT;
    final axisLen = sqrt(effX * effX + effY * effY);
    if (axisLen > 0) {
      effX /= axisLen;
      effY /= axisLen;
    }

    _pitchDeg += effX * spinDeg * dt;
    _yawDeg += effY * spinDeg * dt;
    
    // Normalize angles to prevent float precision drift over long sessions
    _pitchDeg = _pitchDeg % 360.0;
    _yawDeg = _yawDeg % 360.0;
    
    // Exponential decay on pitch toward 0 when nearly idle (fixes flicker/snap)
    if (speedRatio < 0.05) {
      const decayRate = 2.0; // radians per second
      _pitchDeg -= _pitchDeg * decayRate * dt;
    }
    
    _spinNotifier.value = RotationState(pitchDeg: _pitchDeg, yawDeg: _yawDeg);

    _tickLogCount++;
    if (_tickLogCount % 120 == 0) {
      debugPrint('[SPIN] tick#$_tickLogCount vel=${_vel.distance.toStringAsFixed(0)}px/s '
          'ratio=${speedRatio.toStringAsFixed(2)} '
          'pitch=${_pitchDeg.toStringAsFixed(1)} yaw=${_yawDeg.toStringAsFixed(1)}');
    }
  }

  // ── Data ────────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final dropService = ref.read(dropServiceProvider);
    final streakService = ref.read(streakServiceProvider);
    final collectionService = await ref.read(collectionServiceProvider.future);
    final canOpen = await dropService.canOpenDrop();
    final streak = await streakService.getCurrentStreak();
    final selectedContainer = collectionService.getSelectedContainer();
    if (mounted) {
      setState(() {
        _canOpen = canOpen;
        _streak = streak;
        _selectedContainer = selectedContainer;
      });
    }
  }

  // Long press hold state for opening
  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;
  static const Duration _holdDuration = Duration(milliseconds: 3000);

  void _onHoldStart() {
    if (!_canOpen || _activated || _isHolding) return;
    
    _isHolding = true;
    _holdProgress = 0.0;
    const updateInterval = Duration(milliseconds: 50);
    final steps = _holdDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    final increment = 1.0 / steps;
    
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(updateInterval, (timer) {
      if (_holdProgress >= 1.0) {
        timer.cancel();
        _isHolding = false;
        // Hold complete - set a flag to trigger the animation on next build
        setState(() {});
        // After UI updates, the SealedContainer will detect onOpen is set and can be triggered
      } else {
        _holdProgress += increment;
        setState(() {});
      }
    });
  }

  void _onHoldEnd() {
    _holdTimer?.cancel();
    _isHolding = false;
    if (_holdProgress < 1.0 && mounted) {
      // Reset progress if not completed
      setState(() {
        _holdProgress = 0.0;
      });
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  void _openReveal() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RevealScreen()))
        .then((_) {
      if (!mounted) return;
      _activated = false;
      _floatCtrl.stop();
      _floatCtrl.reset();
      _buttonCtrl.reset();
      _lastTick = null;
      if (!_ticker.isActive) _ticker.start();
      setState(() {});
      _refresh();
    });
  }

  // ── Drag / throw ────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails _) {
    _ticker.stop();
    _lastTick = null;
    _panStartTime = DateTime.now();
    debugPrint('[SPIN] panStart — ticker stopped');
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final maxX = size.width - _sphereSize;
    final maxY = size.height - _sphereSize;
    final next = _posNotifier.value + details.delta;
    _posNotifier.value = Offset(
      next.dx.clamp(0.0, maxX),
      next.dy.clamp(0.0, maxY),
    );
  }

  void _onPanEnd(DragEndDetails details) {
    var vel = details.velocity.pixelsPerSecond * 0.4;
    final rawSpeed = vel.distance;
    if (rawSpeed > _maxThrowSpeed) vel = vel / rawSpeed * _maxThrowSpeed;

    // Wind-up: longer hold → extra force (max 2.2× multiplier)
    if (_panStartTime != null) {
      final holdSecs =
          DateTime.now().difference(_panStartTime!).inMilliseconds / 1000.0;
      final windUp = 1.0 + (holdSecs * 0.6).clamp(0.0, 1.2);
      vel = vel * windUp;
      final ws = vel.distance;
      if (ws > _maxThrowSpeed) vel = vel / ws * _maxThrowSpeed;
      _panStartTime = null;
    }

    // Perpendicular axis: throw (vx, vy) → spin axis (-vy, vx) normalised
    // Horizontal throw → Y-axis spin (yaw); vertical throw → X-axis spin (pitch)
    // Diagonal throws create combined diagonal spin axes
    final throwSpeed = vel.distance;
    if (throwSpeed > 0) {
      _spinAxis = Offset(-vel.dy / throwSpeed, vel.dx / throwSpeed);
    } else {
      // If no throw velocity, default to Y-axis yaw spin
      _spinAxis = const Offset(0.0, 1.0);
    }

    _vel = vel;
    _lastTick = null;
    _ticker.start();
    debugPrint('[SPIN] panEnd rawSpeed=${rawSpeed.toStringAsFixed(0)} '
        'axis=(${_spinAxis.dx.toStringAsFixed(2)},${_spinAxis.dy.toStringAsFixed(2)}) '
        'finalVel=(${vel.dx.toStringAsFixed(0)},${vel.dy.toStringAsFixed(0)})');
  }

  // ── Double-tap activation ───────────────────────────────────────────────

  void _onDoubleTap() {
    setState(() { _activated = true; });
    _ticker.stop();
    _lastTick = null;

    final size = MediaQuery.of(context).size;
    final centerPos = Offset(
      (size.width - _sphereSize) / 2,
      (size.height - _sphereSize) / 2,
    );

    _centerAnim = Tween<Offset>(
      begin: _posNotifier.value,
      end: centerPos,
    ).animate(CurvedAnimation(parent: _centerCtrl, curve: Curves.easeOut));

    _centerCtrl.forward(from: 0).then((_) {
      if (!mounted || !_activated) return;
      _posNotifier.value = centerPos;
      _floatCtrl.repeat();
    });

    _buttonCtrl.forward();
  }

  // ── Cancel activation ───────────────────────────────────────────────────

  void _onCancel() {
    _floatCtrl.stop();
    _floatCtrl.reset();
    _buttonCtrl.animateTo(0, duration: const Duration(milliseconds: 300));

    final size = MediaQuery.of(context).size;
    final maxX = size.width - _sphereSize;
    final maxY = size.height - _sphereSize;
    final rng = Random();

    Offset randomPos;
    do {
      randomPos = Offset(
        rng.nextDouble() * maxX,
        rng.nextDouble() * maxY,
      );
    } while ((randomPos - Offset(maxX / 2, maxY / 2)).distance < 120);

    _centerAnim = Tween<Offset>(
      begin: _posNotifier.value,
      end: randomPos,
    ).animate(CurvedAnimation(parent: _centerCtrl, curve: Curves.easeOut));

    _centerCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      _posNotifier.value = randomPos;
      _vel = const Offset(90, 68);
      _lastTick = null;
      _ticker.start();
      setState(() { _activated = false; });
    });
  }

  // ── Display position ────────────────────────────────────────────────────

  Offset _computeDisplayPos(Size size) {
    if (!_activated) return _posNotifier.value;

    // During centering or cancel-position animation
    if (_centerCtrl.isAnimating) {
      return _centerAnim?.value ?? _posNotifier.value;
    }

    // Floating phase: gentle sine-wave around center
    final centerPos = Offset(
      (size.width - _sphereSize) / 2,
      (size.height - _sphereSize) / 2,
    );
    return centerPos + Offset(0, sin(_floatCtrl.value * 2 * pi) * 18.0);
  }

  // ── UI helpers ──────────────────────────────────────────────────────────

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SELECT CONTAINER',
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 3,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _containerModels.length,
              itemBuilder: (context, index) {
                final model = _containerModels[index];
                final isSelected = model == _selectedContainer;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedContainer = model;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accentBlue.withOpacity(0.3)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentBlue
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getModelIcon(model),
                          color: isSelected
                              ? AppColors.accentBlue
                              : Colors.white70,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getModelDisplayName(model),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _getModelIcon(String model) {
    switch (model) {
      case 'brain':
        return Icons.psychology;
      case 'pepe_compressed':
        return Icons.emoji_emotions;
      case '67':
        return Icons.looks_one;
      case 'lantern':
        return Icons.lightbulb;
      case 'gigachad':
        return Icons.fitness_center;
      case 'trollcube':
        return Icons.cube_outlined;
      case 'sus':
        return Icons.visibility;
      default:
        return Icons.box_container;
    }
  }

  String _getModelDisplayName(String model) {
    switch (model) {
      case 'brain':
        return 'Brain';
      case 'pepe_compressed':
        return 'Pepe';
      case '67':
        return '67';
      case 'lantern':
        return 'Lantern';
      case 'gigachad':
        return 'Gigachad';
      case 'trollcube':
        return 'Trollcube';
      case 'sus':
        return 'Sus';
      default:
        return model;
    }
  }

  Widget _buildTitle() {
    return const Text(
      AppStrings.appTitle,
      style: TextStyle(
        fontSize: 28,
        letterSpacing: 8,
        color: Colors.white,
        fontWeight: FontWeight.w100,
      ),
    );
  }

  Widget _buildStreakBadge() {
    if (_streak <= 1) return const SizedBox.shrink();
    return Text(
      _streak >= 7
          ? '⚡ $_streak DAY STREAK'
          : '🔥 $_streak DAY STREAK',
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 3,
        color: _streak >= 7
            ? AppColors.streakLegendary
            : AppColors.streakNormal,
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
      AnimatedBuilder(
        animation:
            Listenable.merge([_posNotifier, _centerCtrl, _floatCtrl, _buttonCtrl]),
        builder: (context, _) {
          final displayPos = _computeDisplayPos(size);
          
          // Build SealedContainer here so it rebuilds when _selectedContainer changes
          final sealedChild = SealedContainer(
            isReady: _canOpen || _activated, 
            spinNotifier: _spinNotifier,
            containerType: _selectedContainer,
            onOpen: _openReveal,
            triggerOpen: _holdProgress >= 1.0 && !_isHolding,
          );

          return Stack(
            children: [
              // ── Sphere ─────────────────────────────────────────────
              Positioned(
                left: displayPos.dx,
                top: displayPos.dy,
                width: _sphereSize,
                height: _sphereSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _activated ? null : (details) {
                    if (_canOpen && !_isHolding) {
                      _onHoldStart();
                    }
                  },
                  onTapUp: _activated ? null : (details) {
                    if (_canOpen && _isHolding) {
                      _onHoldEnd();
                    }
                  },
                  onTapCancel: _activated ? null : () {
                    if (_canOpen && _isHolding) {
                      _onHoldEnd();
                    }
                  },
                  onDoubleTap: _activated ? null : _onDoubleTap,
                  onPanStart: _activated ? null : _onPanStart,
                  onPanUpdate: _activated ? null : _onPanUpdate,
                  onPanEnd: _activated ? null : _onPanEnd,
                  child: IgnorePointer(
                    ignoring: _holdProgress > 0 && _holdProgress < 1.0,
                    child: sealedChild,
                  ),
                ),
              ),

              // ── Fixed UI overlay ────────────────────────────────────
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded,
                              color: Colors.white),
                          onPressed: () => _showModelSelector(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white),
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => const VaultScreen()))
                                  .then((_) => _refresh()),
                            ),
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) => const GalleryScreen()))
                                  .then((_) => _refresh()),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildStreakBadge(),
                    const Spacer(),
                    if (!_activated) ...[
                      Text(
                        'D R O P.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 5,
                          color: _canOpen ? Colors.white : Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _canOpen ? 'T A P  T O  O P E N' : 'S E A L E D',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 4,
                          color: _canOpen ? Colors.white60 : Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_canOpen) const CountdownTimer(),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
              // ── Roulette + Cancel — LAST so it renders on top ──────
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: FadeTransition(
                  opacity: _buttonOpacity,
                  child: SlideTransition(
                    position: _buttonSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTapDown: (_) => _onHoldStart(),
                          onTapUp: (_) => _onHoldEnd(),
                          onTapCancel: () => _onHoldEnd(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _canOpen ? Colors.white : Colors.white24,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Progress bar background
                                if (_holdProgress > 0)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: FractionallySizedBox(
                                      widthFactor: _holdProgress,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        height: double.infinity,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                // Text on top
                                Text(
                                  _holdProgress >= 1.0 
                                      ? 'O P E N I N G...'
                                      : 'H O L D  T O  O P E N',
                                  style: TextStyle(
                                    color: _canOpen ? Colors.white : Colors.white24,
                                    fontSize: 13,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _onCancel,
                          child: const Text(
                            '✕  cancel',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // DEBUG: confirm _activated setState reaches the build method
      if (_activated)
        const Center(
          child: IgnorePointer(
            child: Text(
              'ACTIVATED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
