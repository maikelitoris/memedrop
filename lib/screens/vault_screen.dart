import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../data/meme_manifest.dart';
import '../models/collection_item.dart';
import '../services/coin_service.dart';
import '../services/collection_service.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  int _coins = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cs = await ref.read(collectionServiceProvider.future);
    if (mounted) {
      setState(() {
        _coins = cs.getCoins();
        _loaded = true;
      });
    }
  }

  Future<void> _purchase(int cost, Future<void> Function() action) async {
    if (_coins < cost) return;
    final cs = await ref.read(collectionServiceProvider.future);
    final ok = await cs.spendCoins(cost);
    if (!ok) return;
    await action();
    if (mounted) {
      setState(() => _coins -= cost);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PURCHASED', style: TextStyle(letterSpacing: 3, fontSize: 10)),
        backgroundColor: Color(0xFF1A1A1A),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<void> _buyStreakShield() async {
    await _purchase(50, () async {
      final coinService = await ref.read(coinServiceProvider.future);
      await coinService.addShield();
    });
  }

  Future<void> _buyLoreUnlock() async {
    final cs = await ref.read(collectionServiceProvider.future);
    final eligible = cs.getCollection().where((item) => item.unlockedLoreSegments.length < 4).toList();

    if (eligible.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('NO CARDS WITH LOCKED LORE',
              style: TextStyle(letterSpacing: 2, fontSize: 10)),
          backgroundColor: Color(0xFF1A1A1A),
        ));
      }
      return;
    }

    if (!mounted) return;
    final chosen = await _showCardPicker(eligible);
    if (chosen == null) return;

    await _purchase(80, () async {
      final nextLocked = [0, 1, 2, 3].firstWhere(
        (i) => !chosen.unlockedLoreSegments.contains(i),
        orElse: () => -1,
      );
      if (nextLocked != -1) {
        await cs.unlockLoreSegment(chosen.cardId, nextLocked);
        ref.invalidate(collectionServiceProvider);
      }
    });
  }

  Future<void> _buyExtraDrop() async {
    final coinService = await ref.read(coinServiceProvider.future);
    if (coinService.hasBonusDrop()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ALREADY HAVE A BONUS DROP',
              style: TextStyle(letterSpacing: 2, fontSize: 10)),
          backgroundColor: Color(0xFF1A1A1A),
        ));
      }
      return;
    }
    await _purchase(200, () async {
      await coinService.setBonusDrop(true);
    });
  }

  Future<CollectionItem?> _showCardPicker(List<CollectionItem> eligible) async {
    return showModalBottomSheet<CollectionItem>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (ctx, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('CHOOSE CARD',
                  style: TextStyle(fontSize: 11, letterSpacing: 4, color: Colors.white)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: eligible.length,
                itemBuilder: (_, i) {
                  final item = eligible[i];
                  final memeData = kMemeManifest.firstWhere(
                    (m) => m.id == item.cardId,
                    orElse: () => kFallbackMeme,
                  );
                  final locked = 4 - item.unlockedLoreSegments.length;
                  final rarityColor = AppColors.forRarity(item.rarity);
                  return GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(item),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: rarityColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                memeData.name.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12, letterSpacing: 1, color: Colors.white),
                              ),
                            ),
                            Text(
                              'LV ${item.level} · $locked LOCKED',
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF555555)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THE VAULT', style: TextStyle(letterSpacing: 6, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$_coins COINS',
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 4,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _VaultItem(
                        title: 'STREAK SHIELD',
                        subtitle: 'One extra streak freeze for the current week.',
                        cost: 50,
                        coins: _coins,
                        onTap: _buyStreakShield,
                      ),
                      const _Divider(),
                      _VaultItem(
                        title: 'LORE UNLOCK',
                        subtitle: 'Unlock the next locked lore segment on one chosen card.',
                        cost: 80,
                        coins: _coins,
                        onTap: _buyLoreUnlock,
                      ),
                      const _Divider(),
                      _VaultItem(
                        title: 'EXTRA DROP',
                        subtitle: 'One bonus drop outside time windows. Max 1 held.',
                        cost: 200,
                        coins: _coins,
                        onTap: _buyExtraDrop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _VaultItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final int cost;
  final int coins;
  final VoidCallback onTap;

  const _VaultItem({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.coins,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= cost;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    color: canAfford ? Colors.white : const Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: canAfford ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: canAfford ? const Color(0xFF1A1A1A) : const Color(0xFF111111),
                border: Border.all(
                  color: canAfford ? Colors.white24 : const Color(0xFF222222),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on,
                      color: canAfford ? Colors.amber : const Color(0xFF333333), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: canAfford ? Colors.amber : const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFF1A1A1A), height: 1, thickness: 1);
  }
}
