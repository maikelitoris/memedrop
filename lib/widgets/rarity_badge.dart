import 'package:flutter/material.dart';
import '../models/meme.dart';

class RarityColors {
  static const Color normie = Color(0xFF9E9E9E);
  static const Color mid = Color(0xFF4FC3F7);
  static const Color based = Color(0xFFAB47BC);
  static const Color dank = Color(0xFFFF7043);
  static const Color sigma = Color(0xFFFFD700);

  static Color getColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.normie: return normie;
      case Rarity.mid: return mid;
      case Rarity.based: return based;
      case Rarity.dank: return dank;
      case Rarity.sigma: return sigma;
    }
  }

  static Map<String, dynamic> getReelStyle(Rarity rarity) {
    final color = getColor(rarity);
    switch (rarity) {
      case Rarity.normie:
        return {'bg': const Color(0xFF3a3a3a), 'border': color, 'glow': null};
      case Rarity.mid:
        return {'bg': const Color(0xFF0d3b52), 'border': color, 'glow': color};
      case Rarity.based:
        return {'bg': const Color(0xFF2d1040), 'border': color, 'glow': color};
      case Rarity.dank:
        return {'bg': const Color(0xFF3d1a00), 'border': color, 'glow': color};
      case Rarity.sigma:
        return {'bg': const Color(0xFF2d2000), 'border': color, 'glow': color};
    }
  }
}

class RarityBadge extends StatelessWidget {
  final Rarity rarity;
  const RarityBadge({super.key, required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: RarityColors.getColor(rarity),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
