import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meme.dart';

final assetServiceProvider = FutureProvider((ref) async {
  final service = AssetService();
  await service.loadManifest();
  return service;
});

class AssetService {
  List<Meme> _allMemes = [];
  final Random _random = Random();

  Future<void> loadManifest() async {
    final String manifestStr = await rootBundle.loadString('assets/memes/manifest.json');
    final List<dynamic> jsonList = jsonDecode(manifestStr);
    _allMemes = jsonList.map((e) => Meme.fromJson(e)).toList();
  }

  Meme getRandomMeme() {
    if (_allMemes.isEmpty) throw Exception("No memes loaded");

    final double roll = _random.nextDouble() * 100;
    Rarity selectedRarity;

    // Weights: normie: 60, mid: 25, based: 10, dank: 4, sigma: 1
    if (roll < 60) {
      selectedRarity = Rarity.normie;
    } else if (roll < 85) {
      selectedRarity = Rarity.mid;
    } else if (roll < 95) {
      selectedRarity = Rarity.based;
    } else if (roll < 99) {
      selectedRarity = Rarity.dank;
    } else {
      selectedRarity = Rarity.sigma;
    }

    final memesOfRarity = _allMemes.where((m) => m.rarity == selectedRarity).toList();
    
    if (memesOfRarity.isEmpty) {
      return _allMemes[_random.nextInt(_allMemes.length)];
    }

    return memesOfRarity[_random.nextInt(memesOfRarity.length)];
  }

  Meme? getMemeById(String id) {
    try {
      return _allMemes.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // Helper for generating reel tiles
  Rarity weightedRandomRarity() {
    final double roll = _random.nextDouble() * 100;
    if (roll < 60) return Rarity.normie;
    if (roll < 85) return Rarity.mid;
    if (roll < 95) return Rarity.based;
    if (roll < 99) return Rarity.dank;
    return Rarity.sigma;
  }
}
