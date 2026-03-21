import 'package:basabuddy/utils/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;


class StreakService {
  final supabase = Supabase.instance.client;

  // Get current streak
  Future<int> getCurrentStreak(String userId) async {
    final db = await DatabaseHelper.instance.db;

    final local = await db.query(
      "user_streak",
      where: "user_id = ?",
      whereArgs: [userId],
    );

    if (local.isEmpty) return 0;

    return local.first["current_streak"] as int;
    
  }

  Future<void> freezeStreak(String userId) async {
  final now = DateTime.now();
  final db = await DatabaseHelper.instance.db;

  // Calculate the end of the next day (local time)
  final nextDayEnd = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);
  final nextDayEndUtc = nextDayEnd.toUtc();
  await db.update(
    'user_streak',
    {
      'streak_frozen_until': nextDayEndUtc.toIso8601String(),
      'updated_at': now,
    },
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  await supabase.from('profiles').update({
    'streakFrozenUntil': nextDayEndUtc.toIso8601String(),
    'updated_at': now.toUtc().toIso8601String()
  }).eq('id', userId);
}

  // Update streak after completing a story
  Future<void> updateStreak(String userId) async {
    print("STREAK SERVICE CALLED");
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final db = await DatabaseHelper.instance.db;

    int currentStreak = 0;
    int longestStreak = 0;
    String? lastActiveDate;
    String? streakFrozenUntilStr;

    try {
      final response = await supabase
        .from('profiles')
        .select('currentStreak, longestStreak, lastActiveDate, streakFrozenUntil')
        .eq('id', userId)
        .single();

      currentStreak = response['currentStreak'] ?? 0;
      longestStreak = response['longestStreak'] ?? 0;
      lastActiveDate = response['lastActiveDate'];
      streakFrozenUntilStr = response['streakFrozenUntil'];
    } catch (e) {
      final  local = await db.query(
        "user_streak",
        where: "user_id = ?",
        whereArgs: [userId],
      );

      if (local.isNotEmpty) {
        currentStreak = local.first['current_streak'] as int? ?? 0;
        longestStreak = local.first['longest_streak'] as int? ?? 0;
        lastActiveDate = local.first['last_active_date'] as String?;
        streakFrozenUntilStr = local.first['streak_frozen_until'] as String?;
      }
    }
    
    // Check if freeze is active
    if (streakFrozenUntilStr != null) {
      final frozenUntil = DateTime.parse(streakFrozenUntilStr).toUtc();
      final now = DateTime.now().toUtc().toIso8601String();
      if (todayUtc.isBefore(frozenUntil)) {

        await db.insert(
          "user_streak",
          {
            "user_id": userId,
            "current_streak": currentStreak,
            "longest_streak": longestStreak,
            "last_active_date": todayUtc.toIso8601String(),
            "streak_frozen_until": streakFrozenUntilStr,
            "updated_at": now
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        try {
          await supabase.from('profiles').update({
            'lastActiveDate': todayUtc.toIso8601String(),
          }).eq('id', userId);
        } catch (_) {}
        
        return;
      }
    }
    int newStreak;
    int newLongest = longestStreak;

    if (lastActiveDate == null) {
      newStreak = 1;
      newLongest = 1;
    } else {
      final lastDate = DateTime.parse(lastActiveDate).toUtc();
      final lastDateOnly =
          DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
      print("LAST DATE: $lastDate, current streak: $currentStreak, today: $todayUtc");
      final difference = todayUtc.difference(lastDateOnly).inDays;
      print("DIFFERENCE: $difference");
      if (difference == 0) return;
      newStreak = difference == 1 ? currentStreak + 1 : 1;
      if (newStreak > newLongest) newLongest = newStreak;
    }
    final now = DateTime.now().toUtc().toIso8601String();

    await db.insert(
      "user_streak",
      {
        "user_id": userId,
        "current_streak": newStreak,
        "longest_streak": newLongest,
        "last_active_date": todayUtc.toIso8601String(),
        "streak_frozen_until": streakFrozenUntilStr,
        "updated_at": now
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    try {
      await supabase.from('profiles').update({
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastActiveDate': todayUtc.toIso8601String(),
      }).eq('id', userId);
    } catch (_) {

    }
    
  }
}