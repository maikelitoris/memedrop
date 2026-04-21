import 'package:flutter/material.dart';
import '../models/meme.dart';
import 'rarity_badge.dart';

enum GallerySort { newestFirst, rarity, level, alphabetical }

class GalleryFilter {
  final Set<Rarity> rarities;
  final bool maxLevelOnly;
  final bool lockedLoreOnly;

  const GalleryFilter({
    this.rarities = const {},
    this.maxLevelOnly = false,
    this.lockedLoreOnly = false,
  });

  bool get isFiltered =>
      rarities.isNotEmpty || maxLevelOnly || lockedLoreOnly;

  GalleryFilter copyWith({
    Set<Rarity>? rarities,
    bool? maxLevelOnly,
    bool? lockedLoreOnly,
  }) {
    return GalleryFilter(
      rarities: rarities ?? this.rarities,
      maxLevelOnly: maxLevelOnly ?? this.maxLevelOnly,
      lockedLoreOnly: lockedLoreOnly ?? this.lockedLoreOnly,
    );
  }
}

class SortFilterSheet extends StatefulWidget {
  final GallerySort currentSort;
  final GalleryFilter currentFilter;
  final void Function(GallerySort, GalleryFilter) onApply;

  const SortFilterSheet({
    super.key,
    required this.currentSort,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  late GallerySort _sort;
  late GalleryFilter _filter;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _filter = widget.currentFilter;
  }

  static const _sortLabels = {
    GallerySort.newestFirst: 'NEWEST FIRST',
    GallerySort.rarity: 'RARITY',
    GallerySort.level: 'LEVEL',
    GallerySort.alphabetical: 'ALPHABETICAL',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SORT',
            style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GallerySort.values.map((sort) {
              final selected = _sort == sort;
              return GestureDetector(
                onTap: () => setState(() => _sort = sort),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: selected ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  child: Text(
                    _sortLabels[sort]!,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: selected ? Colors.black : const Color(0xFF888888),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'FILTER',
            style: TextStyle(fontSize: 9, letterSpacing: 4, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rarity in [
                Rarity.sigma,
                Rarity.dank,
                Rarity.based,
                Rarity.mid,
                Rarity.normie
              ])
                _RarityPill(
                  rarity: rarity,
                  selected: _filter.rarities.contains(rarity),
                  onTap: () {
                    final newSet = Set<Rarity>.from(_filter.rarities);
                    if (newSet.contains(rarity)) {
                      newSet.remove(rarity);
                    } else {
                      newSet.add(rarity);
                    }
                    setState(() => _filter = _filter.copyWith(rarities: newSet));
                  },
                ),
              _TextPill(
                label: 'MAX LEVEL',
                selected: _filter.maxLevelOnly,
                onTap: () => setState(
                    () => _filter = _filter.copyWith(maxLevelOnly: !_filter.maxLevelOnly)),
              ),
              _TextPill(
                label: 'LOCKED LORE',
                selected: _filter.lockedLoreOnly,
                onTap: () => setState(
                    () => _filter = _filter.copyWith(lockedLoreOnly: !_filter.lockedLoreOnly)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _sort = GallerySort.newestFirst;
                      _filter = const GalleryFilter();
                    });
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: const Text(
                      'RESET',
                      style: TextStyle(
                          fontSize: 10, letterSpacing: 3, color: Color(0xFF666666)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onApply(_sort, _filter);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    color: Colors.white,
                    child: const Text(
                      'APPLY',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RarityPill extends StatelessWidget {
  final Rarity rarity;
  final bool selected;
  final VoidCallback onTap;

  const _RarityPill({required this.rarity, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = RarityColors.getColor(rarity);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : const Color(0xFF1A1A1A),
          border: Border.all(color: selected ? color : const Color(0xFF333333)),
        ),
        child: Text(
          rarity.name.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2,
            color: selected ? color : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _TextPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TextPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.1) : const Color(0xFF1A1A1A),
          border: Border.all(
            color: selected ? Colors.white54 : const Color(0xFF333333),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2,
            color: selected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
