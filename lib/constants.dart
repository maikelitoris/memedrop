import 'package:flutter/material.dart';
import 'models/meme.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surface2 = Color(0xFF1A1A1A);
  static const Color surface3 = Color(0xFF1E1E1E);

  static const Color normie = Color(0xFF9E9E9E);
  static const Color mid = Color(0xFF4FC3F7);
  static const Color based = Color(0xFFAB47BC);
  static const Color dank = Color(0xFFFF7043);
  static const Color sigma = Color(0xFFFFD700);

  static const Color streakNormal = Color(0xFFFF6B35);
  static const Color streakLegendary = Color(0xFFFFD700);
  static const Color destructive = Color(0xFFFF3333);
  static const Color streakFreeze = Color(0xFF00D4AA);

  static Color forRarity(Rarity rarity) {
    switch (rarity) {
      case Rarity.normie:
        return normie;
      case Rarity.mid:
        return mid;
      case Rarity.based:
        return based;
      case Rarity.dank:
        return dank;
      case Rarity.sigma:
        return sigma;
    }
  }
}

class AppStrings {
  static const String appTitle = 'DROP.';
  static const String theHoard = 'THE HOARD';
  static const String settings = 'SETTINGS';
  static const String sealed = 'SEALED';
  static const String tapToOpen = 'TAP TO OPEN';
  static const String stashToGallery = 'STASH TO GALLERY';
  static const String stashed = 'STASHED';
  static const String legendaryAcquired = '⚡ SIGMA ACQUIRED';
  static const String saveToRoll = 'SAVE TO CAMERA ROLL';
  static const String deleteFromHoard = 'DELETE FROM HOARD';
  static const String purgeTheHoard = 'PURGE THE HOARD';
  static const String streakSaved = 'STREAK SAVED. 1 FREEZE USED THIS WEEK.';
}
