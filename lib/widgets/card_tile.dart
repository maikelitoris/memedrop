import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import 'rarity_badge.dart';
import 'xp_bar.dart';

class CardTile extends StatelessWidget {
  final CollectionItem item;
  final VoidCallback onTap;

  const CardTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = RarityColors.getColor(item.rarity);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: rarityColor.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.asset(item.assetPath, fit: BoxFit.cover),
              ),
              
              // Bottom Info Area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RarityBadge(rarity: item.rarity),
                          if (item.level == 5)
                            const Icon(Icons.star, color: RarityColors.sigma, size: 16)
                          else
                            Text(
                              'LV ${item.level}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      XPBar(level: item.level, experience: item.experience, rarity: item.rarity),
                    ],
                  ),
                ),
              ),

              // Lore Progress (Dots)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: List.generate(4, (index) {
                    final isUnlocked = item.unlockedLoreSegments.contains(index);
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked ? Colors.white : Colors.white24,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
