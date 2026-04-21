import 'meme.dart';

class CollectionItem {
  final String cardId;
  final String assetPath;
  final Rarity rarity;
  final int acquiredAt;
  final int level;
  final int experience;
  final List<int> unlockedLoreSegments;
  final bool viewed;

  CollectionItem({
    required this.cardId,
    required this.assetPath,
    required this.rarity,
    required this.acquiredAt,
    this.level = 1,
    this.experience = 0,
    this.unlockedLoreSegments = const [],
    this.viewed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'asset_path': assetPath,
      'rarity': rarity.name,
      'acquired_at': acquiredAt,
      'level': level,
      'experience': experience,
      'unlocked_lore_segments': unlockedLoreSegments,
      'viewed': viewed,
    };
  }

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      cardId: json['card_id'] ?? json['id'] ?? '', // Handle migration
      assetPath: json['asset_path'],
      rarity: Rarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => Rarity.normie,
      ),
      acquiredAt: json['acquired_at'],
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      unlockedLoreSegments: json['unlocked_lore_segments'] != null 
          ? List<int>.from(json['unlocked_lore_segments']) 
          : [],
      viewed: json['viewed'] ?? false,
    );
  }

  String get memeId => cardId;

  CollectionItem copyWith({
    int? level,
    int? experience,
    List<int>? unlockedLoreSegments,
    bool? viewed,
  }) {
    return CollectionItem(
      cardId: cardId,
      assetPath: assetPath,
      rarity: rarity,
      acquiredAt: acquiredAt,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      unlockedLoreSegments: unlockedLoreSegments ?? this.unlockedLoreSegments,
      viewed: viewed ?? this.viewed,
    );
  }
}
