import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final streakServiceProvider = Provider((ref) => StreakService());

class StreakService {
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastStreakDateKey = 'last_streak_date';
  static const String _freezesUsedKey = 'freezes_used_this_week';
  static const String _lastFreezeWeekKey = 'last_freeze_week';

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestStreakKey) ?? 0;
  }

  /// Returns true if a streak freeze was consumed this call.
  Future<bool> recordDropOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toUtc();
    final todayStr = _dateStr(today);
    final lastDateStr = prefs.getString(_lastStreakDateKey) ?? '';

    int current = prefs.getInt(_currentStreakKey) ?? 0;
    bool freezeUsed = false;

    if (lastDateStr.isEmpty) {
      current = 1;
    } else if (lastDateStr == todayStr) {
      // Already counted today — no-op.
    } else {
      final lastDate = DateTime.parse(lastDateStr).toUtc();
      final dayGap = today
          .difference(DateTime.utc(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (dayGap == 1) {
        current += 1;
      } else if (dayGap == 2) {
        freezeUsed = await _tryConsumeFreeze(prefs, today);
        if (freezeUsed) {
          current += 1;
        } else {
          current = 1;
        }
      } else {
        current = 1;
      }
    }

    final longest = prefs.getInt(_longestStreakKey) ?? 0;
    if (current > longest) await prefs.setInt(_longestStreakKey, current);
    await prefs.setInt(_currentStreakKey, current);
    await prefs.setString(_lastStreakDateKey, todayStr);

    return freezeUsed;
  }

  Future<bool> _tryConsumeFreeze(SharedPreferences prefs, DateTime today) async {
    final weekStart = _mondayOf(today);
    final weekStartStr = _dateStr(weekStart);
    final lastFreezeWeek = prefs.getString(_lastFreezeWeekKey) ?? '';
    final freezesUsed = prefs.getInt(_freezesUsedKey) ?? 0;

    final sameWeek = lastFreezeWeek == weekStartStr;
    if (!sameWeek || freezesUsed < 1) {
      await prefs.setInt(_freezesUsedKey, sameWeek ? freezesUsed + 1 : 1);
      await prefs.setString(_lastFreezeWeekKey, weekStartStr);
      return true;
    }
    return false;
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _mondayOf(DateTime d) {
    return DateTime.utc(d.year, d.month, d.day - (d.weekday - 1));
  }
}
