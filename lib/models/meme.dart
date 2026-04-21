enum Rarity {
  normie,
  mid,
  based,
  dank,
  sigma,
}

class Meme {
  final String id;
  final String assetPath;
  final Rarity rarity;
  final String? origin;
  final String? lore;
  final String? peakMoment;
  final List<String>? tags;

  Meme({
    required this.id,
    required this.assetPath,
    required this.rarity,
    this.origin,
    this.lore,
    this.peakMoment,
    this.tags,
  });

  factory Meme.fromJson(Map<String, dynamic> json) {
    return Meme(
      id: json['id'],
      assetPath: json['asset_path'],
      rarity: Rarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => Rarity.normie,
      ),
      origin: json['origin'],
      lore: json['lore'],
      peakMoment: json['peak_moment'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }
}
