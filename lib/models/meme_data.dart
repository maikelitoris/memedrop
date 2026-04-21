import 'meme.dart';

class MemeData {
  final String id;
  final String assetPath;
  final Rarity rarity;
  final String name;
  final String era;
  final String origin;
  final String lore;
  final String peakEvent;
  final List<String> tags;
  final bool isPlaceholder;

  const MemeData({
    required this.id,
    required this.assetPath,
    required this.rarity,
    required this.name,
    required this.era,
    required this.origin,
    required this.lore,
    required this.peakEvent,
    required this.tags,
    this.isPlaceholder = false,
  });

  Meme toMeme() => Meme(
        id: id,
        assetPath: assetPath,
        rarity: rarity,
        origin: origin,
        lore: lore,
        peakMoment: peakEvent,
        tags: tags,
      );
}
