import 'dart:async';
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

  const ModelCameraConfig({
    this.basePitch = 90.0,
    this.pitchClampMin = 5.0,
    this.pitchClampMax = 175.0,
    this.cameraDistance = '2.5m',
    this.fieldOfView = '45deg',
    this.minCameraOrbit = '0deg 0deg',
    this.maxCameraOrbit = '360deg 180deg',
  });
}

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
  
  // Track last applied values to prevent redundant JS calls (fixes flicker)
  double? _lastAppliedYaw;
  double? _lastAppliedPitch;

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
      pitchClampMin: 5.0,
      pitchClampMax: 175.0,
      cameraDistance: '2.8m',
      fieldOfView: '45deg',
    ),
    'pepe_compressed': ModelCameraConfig(
      basePitch: 90.0,
      pitchClampMin: 30.0,
      pitchClampMax: 150.0,
      cameraDistance: '3.5m',
      fieldOfView: '38deg',
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

    // Normalize angles to prevent float precision drift over long sessions
    // Using modulo 360 to keep values bounded while preserving rotation
    final normalizedYaw = state.yawDeg % 360.0;
    final normalizedPitch = state.pitchDeg % 360.0;

    // Log every 60 calls (~1s at 60fps) to track pipeline health
    if (_spinCallCount % 60 == 0) {
      debugPrint('[SPIN] _onSpinChanged #$_spinCallCount '
          'pageReady=$_pageReady runJS=${_runJS != null} '
          'pitch=${normalizedPitch.toStringAsFixed(1)} '
          'yaw=${normalizedYaw.toStringAsFixed(1)}');
    }

    if (!_pageReady || _runJS == null) return;

    // Get per-model configuration
    final config = _getConfig(widget.containerType);

    // Calculate display pitch with base offset and clamping
    double rawDisplayPitch = config.basePitch + normalizedPitch;
    final clampedPitch = rawDisplayPitch.clamp(config.pitchClampMin, config.pitchClampMax);
    
    final yaw = normalizedYaw.toStringAsFixed(1);
    final displayPitch = clampedPitch.toStringAsFixed(1);
    
    // Prevent redundant JS calls when values haven't changed significantly (fixes flicker)
    const tolerance = 0.5;
    if (_lastAppliedYaw != null && _lastAppliedPitch != null &&
        (normalizedYaw - _lastAppliedYaw!).abs() < tolerance &&
        (clampedPitch - _lastAppliedPitch!).abs() < tolerance) {
      return;
    }
    
    _lastAppliedYaw = normalizedYaw;
    _lastAppliedPitch = clampedPitch;
    
    unawaited(_runJS!(
      'var mv=document.querySelector("model-viewer");'
      'if(mv){mv.setAttribute("camera-orbit","${yaw}deg ${displayPitch}deg ${config.cameraDistance}");}',
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
              // Use per-model config for initial camera orbit and field of view
              cameraOrbit: '0deg 90deg ${_getConfig(widget.containerType).cameraDistance}',
              fieldOfView: _getConfig(widget.containerType).fieldOfView,
              minCameraOrbit: '0deg 5deg',
              maxCameraOrbit: '360deg 175deg',
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
