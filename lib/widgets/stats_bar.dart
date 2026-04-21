import 'package:flutter/material.dart';
import '../models/collection_item.dart';
import '../models/meme.dart';
import '../constants.dart';

class StatsBar extends StatelessWidget {
  final List<CollectionItem> items;

  const StatsBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final counts = <Rarity, int>{};
    for (final item in items) {
      counts[item.rarity] = (counts[item.rarity] ?? 0) + 1;
    }

    final pills = <Widget>[
      _Pill('${items.length} STASHED', Colors.white60),
      for (final rarity in [Rarity.sigma, Rarity.dank, Rarity.based, Rarity.mid, Rarity.normie])
        if (counts.containsKey(rarity))
          _Pill(
            '${counts[rarity]} ${_symbol(rarity)} ${rarity.name.toUpperCase()}',
            AppColors.forRarity(rarity),
          ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => pills[i],
      ),
    );
  }

  String _symbol(Rarity rarity) {
    switch (rarity) {
      case Rarity.sigma:
        return '✦';
      case Rarity.dank:
        return '◈';
      case Rarity.based:
        return '◆';
      case Rarity.mid:
        return '◆';
      case Rarity.normie:
        return '●';
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 2,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
