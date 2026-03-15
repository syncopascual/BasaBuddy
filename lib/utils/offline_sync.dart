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
        .select('vocab_lvl, narrative_lvl, information_lvl')
        .eq('user_id', userId)
        .single();

    await db.insert(
      'user_level_info',
      {
        'user_id': userId,
        'vocab_lvl': levelRes['vocab_lvl'],
        'narrative_lvl': levelRes['narrative_lvl'],
        'information_lvl': levelRes['information_lvl'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

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
      print("ROW: $row");
      await db.insert(
        'stage_level',
        {
          'user_id': row['user_id'],
          'story_id': row['story_id'],
          'skill': row['skill'],
          'total_items': row['total_items'],
          'total_attempts': row['total_attempts'],
          'first_attempt_correct': row['first_attempt_correct'],
          'date': row['date']
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    //Get supabase's streak info, update local database. When should the streak info for remote be updated then?
    final response = await supabase
    .from('profiles')
    .select('currentStreak, longestStreak, lastActiveDate, streakFrozenUntil')
    .eq('id', userId)
    .single();

    await db.insert(
      'user_streak',
      {
        'user_id': userId,
        'current_streak': response['currentStreak'],
        'longest_streak': response['longestStreak'],
        'last_active_date': response['lastActiveDate'],
        'streak_frozen_until': response['streakFrozenUntil'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  } catch (e) {
    print("Sync failed (probably offline): $e");
  }
}