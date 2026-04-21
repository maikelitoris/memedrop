import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../data/meme_manifest.dart';
import '../models/collection_item.dart';
import '../models/meme.dart';
import '../models/meme_data.dart';
import '../services/collection_service.dart';
import '../services/drop_service.dart';
import '../widgets/card_tile.dart';
import '../widgets/stats_bar.dart';
import '../widgets/sort_filter_sheet.dart';
import 'meme_card_screen.dart';
import 'vault_screen.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  GallerySort _sort = GallerySort.newestFirst;
  GalleryFilter _filter = const GalleryFilter();

  List<CollectionItem> _applySort(List<CollectionItem> items) {
    final sorted = List<CollectionItem>.from(items);
    switch (_sort) {
      case GallerySort.newestFirst:
        sorted.sort((a, b) => b.acquiredAt.compareTo(a.acquiredAt));
      case GallerySort.rarity:
        const order = [Rarity.sigma, Rarity.dank, Rarity.based, Rarity.mid, Rarity.normie];
        sorted.sort((a, b) => order.indexOf(a.rarity).compareTo(order.indexOf(b.rarity)));
      case GallerySort.level:
        sorted.sort((a, b) => b.level.compareTo(a.level));
      case GallerySort.alphabetical:
        sorted.sort((a, b) {
          final nameA = kMemeManifest.where((m) => m.id == a.cardId).firstOrNull?.name ?? a.cardId;
          final nameB = kMemeManifest.where((m) => m.id == b.cardId).firstOrNull?.name ?? b.cardId;
          return nameA.compareTo(nameB);
        });
    }
    return sorted;
  }

  List<CollectionItem> _applyFilter(List<CollectionItem> items) {
    return items.where((item) {
      if (_filter.rarities.isNotEmpty && !_filter.rarities.contains(item.rarity)) return false;
      if (_filter.maxLevelOnly && item.level != 5) return false;
      if (_filter.lockedLoreOnly && item.unlockedLoreSegments.length >= 4) return false;
      return true;
    }).toList();
  }

  void _openSortFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SortFilterSheet(
        currentSort: _sort,
        currentFilter: _filter,
        onApply: (sort, filter) {
          setState(() {
            _sort = sort;
            _filter = filter;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(collectionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: collectionAsync.when(
          data: (service) => Column(
            children: [
              const Text(
                'THE HOARD',
                style: TextStyle(letterSpacing: 4, fontSize: 14),
              ),
              GestureDetector(
                onLongPress: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VaultScreen()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${service.getCoins()} COINS',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: Colors.amber,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Text('THE HOARD', style: TextStyle(letterSpacing: 4, fontSize: 14)),
          error: (_, __) => const Text('THE HOARD', style: TextStyle(letterSpacing: 4, fontSize: 14)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              color: _filter.isFiltered ? const Color(0xFF00D4AA) : Colors.white,
            ),
            onPressed: () => _openSortFilter(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: collectionAsync.when(
            data: (service) => StatsBar(items: service.getCollection()),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
      body: collectionAsync.when(
        data: (service) {
          final allItems = service.getCollection();
          if (allItems.isEmpty) return _buildEmptyState();

          final items = _applyFilter(_applySort(allItems));
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('NO CARDS MATCH FILTER',
                      style: TextStyle(fontSize: 11, letterSpacing: 3, color: Colors.white38)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _filter = const GalleryFilter()),
                    child: const Text('CLEAR FILTER',
                        style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF00D4AA))),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 5 / 7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onLongPress: () => _showLongPressSheet(context, item, service),
                child: CardTile(
                  item: item,
                  onTap: () => _openCard(context, item),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  MemeData _lookupMemeData(CollectionItem item) {
    final match = kMemeManifest.where((m) => m.id == item.cardId).firstOrNull;
    if (match != null) return match;
    // Legacy card stored with old JSON manifest ID — build usable fallback from stored data
    return MemeData(
      id: item.cardId,
      assetPath: item.assetPath,
      rarity: item.rarity,
      name: item.rarity.name.toUpperCase(),
      era: 'UNCHARTED ERA',
      origin: 'Origin data lost to the void.',
      lore: 'This card predates the lore archive.',
      peakEvent: 'Unknown',
      tags: [],
      isPlaceholder: false,
    );
  }

  void _openCard(BuildContext context, CollectionItem item) {
    final memeData = _lookupMemeData(item);
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => MemeCardScreen(
            meme: memeData,
            acquiredAt: item.acquiredAt,
            viewOnly: true,
            isFirstView: false,
            collectionItem: item,
          ),
        ))
        .then((_) => ref.invalidate(collectionServiceProvider));
  }

  void _showLongPressSheet(BuildContext context, CollectionItem item, CollectionService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                _openCard(context, item); // uses _lookupMemeData internally
              },
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
                      'Once gone, it\'s gone. Delete?',
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
                if (confirm == true && context.mounted) {
                  await service.removeCard(item.cardId);
                  ref.invalidate(collectionServiceProvider);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text('DELETE FROM HOARD',
                        style: TextStyle(fontSize: 12, letterSpacing: 3, color: AppColors.destructive)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _EmptyGalleryState();
  }
}

class _EmptyGalleryState extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EmptyGalleryState> createState() => _EmptyGalleryStateState();
}

class _EmptyGalleryStateState extends ConsumerState<_EmptyGalleryState>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  String _getCountdown() {
    final ds = ref.read(dropServiceProvider);
    final dur = ds.timeUntilNextDrop();
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    return 'NEXT DROP: ${h.toString().padLeft(2, '0')}H ${m.toString().padLeft(2, '0')}M';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _breatheAnim,
            builder: (_, __) => Transform.scale(
              scale: _breatheAnim.value,
              child: const Text(
                '?',
                style: TextStyle(fontSize: 120, color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                'Your gallery is as barren as your DMs.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              Text(
                _getCountdown(),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
