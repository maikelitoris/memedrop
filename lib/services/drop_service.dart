import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dropServiceProvider = Provider((ref) => DropService());

class DropHistory {
  final int openedAt;
  final String rarity;
  final String assetPath;
  final bool stashed;
  final String memeId;

  const DropHistory({
    required this.openedAt,
    required this.rarity,
    required this.assetPath,
    required this.stashed,
    this.memeId = '',
  });

  DropHistory copyWith({bool? stashed, String? memeId}) => DropHistory(
        openedAt: openedAt,
        rarity: rarity,
        assetPath: assetPath,
        stashed: stashed ?? this.stashed,
        memeId: memeId ?? this.memeId,
      );

  Map<String, dynamic> toJson() => {
        'opened_at': openedAt,
        'rarity': rarity,
        'asset_path': assetPath,
        'stashed': stashed,
        'meme_id': memeId,
      };

  factory DropHistory.fromJson(Map<String, dynamic> json) => DropHistory(
        openedAt: json['opened_at'] as int,
        rarity: json['rarity'] as String,
        assetPath: json['asset_path'] as String,
        stashed: (json['stashed'] as bool?) ?? false,
        memeId: (json['meme_id'] as String?) ?? '',
      );
}

class DropService {
  static const String _lastOpenedKey = 'last_opened_timestamp';
  static const String _dropHistoryKey = 'drop_history';
  static const int _maxHistory = 60;

  // TEST MODE: time gate disabled — revert before shipping
  Future<bool> canOpenDrop() async => true;

  Future<void> markDropAsOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastOpenedKey, DateTime.now().toUtc().millisecondsSinceEpoch);
  }

  Future<void> recordDropOpened({
    required String rarity,
    required String assetPath,
    String memeId = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = _loadHistory(prefs);
    history.insert(
      0,
      DropHistory(
        openedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        rarity: rarity,
        assetPath: assetPath,
        stashed: false,
        memeId: memeId,
      ),
    );
    if (history.length > _maxHistory) history.removeRange(_maxHistory, history.length);
    await _saveHistory(prefs, history);
  }

  Future<void> markLastDropStashed() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _loadHistory(prefs);
    if (history.isEmpty) return;
    history[0] = history[0].copyWith(stashed: true);
    await _saveHistory(prefs, history);
  }

  Future<Map<String, int>> getStashStats() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _loadHistory(prefs);
    return {
      'total': history.length,
      'stashed': history.where((e) => e.stashed).length,
    };
  }

  Future<List<DropHistory>> getDropHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadHistory(prefs);
  }

  List<DropHistory> _loadHistory(SharedPreferences prefs) {
    final str = prefs.getString(_dropHistoryKey);
    if (str == null) return [];
    final list = jsonDecode(str) as List<dynamic>;
    return list.map((e) => DropHistory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveHistory(
      SharedPreferences prefs, List<DropHistory> history) async {
    await prefs.setString(
        _dropHistoryKey, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Duration timeUntilNextDrop() {
    final now = DateTime.now().toUtc();
    final next = now.hour < 12
        ? DateTime.utc(now.year, now.month, now.day, 12, 0)
        : DateTime.utc(now.year, now.month, now.day + 1, 0, 0);
    return next.difference(now);
  }
}
