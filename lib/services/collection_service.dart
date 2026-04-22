import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/collection_item.dart';
import '../models/meme.dart';

final collectionServiceProvider = FutureProvider((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CollectionService(prefs);
});

class AddCardResult {
  final bool isNew;
  final bool levelUp;
  final int? newLevel;
  final bool maxLevel;
  final int? coinsAwarded;

  AddCardResult({
    required this.isNew,
    required this.levelUp,
    this.newLevel,
    this.maxLevel = false,
    this.coinsAwarded,
  });
}

class CollectionService {
  final SharedPreferences prefs;
  static const String _collectionKey = 'collection';
  static const String _anonIdKey = 'anonymous_id';
  static const String _hapticsKey = 'haptics_enabled';
  static const String _crtKey = 'crt_effect_enabled';
  static const String _coinsKey = 'meme_coins';
  static const String _containerKey = 'selected_container';

  CollectionService(this.prefs);

  static const Map<Rarity, Map<int, int>> _levelThresholds = {
    Rarity.normie: {1: 6, 2: 8, 3: 12, 4: 18},
    Rarity.mid: {1: 4, 2: 6, 3: 8, 4: 12},
    Rarity.based: {1: 3, 2: 4, 3: 6, 4: 8},
    Rarity.dank: {1: 2, 2: 3, 3: 4, 4: 5},
    Rarity.sigma: {1: 1, 2: 2, 3: 2, 4: 3},
  };

  static const Map<Rarity, int> _maxLevelCoins = {
    Rarity.normie: 5,
    Rarity.mid: 15,
    Rarity.based: 40,
    Rarity.dank: 100,
    Rarity.sigma: 300,
  };

  String getAnonymousId() {
    String? id = prefs.getString(_anonIdKey);
    if (id == null) {
      id = const Uuid().v4();
      prefs.setString(_anonIdKey, id);
    }
    return id;
  }

  int getCoins() => prefs.getInt(_coinsKey) ?? 0;

  Future<void> addCoins(int amount) async {
    final current = getCoins();
    await prefs.setInt(_coinsKey, current + amount);
  }

  List<CollectionItem> getCollection() {
    final String? jsonStr = prefs.getString(_collectionKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => CollectionItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<AddCardResult> addCardToGallery(Meme meme) async {
    final collection = getCollection();
    final existingIndex = collection.indexWhere((item) => item.cardId == meme.id);

    if (existingIndex == -1) {
      final newItem = CollectionItem(
        cardId: meme.id,
        assetPath: meme.assetPath,
        rarity: meme.rarity,
        acquiredAt: DateTime.now().millisecondsSinceEpoch,
        level: 1,
        experience: 0,
        unlockedLoreSegments: [],
      );
      collection.insert(0, newItem);
      await _saveCollection(collection);
      return AddCardResult(isNew: true, levelUp: false);
    }

    final existing = collection[existingIndex];

    if (existing.level == 5) {
      final coins = _maxLevelCoins[meme.rarity] ?? 0;
      await addCoins(coins);
      return AddCardResult(isNew: false, levelUp: false, maxLevel: true, coinsAwarded: coins);
    }

    final threshold = _levelThresholds[existing.rarity]![existing.level]!;
    final newExp = existing.experience + 1;

    if (newExp >= threshold) {
      final newLevel = existing.level + 1;
      final overflow = newExp - threshold;
      final updated = existing.copyWith(
        level: newLevel,
        experience: overflow,
        unlockedLoreSegments: _getLoreSegmentsForLevel(newLevel),
      );
      collection[existingIndex] = updated;
      await _saveCollection(collection);
      return AddCardResult(isNew: false, levelUp: true, newLevel: newLevel);
    }

    final updated = existing.copyWith(experience: newExp);
    collection[existingIndex] = updated;
    await _saveCollection(collection);
    return AddCardResult(isNew: false, levelUp: false);
  }

  List<int> _getLoreSegmentsForLevel(int level) {
    // Level 2 unlocks segment 0 (Origin)
    // Level 3 unlocks segment 1 (Lore)
    // Level 4 unlocks segment 2 (Peak Moment)
    // Level 5 unlocks segment 3 (Tags)
    List<int> segments = [];
    for (int i = 0; i < level - 1; i++) {
      segments.add(i);
    }
    return segments;
  }

  Future<void> _saveCollection(List<CollectionItem> collection) async {
    await prefs.setString(_collectionKey, jsonEncode(collection.map((e) => e.toJson()).toList()));
  }

  bool isHapticsEnabled() => prefs.getBool(_hapticsKey) ?? true;
  Future<void> setHapticsEnabled(bool enabled) => prefs.setBool(_hapticsKey, enabled);

  bool isCrtEnabled() => prefs.getBool(_crtKey) ?? false;
  Future<void> setCrtEnabled(bool enabled) => prefs.setBool(_crtKey, enabled);

  Future<bool> spendCoins(int amount) async {
    final current = getCoins();
    if (current < amount) return false;
    await prefs.setInt(_coinsKey, current - amount);
    return true;
  }

  Future<void> removeCard(String cardId) async {
    final collection = getCollection();
    collection.removeWhere((item) => item.cardId == cardId);
    await _saveCollection(collection);
  }

  Future<void> unlockLoreSegment(String cardId, int segmentIndex) async {
    final collection = getCollection();
    final idx = collection.indexWhere((i) => i.cardId == cardId);
    if (idx == -1) return;
    final item = collection[idx];
    if (item.unlockedLoreSegments.contains(segmentIndex)) return;
    final newSegs = [...item.unlockedLoreSegments, segmentIndex]..sort();
    collection[idx] = item.copyWith(unlockedLoreSegments: newSegs);
    await _saveCollection(collection);
  }

  Future<void> clearCollection() => prefs.remove(_collectionKey);

  String getSelectedContainer() => prefs.getString(_containerKey) ?? 'brain';
  Future<void> setSelectedContainer(String container) => prefs.setString(_containerKey, container);
}
