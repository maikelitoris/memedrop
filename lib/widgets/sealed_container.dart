import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'rarity_badge.dart';
import '../models/rotation_state.dart';

/// Per-model camera configuration to handle different GLB scales and bounding boxes.
/// Each model can define its own camera parameters for optimal viewing.
class ModelCameraConfig {
  final double basePitch; // Resting eye-level phi (default 90.0)
  final double pitchClampMin; // Minimum pitch angle (default 5.0)
  final double pitchClampMax; // Maximum pitch angle (default 175.0)
  final String cameraDistance; // The radius in camera-orbit (e.g., '2.5m')
  final String fieldOfView; // Field of view (e.g., '45deg')
  final String minCameraOrbit; // Minimum orbit constraint
  final String maxCameraOrbit; // Maximum orbit constraint
  final double glowIntensity; // Max glow intensity for brain animation

  const ModelCameraConfig({
    this.basePitch = 90.0,
    this.pitchClampMin = 5.0,
    this.pitchClampMax = 175.0,
    this.cameraDistance = '2.5m',
    this.fieldOfView = '45deg',
    this.minCameraOrbit = '0deg 0deg',
    this.maxCameraOrbit = '360deg 180deg',
    this.glowIntensity = 1.0,
  });
}

class SealedContainer extends StatefulWidget {
  final bool isReady;
  final ValueNotifier<RotationState> spinNotifier;
  final String containerType; // e.g., 'brain', 'pepe_compressed'
  final VoidCallback? onOpen; // Callback when open animation completes
  
  const SealedContainer({
    super.key, 
    required this.isReady, 
    required this.spinNotifier,
    this.containerType = 'brain',
    this.onOpen,
  });

  @override
  State<SealedContainer> createState() => _SealedContainerState();
}

