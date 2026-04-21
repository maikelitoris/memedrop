import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final coinServiceProvider = FutureProvider((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CoinService(prefs);
});

class CoinService {
  final SharedPreferences prefs;
  static const String _shieldsKey = 'vault_streak_shields';
  static const String _bonusDropKey = 'vault_bonus_drop_available';

  CoinService(this.prefs);

  int getShields() => prefs.getInt(_shieldsKey) ?? 0;

  Future<void> addShield() async {
    await prefs.setInt(_shieldsKey, getShields() + 1);
  }

  Future<bool> consumeShield() async {
    final current = getShields();
    if (current <= 0) return false;
    await prefs.setInt(_shieldsKey, current - 1);
    return true;
  }

  bool hasBonusDrop() => prefs.getBool(_bonusDropKey) ?? false;

  Future<void> setBonusDrop(bool value) async {
    await prefs.setBool(_bonusDropKey, value);
  }
}
