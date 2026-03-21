import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:basabuddy/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';


Future<void> syncUserProgress() async {
  print("SYNC USER PROGRESS CALLED");
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return;

  final userId = user.id;

  final db = await DatabaseHelper.instance.db;

  try {

    //Get remote module levels and update local database. (What about local -> supabase? Check later)
    final levelRes = await supabase
        .from('user_level_info')
        .select('vocab_lvl, narrative_lvl, information_lvl, updated_at')
        .eq('user_id', userId)
        .single();
    
    final localLevel = await db.query('user_level_info', where: 'user_id = ?', whereArgs: [userId]);
    final remoteUpdatedAt = DateTime.parse(levelRes['updated_at']);
    final localUpdatedAt = localLevel.isNotEmpty && localLevel.first['updated_at'] != null
        ? DateTime.parse(localLevel.first['updated_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0);

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      // Remote is newer, update local
      await db.insert('user_level_info', {
        'user_id': userId,
        'vocab_lvl': levelRes['vocab_lvl'],
        'narrative_lvl': levelRes['narrative_lvl'],
        'information_lvl': levelRes['information_lvl'],
        'updated_at': levelRes['updated_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      // Local is newer, push to remote
      await supabase.from('user_level_info').upsert({
        'user_id': userId,
        'vocab_lvl': localLevel.first['vocab_lvl'],
        'narrative_lvl': localLevel.first['narrative_lvl'],
        'information_lvl': localLevel.first['information_lvl'],
        'updated_at': localLevel.first['updated_at'],
      });
    }

    //Get user's stage levels (user's completed stories - one row for each story + skill combo). Local -> supabase, supabase -> local database. What about conflicts? Say, did stories offline then went online, or did stories online then went offline.
    final localStages = await db.query(
      'stage_level',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (final row in localStages) {
      await supabase.from('stage_level').upsert(row);
    }

    final remoteStages = await supabase
      .from('stage_level')
      .select()
      .eq('user_id', userId);

    for (final row in remoteStages) {
      await db.insert(
        'stage_level',
        {
          'user_id': row['user_id'],
          'story_id': row['story_id'],
          'skill': row['skill'],
          'total_items': row['total_items'],
          'total_attempts': row['total_attempts'],
          'first_attempt_correct': row['first_attempt_correct'],
          'date': row['date'],
          'updated_at': row['updated_at']
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    //Get supabase's streak info, update local database. When should the streak info for remote be updated then?
    final response = await supabase
    .from('profiles')
    .select('currentStreak, longestStreak, lastActiveDate, streakFrozenUntil, updated_at')
    .eq('id', userId)
    .single();

    final localStreak = await db.query('user_streak',
        where: 'user_id = ?', whereArgs: [userId]);

    final remoteStreakUpdatedAt = DateTime.parse(response['updated_at']);
    final localStreakUpdatedAt = localStreak.isNotEmpty && localStreak.first['updated_at'] != null
        ? DateTime.parse(localStreak.first['updated_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0);

    if (remoteStreakUpdatedAt.isAfter(localStreakUpdatedAt)) {
      // Remote is newer, update local
      await db.insert('user_streak', {
        'user_id': userId,
        'current_streak': response['currentStreak'],
        'longest_streak': response['longestStreak'],
        'last_active_date': response['lastActiveDate'],
        'streak_frozen_until': response['streakFrozenUntil'],
        'updated_at': response['updated_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      // Local is newer, push to remote
      await supabase.from('profiles').update({
        'currentStreak': localStreak.first['current_streak'],
        'longestStreak': localStreak.first['longest_streak'],
        'lastActiveDate': localStreak.first['last_active_date'],
        'streakFrozenUntil': localStreak.first['streak_frozen_until'],
        'updated_at': localStreak.first['updated_at'],
      }).eq('id', userId);
    }

  } catch (e) {
    print("Sync failed (probably offline): $e");
  }
}