class _SealedContainerState extends State<SealedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  
  // Animation controller for open sequence
  late AnimationController _openAnimCtrl;
  late Animation<double> _openAnim;

  Future<void> Function(String)? _runJS;
  bool _pageReady = false;
  int _spinCallCount = 0;
  
  // Track last applied values to prevent redundant JS calls (fixes flicker)
  double? _lastAppliedYaw;
  double? _lastAppliedPitch;
  
  // Track animation state
  bool _isOpening = false;

  static const _glowColors = [
    RarityColors.normie,
    RarityColors.mid,
    RarityColors.based,
    RarityColors.dank,
    RarityColors.sigma,
  ];

  /// Per-model camera configurations - add new models here without changing logic
  static const Map<String, ModelCameraConfig> _modelConfigs = {
    'brain': ModelCameraConfig(
      basePitch: 90.0,
      pitchClampMin: 50.0,
      pitchClampMax: 130.0,
      cameraDistance: '5.0m',
      fieldOfView: '30deg',
      glowIntensity: 2.5, // Intense glow for flash animation
    ),
    'pepe_compressed': ModelCameraConfig(
      basePitch: 90.0,
      pitchClampMin: 60.0,
      pitchClampMax: 120.0,
      cameraDistance: '5.5m',
      fieldOfView: '28deg',
      glowIntensity: 1.0,
    ),
  };

  /// Get config for a model, with safe fallback defaults if key is missing
  ModelCameraConfig _getConfig(String modelKey) {
    return _modelConfigs[modelKey] ?? const ModelCameraConfig();
  }

  // relatedJs runs inside the WebView once the HTML is parsed.
  // It listens for model-viewer's own 'load' event (fires when the GLB is
  // fully loaded and rendered) and signals Flutter via FlutterBridge.
  static const _bridgeJs = '''
    (function() {
      function signalReady() {
        try { window.FlutterBridge.postMessage('modelReady'); } catch(e) {}
      }
      function attachListener() {
        var mv = document.querySelector('model-viewer');
        if (mv) {
          mv.addEventListener('load', signalReady);
        }
      }
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', attachListener);
      } else {
        attachListener();
      }
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    
    // Setup open animation controller
    _openAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _openAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _openAnimCtrl, curve: Curves.easeInOut),
    );
    
    widget.spinNotifier.addListener(_onSpinChanged);
  }

  @override
  void didUpdateWidget(SealedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spinNotifier != widget.spinNotifier) {
      oldWidget.spinNotifier.removeListener(_onSpinChanged);
      widget.spinNotifier.addListener(_onSpinChanged);
    }
    // Reset pageReady when containerType changes so the new model must signal ready again
    if (oldWidget.containerType != widget.containerType) {
      _pageReady = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.spinNotifier.removeListener(_onSpinChanged);
    _glowCtrl.dispose();
    _openAnimCtrl.dispose();
    super.dispose();
  }

  void _onSpinChanged() {
    _spinCallCount++;
    final state = widget.spinNotifier.value;

    // Get per-model configuration
    final config = _getConfig(widget.containerType);

    // Use sine-based oscillation for natural pitch movement (fixes drift and hard clamping)
    // This maps accumulated _pitchDeg to a smooth oscillation between fixed bounds
    // Increased amplitude from 40 to 60 for more dramatic vertical rotation
    final pitchOscillation = math.sin(state.pitchDeg * math.pi / 180.0) * 60.0;
    double displayPitch = config.basePitch + pitchOscillation;
    
    // Apply soft clamping to stay within model-specific bounds
    displayPitch = displayPitch.clamp(config.pitchClampMin, config.pitchClampMax);
    
    // Normalize yaw for clean rotation
    double normalizedYaw = state.yawDeg % 360.0;

    // Log every 60 calls (~1s at 60fps) to track pipeline health
    if (_spinCallCount % 60 == 0) {
      debugPrint('[SPIN] _onSpinChanged #$_spinCallCount '
          'pageReady=$_pageReady runJS=${_runJS != null} '
          'pitch=${displayPitch.toStringAsFixed(1)} '
          'yaw=${normalizedYaw.toStringAsFixed(1)}');
    }

    if (!_pageReady || _runJS == null) return;

    final yaw = normalizedYaw.toStringAsFixed(1);
    final pitch = displayPitch.toStringAsFixed(1);
    
    // Prevent redundant JS calls when values haven't changed significantly (fixes flicker)
    const tolerance = 2.0;
    if (_lastAppliedYaw != null && _lastAppliedPitch != null &&
        (normalizedYaw - _lastAppliedYaw!).abs() < tolerance &&
        (displayPitch - _lastAppliedPitch!).abs() < tolerance) {
      return;
    }
    
    _lastAppliedYaw = normalizedYaw;
    _lastAppliedPitch = displayPitch;
    
    unawaited(_runJS!(
      'var mv=document.querySelector("model-viewer");'
      'if(mv){mv.setAttribute("camera-orbit","${yaw}deg ${pitch}deg ${config.cameraDistance}");}',
    ));
  }

  Color _lerpGlowColor(double t) {
    final scaled = t * (_glowColors.length - 1);
    final i = scaled.floor().clamp(0, _glowColors.length - 2);
    return Color.lerp(_glowColors[i], _glowColors[i + 1], scaled - i)!;
  }

  /// Handle tap to open the sealed container with model-specific animations
  void _handleTap() {
    if (_isOpening || !widget.isReady) return;
    _isOpening = true;
    
    // Stop the glow animation
    _glowCtrl.stop();
    
    // Trigger parent callback to start navigation
    // The actual navigation happens after animation completes
    if (widget.containerType == 'pepe_compressed') {
      _playPepeOpenAnimation();
    } else if (widget.containerType == 'brain') {
      _playBrainOpenAnimation();
    }
  }

  /// Pepe animation: Camera dives from front view to top view and zooms in until screen goes black
  void _playPepeOpenAnimation() {
    final config = _getConfig('pepe_compressed');
    final startTime = DateTime.now().millisecondsSinceEpoch;
    const duration = 1500; // ms
    
    void animateStep() {
      if (!_isOpening) return;
      
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      final t = (elapsed / duration).clamp(0.0, 1.0);
      // Ease-in-back curve for dramatic dive effect
      final curveT = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
      
      // Get current pitch from state
      final currentState = widget.spinNotifier.value;
      final currentPitch = config.basePitch + math.sin(currentState.pitchDeg * math.pi / 180.0) * 60.0;
      
      // Interpolate pitch from current to 0 (top view, looking straight down)
      final targetPitch = 0.0;
      final interpPitch = currentPitch + (targetPitch - currentPitch) * curveT;
      
      // Interpolate distance from current to very close (dive inside)
      final startDist = double.parse(config.cameraDistance.replaceAll('m', ''));
      final targetDist = 0.5; // Very close = black screen
      final interpDist = startDist + (targetDist - startDist) * curveT;
      
      // Apply camera orbit
      if (_runJS != null) {
        unawaited(_runJS!(
          'var mv=document.querySelector("model-viewer");'
          'if(mv){mv.setAttribute("camera-orbit","0deg ${interpPitch.toStringAsFixed(1)}deg ${interpDist.toStringAsFixed(2)}m");}',
        ));
      }
      
      if (t < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), animateStep);
      } else {
        // Animation complete - screen should be black inside the model
        // Signal parent to navigate to roulette
        _finishOpenSequence();
      }
    }
    
    animateStep();
  }

  /// Brain animation: Intensify glow until screen flashes white
  void _playBrainOpenAnimation() {
    final config = _getConfig('brain');
    final startTime = DateTime.now().millisecondsSinceEpoch;
    const duration = 1500; // ms
    
    void animateStep() {
      if (!_isOpening) return;
      
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      final t = (elapsed / duration).clamp(0.0, 1.0);
      
      // Update glow intensity - ramp up to maximum
      setState(() {
        // We'll use a local animation value for the intensifying glow
        // The existing _glowAnim will continue but we can overlay extra intensity
      });
      
      if (t < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), animateStep);
      } else {
        // Flash white
        _triggerWhiteFlash();
      }
    }
    
    animateStep();
  }

  /// Create a white flash overlay that fades in and out
  void _triggerWhiteFlash() {
    // Use OverlayEntry or a full-screen dialog for the flash
    final overlay = Overlay.of(context);
    final flashOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
      ),
    );
    
    overlay.insert(flashOverlay);
    
    // Fade out the flash after a brief moment
    Future.delayed(const Duration(milliseconds: 300), () {
      flashOverlay.remove();
      _finishOpenSequence();
    });
  }

  /// Complete the open sequence and signal parent to navigate
  void _finishOpenSequence() {
    // Small delay to ensure visual completion before navigation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && context.mounted) {
        // Call the parent callback if provided
        widget.onOpen?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow layer — separate from PlatformView to avoid composition artifacts
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) {
                final t = _glowAnim.value;
                final color = _lerpGlowColor(t);
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: widget.isReady && !_isOpening
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.38 + t * 0.28),
                              blurRadius: 50 + t * 22,
                              spreadRadius: 6 + t * 6,
                            ),
                          ]
                        : const [],
                  ),
                );
              },
            ),

            // ModelViewer — stable child, never rebuilt after first creation
            SizedBox(
              width: 160,
              height: 160,
              child: ModelViewer(
                key: ValueKey(widget.containerType), // Force rebuild on container change
                src: 'assets/models/${widget.containerType}.glb',
                backgroundColor: Colors.transparent,
                autoRotate: false,
                cameraControls: false,
                disableZoom: true,
                touchAction: TouchAction.none,
                interactionPrompt: InteractionPrompt.none,
                // Use per-model config for initial camera orbit and field of view
                cameraOrbit: '0deg 90deg ${_getConfig(widget.containerType).cameraDistance}',
                fieldOfView: _getConfig(widget.containerType).fieldOfView,
                minCameraOrbit: '${_getConfig(widget.containerType).minCameraOrbit}',
                maxCameraOrbit: '${_getConfig(widget.containerType).maxCameraOrbit}',
                // Signal Flutter when the GLB model has fully loaded
                relatedJs: _bridgeJs,
                javascriptChannels: {
                  JavascriptChannel(
                    'FlutterBridge',
                    onMessageReceived: (msg) {
                      debugPrint('[SPIN] FlutterBridge: ${msg.message}');
                      if (msg.message == 'modelReady') {
                        _pageReady = true;
                        debugPrint('[SPIN] ✓ model loaded — JS rotation active');
                      }
                    },
                  ),
                },
                onWebViewCreated: (controller) {
                  _runJS = controller.runJavaScript;
                  debugPrint('[SPIN] WebView created, runJS captured');
                },
              ),
            ),

            // Touch shield — keeps Flutter GestureDetector winning the arena
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
