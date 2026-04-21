import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection_item.dart';
import '../services/asset_service.dart';
import '../widgets/lore_segment.dart';
import '../widgets/rarity_badge.dart';

class MemeViewScreen extends ConsumerStatefulWidget {
  final CollectionItem item;
  const MemeViewScreen({super.key, required this.item});

  @override
  ConsumerState<MemeViewScreen> createState() => _MemeViewScreenState();
}

class _MemeViewScreenState extends ConsumerState<MemeViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(_flipController);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assetServiceAsync = ref.watch(assetServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
            Navigator.of(context).pop();
          }
        },
        onTap: _flipCard,
        child: Center(
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value;
              final isBack = angle >= pi / 2;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _buildBack(assetServiceAsync),
                      )
                    : _buildFront(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: 320,
      height: 448, // 800x1120 ratio is 5:7
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RarityColors.getColor(widget.item.rarity), width: 2),
        boxShadow: [
          BoxShadow(
            color: RarityColors.getColor(widget.item.rarity).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(widget.item.assetPath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBack(AsyncValue<AssetService> assetServiceAsync) {
    return Container(
      width: 320,
      height: 448,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: assetServiceAsync.when(
        data: (service) {
          final meme = service.getMemeById(widget.item.cardId);
          if (meme == null) return const Center(child: Text("Meme data missing"));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "CARD BACK",
                    style: TextStyle(letterSpacing: 4, fontSize: 12, color: Colors.white54),
                  ),
                  RarityBadge(rarity: widget.item.rarity),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      LoreSegment(
                        title: "Origin",
                        content: meme.origin ?? "Unknown origin",
                        isLocked: !widget.item.unlockedLoreSegments.contains(0),
                      ),
                      LoreSegment(
                        title: "Lore",
                        content: meme.lore ?? "No lore available",
                        isLocked: !widget.item.unlockedLoreSegments.contains(1),
                      ),
                      LoreSegment(
                        title: "Peak Moment",
                        content: meme.peakMoment ?? "N/A",
                        isLocked: !widget.item.unlockedLoreSegments.contains(2),
                      ),
                      LoreSegment(
                        title: "Tags",
                        content: meme.tags?.join(", ") ?? "None",
                        isLocked: !widget.item.unlockedLoreSegments.contains(3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "LV ${widget.item.level}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text("Error loading data")),
      ),
    );
  }
}
