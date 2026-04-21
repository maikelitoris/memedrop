import 'package:flutter/material.dart';
import '../models/meme.dart';
import 'rarity_badge.dart';

class XPBar extends StatelessWidget {
  final int level;
  final int experience;
  final Rarity rarity;

  const XPBar({
    super.key,
    required this.level,
    required this.experience,
    required this.rarity,
  });

  static const Map<Rarity, Map<int, int>> _levelThresholds = {
    Rarity.normie: {1: 6, 2: 8, 3: 12, 4: 18},
    Rarity.mid: {1: 4, 2: 6, 3: 8, 4: 12},
    Rarity.based: {1: 3, 2: 4, 3: 6, 4: 8},
    Rarity.dank: {1: 2, 2: 3, 3: 4, 4: 5},
    Rarity.sigma: {1: 1, 2: 2, 3: 2, 4: 3},
  };

  @override
  Widget build(BuildContext context) {
    if (level == 5) {
      return _buildBar(1.0, isMax: true);
    }

    final threshold = _levelThresholds[rarity]![level]!;
    final progress = experience / threshold;

    return _buildBar(progress);
  }

  Widget _buildBar(double progress, {bool isMax = false}) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: isMax ? RarityColors.sigma : RarityColors.getColor(rarity),
            borderRadius: BorderRadius.circular(2),
            boxShadow: isMax ? [
              const BoxShadow(color: RarityColors.sigma, blurRadius: 4, spreadRadius: 1)
            ] : null,
          ),
        ),
      ),
    );
  }
}
