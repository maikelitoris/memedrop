import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'rarity_badge.dart';
import '../models/rotation_state.dart';

class SealedContainer extends StatefulWidget {
  final bool isReady;
  final ValueNotifier<RotationState> spinNotifier;
  final String containerType; // e.g., 'brain', 'pepe_compressed'
  
  const SealedContainer({
    super.key, 
    required this.isReady, 
    required this.spinNotifier,
    this.containerType = 'brain',
  });

  @override
  State<SealedContainer> createState() => _SealedContainerState();
}

class _SealedContainerState extends State<SealedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  Future<void> Function(String)? _runJS;
  bool _pageReady = false;
  int _spinCallCount = 0;

  static const _glowColors = [
    RarityColors.normie,
    RarityColors.mid,
    RarityColors.based,
    RarityColors.dank,
    RarityColors.sigma,
  ];

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
    super.dispose();
  }

  void _onSpinChanged() {
    _spinCallCount++;
    final state = widget.spinNotifier.value;

    // Log every 60 calls (~1s at 60fps) to track pipeline health
    if (_spinCallCount % 60 == 0) {
      debugPrint('[SPIN] _onSpinChanged #$_spinCallCount '
          'pageReady=$_pageReady runJS=${_runJS != null} '
          'pitch=${state.pitchDeg.toStringAsFixed(1)} '
          'yaw=${state.yawDeg.toStringAsFixed(1)}');
    }

    if (!_pageReady || _runJS == null) return;

    // Throttle JS bridge to ~30fps (skip every other call)
    if (_spinCallCount % 2 != 0) return;

    // Use both theta (yaw) and phi (pitch) for full 3D rotation
    // theta=yaw controls horizontal rotation, phi=pitch controls vertical tilt
    // 2.5m distance ensures the full model stays in frame at all angles
    final yaw = state.yawDeg.toStringAsFixed(1);
    final pitch = state.pitchDeg.toStringAsFixed(1);
    unawaited(_runJS!(
      'try{'
      'var mv=document.querySelector("model-viewer");'
      'if(mv){'
      'mv.setAttribute("camera-orbit","${yaw}deg ${pitch}deg 2.5m");'
      'if(typeof mv.jumpCameraToGoal==="function")mv.jumpCameraToGoal();'
      '}'
      '}catch(e){console.warn("[SPIN] JS error:",e);}',
    ));
  }

  Color _lerpGlowColor(double t) {
    final scaled = t * (_glowColors.length - 1);
    final i = scaled.floor().clamp(0, _glowColors.length - 2);
    return Color.lerp(_glowColors[i], _glowColors[i + 1], scaled - i)!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  boxShadow: widget.isReady
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
              cameraOrbit: '0deg 0deg 2.5m', // Front view (0deg pitch = eye-level, straight-on)
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
    );
  }
}
