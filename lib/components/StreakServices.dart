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

  Future<bool> freezeStreak(String userId) async {
  final now = DateTime.now();
  final nowStr = now.toUtc().toIso8601String();
  final db = await DatabaseHelper.instance.db;

  final local = await db.query(
    'user_streak',
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  final row = local.isNotEmpty ? local.first : null;

  final int currentFreezeCount = row? ['freeze_count'] as int? ?? 0;

  if (currentFreezeCount >= 2) {
    return false;
  }

  final moneyRow = await db.query(
    'user_money',
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  final int currentMoney = moneyRow.isNotEmpty
    ? (moneyRow.first['money'] as int? ?? 0)
    : 0;

  if (currentMoney < 40) {
    return false;
  }
  final int newMoney = currentMoney - 40;
  await db.update(
    'user_money',
    {'money': newMoney, 'updated_at': nowStr},
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  try {
    await supabase.from('user_money').upsert({
      'user_id': userId,
      'money': newMoney,
      'updated_at': nowStr,
    }, onConflict: 'user_id',);
  } catch(_){}

  final existingFrozenUntilStr = row?['streak_frozen_until'] as String?;
  DateTime baseDate;
  if (existingFrozenUntilStr != null) {
    final existing = DateTime.parse(existingFrozenUntilStr).toUtc();
    baseDate = existing.isAfter(now.toUtc()) ? existing: now.toUtc();
  } else {
    baseDate = now.toUtc();
  }
  // Calculate the end of the next day (local time)
  final nextDay = DateTime.utc(baseDate.year, baseDate.month, baseDate.day + 1, 23, 59, 59);
  
  final int newFreezeCount = currentFreezeCount + 1;

  await db.insert(
    'user_streak',
    {
      'user_id': userId,
      'current_streak': row?['current_streak'] ?? 0,
      'longest_streak': row?['longest_streak'] ?? 0,
      'last_active_date': row?['last_active_date'],
      'streak_frozen_until': nextDay.toIso8601String(),
      'freeze_count': newFreezeCount,
      'updated_at': nowStr,
    },
    conflictAlgorithm: ConflictAlgorithm.replace
  );
  try{
    await supabase.from('profiles').update({
      'streakFrozenUntil': nextDay.toIso8601String(),
      'freezeCount': newFreezeCount,
      'updated_at': nowStr,
    }).eq('id', userId);
  } catch (_) {}
  
  return true;
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
    int freezeCount = 0;

    try {
      final response = await supabase
        .from('profiles')
        .select('currentStreak, longestStreak, lastActiveDate, streakFrozenUntil, freezeCount')
        .eq('id', userId)
        .single();

      currentStreak = response['currentStreak'] ?? 0;
      longestStreak = response['longestStreak'] ?? 0;
      lastActiveDate = response['lastActiveDate'];
      streakFrozenUntilStr = response['streakFrozenUntil'];
      freezeCount = response['freezeCount'] ?? 0;
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
        freezeCount = local.first['freeze_count'] as int? ?? 0;
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    if (lastActiveDate != null) {
      final lastDate = DateTime.parse(lastActiveDate).toUtc();
      final lastDateOnly = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
      print("Have you taken another test today? ${todayUtc.difference(lastDateOnly).inDays == 0}");
      if (todayUtc.difference(lastDateOnly).inDays == 0) return;
    }

    // Check if freeze is active
    if (streakFrozenUntilStr != null) {
      final frozenUntil = DateTime.parse(streakFrozenUntilStr).toUtc();
      if (todayUtc.isBefore(frozenUntil)) {
        // Check if the freeze is actually being consumed (user missed a day)
        bool freezeConsumed = false;
        int newFreezeCount = freezeCount;

        if (lastActiveDate != null) {
          final lastDate = DateTime.parse(lastActiveDate).toUtc();
          final lastDateOnly = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
          final difference = todayUtc.difference(lastDateOnly).inDays;

          if (difference > 1) {
            // A day was actually missed — consume one freeze
            freezeConsumed = true;
            newFreezeCount = (freezeCount - 1).clamp(0, freezeCount);
          }
        }

        // Once all freezes are consumed, clear the frozen-until date
        final String? newFrozenUntil = newFreezeCount > 0 ? streakFrozenUntilStr : null;

        await _saveStreak(db, userId, currentStreak, longestStreak,
            todayUtc.toIso8601String(), newFrozenUntil, newFreezeCount, now);

        try {
          await supabase.from('profiles').update({
            'lastActiveDate': todayUtc.toIso8601String(),
            if (freezeConsumed) 'freezeCount': newFreezeCount,
            if (freezeConsumed) 'streakFrozenUntil': newFrozenUntil,
          }).eq('id', userId);
        } catch (_) {}
        return;
      }
    }
    int newStreak;
    int newLongest = longestStreak;
    String? newFrozenUntil = null;
    int newFreezeCount = freezeCount;

    if (lastActiveDate == null) {
      newStreak = 1;
      newLongest = 1;
    } else {
      final lastDate = DateTime.parse(lastActiveDate).toUtc();
      final lastDateOnly = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
      print("LAST DATE: $lastDate, current streak: $currentStreak, today: $todayUtc");
      final difference = todayUtc.difference(lastDateOnly).inDays;
      print("DIFFERENCE: $difference, freezeCount: $freezeCount");
      
      if (difference == 1) {
        newStreak = currentStreak + 1;
      } else if (difference ==2 && freezeCount > 0) {
        //Missed exactly 1 day and has a freeze in reserve
        //Consume on freeze to save streak
        newStreak = currentStreak + 1;
        newFreezeCount = freezeCount - 1;

        print("Freeze consumed! Remaining: $newFreezeCount");
      } else {
        //Missed 2+ days, or missed 1 day but no freezes left
        newStreak = 1;
        newFreezeCount = 0;

        print("Streak reset");
      }

      if (newStreak > newLongest) newLongest = newStreak;
    }

    

    await _saveStreak(db,userId, newStreak, newLongest, todayUtc.toIso8601String(), newFrozenUntil, newFreezeCount, now);


    try {
      await supabase.from('profiles').update({
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastActiveDate': todayUtc.toIso8601String(),
        'streakFrozenUntil': newFrozenUntil,
        'freezeCount': newFreezeCount,
      }).eq('id', userId);
    } catch (_) {}
  }

  Future<void> _saveStreak(
    Database db,
    String userId,
    int currentStreak,
    int longestStreak,
    String lastActiveDate,
    String? frozenUntil,
    int freezeCount, 
    String updatedAt,
  ) async {
    await db.insert(
      "user_streak",
      {
        "user_id": userId,
        "current_streak": currentStreak,
        "longest_streak": longestStreak,
        "last_active_date": lastActiveDate,
        "streak_frozen_until": frozenUntil,
        "freeze_count": freezeCount,
        "updated_at": updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

}