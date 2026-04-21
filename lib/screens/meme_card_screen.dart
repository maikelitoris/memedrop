import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import '../constants.dart';
import '../models/collection_item.dart';
import '../models/meme_data.dart';
import '../services/collection_service.dart';
import '../widgets/meme_card_3d.dart';
import '../widgets/rarity_edge_glow.dart';

class MemeCardScreen extends ConsumerStatefulWidget {
  final MemeData meme;
  final int acquiredAt;
  final bool viewOnly;
  final bool isFirstView;
  final CollectionItem? collectionItem;

  const MemeCardScreen({
    super.key,
    required this.meme,
    required this.acquiredAt,
    required this.viewOnly,
    this.isFirstView = false,
    this.collectionItem,
  });

  @override
  ConsumerState<MemeCardScreen> createState() => _MemeCardScreenState();
}

class _MemeCardScreenState extends ConsumerState<MemeCardScreen> {
  bool _showChrome = true;
  Timer? _hideTimer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewOnly) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showChrome = false);
    });
  }

  void _toggleChrome() {
    setState(() => _showChrome = !_showChrome);
    if (_showChrome) _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  String _formatDate() {
    final dt = DateTime.fromMillisecondsSinceEpoch(widget.acquiredAt, isUtc: true);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    return 'ACQUIRED $mm.$dd.$yy';
  }

  Future<void> _saveToRoll() async {
    if (widget.meme.isPlaceholder) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('NO IMAGE TO SAVE', style: TextStyle(letterSpacing: 2, fontSize: 10)),
        backgroundColor: Color(0xFF1A1A1A),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final bytes = await rootBundle.load(widget.meme.assetPath);
      await Gal.putImageBytes(bytes.buffer.asUint8List());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SAVED TO CAMERA ROLL',
              style: TextStyle(letterSpacing: 2, fontSize: 10)),
          backgroundColor: Color(0xFF1A1A1A),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SAVE FAILED', style: TextStyle(letterSpacing: 2, fontSize: 10)),
          backgroundColor: Color(0xFF1A1A1A),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text('VIEW LORE',
                        style: TextStyle(fontSize: 12, letterSpacing: 3, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFF1A1A1A), height: 1),
            GestureDetector(
              onTap: () async {
                Navigator.of(ctx).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF141414),
                    title: const Text('DELETE',
                        style: TextStyle(letterSpacing: 4, fontSize: 13, color: Colors.white)),
                    content: const Text(
                      "Once gone, it's gone. Delete?",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL',
                            style: TextStyle(color: Colors.white54, letterSpacing: 2)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('OBLITERATE',
                            style: TextStyle(color: AppColors.destructive, letterSpacing: 2)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final nav = Navigator.of(context);
                  final cs = await ref.read(collectionServiceProvider.future);
                  await cs.removeCard(widget.meme.id);
                  ref.invalidate(collectionServiceProvider);
                  nav.pop();
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text('DELETE FROM HOARD',
                        style:
                            TextStyle(fontSize: 12, letterSpacing: 3, color: AppColors.destructive)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppColors.forRarity(widget.meme.rarity);
    final segments = widget.collectionItem?.unlockedLoreSegments ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: widget.viewOnly ? _toggleChrome : null,
        onLongPress: widget.viewOnly ? _showActionSheet : null,
        child: Stack(
          children: [
            // Full-screen edge glow + card
            RarityEdgeGlow(
              rarity: widget.meme.rarity,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56), // header placeholder
                    const Spacer(),
                    Hero(
                      tag: 'meme_${widget.meme.id}',
                      child: MemeCard3D(
                        meme: widget.meme,
                        acquiredAt: widget.acquiredAt,
                        viewOnly: widget.viewOnly,
                        unlockedLoreSegments: segments,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TAP TO REVEAL LORE',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 3,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const Spacer(),
                    if (widget.viewOnly) _buildFooter(),
                  ],
                ),
              ),
            ),

            // Auto-hiding header overlay
            if (widget.viewOnly)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showChrome ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              color: rarityColor,
                              child: Text(
                                widget.meme.rarity.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 2,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              // Static header for non-viewOnly (history screen)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            color: rarityColor,
                            child: Text(
                              widget.meme.rarity.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                letterSpacing: 2,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _saving ? null : _saveToRoll,
            child: Container(
              width: double.infinity,
              height: 48,
              color: const Color(0xFF1A1A1A),
              alignment: Alignment.center,
              child: Text(
                _saving ? 'SAVING...' : 'SAVE TO CAMERA ROLL',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: _saving ? Colors.white24 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(),
            style: const TextStyle(
              fontSize: 8,
              letterSpacing: 2,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
