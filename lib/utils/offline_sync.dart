import 'package:basabuddy/utils/sync_function.dart';
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

  print("syncing stuff");
  try {
    print("start");
    ///Sync user exp
    await syncTable(
        tableName: 'user_exp',
        userId: userId,
        db: db,
        supabase: supabase,
        syncColumns:['narrative_exp', 'information_exp', 'vocab_exp']
        );


    ///Sync diagnostic test
    await syncTable(
        tableName: 'user_settings',
        userId: userId,
        db: db,
        supabase: supabase,
        syncColumns:['diagnostic_completed']
    );

    print("synced 2.5");
    ///Sync user money
    await syncTable(
        tableName: 'user_money',
        userId: userId,
        db: db,
        supabase: supabase,
        syncColumns:['money']
    );
    print("synced 3");


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

    print("synced 3.5");
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

    print("synced 4");

    //Get user's stage levels (user's completed stories - one row for each story + skill combo). Local -> supabase, supabase -> local database. What about conflicts? Say, did stories offline then went online, or did stories online then went offline.
    final localStages = await db.query(
      'stage_level',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (final row in localStages) {
      try {
        await supabase.from('stage_level').upsert({
          'user_id': row['user_id'],
          'story_id': row['story_id'],
          'skill': row['skill'],
          'date': row['date'],
          'total_items': row['total_items'],
          'total_attempts': row['total_attempts'],
          'first_attempt_correct': row['first_attempt_correct'],
          'updated_at': row['updated_at'],
        }, onConflict: 'user_id, story_id, skill, date'); // ← specify conflict columns
      } catch(e) {
        print("Failed to sync row for ${row['skill']}: $e");
      }
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



    final remoteBoost = await supabase
      .from('user_boosts')
      .select('stories_remaining, updated_at')
      .eq('user_id', userId)
      .maybeSingle();

  final localBoost = await db.query('user_boosts',
      where: 'user_id = ?', whereArgs: [userId]);

  if (remoteBoost == null && localBoost.isNotEmpty) {
    await supabase.from('user_boosts').upsert({
      'user_id': userId,
      'stories_remaining': localBoost.first['stories_remaining'],
      'updated_at': localBoost.first['updated_at'],
    }, onConflict: 'user_id');
  } else if (remoteBoost != null && localBoost.isEmpty) {
    await db.insert('user_boosts', {
      'user_id': userId,
      'stories_remaining': remoteBoost['stories_remaining'],
      'updated_at': remoteBoost['updated_at'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  } else if (remoteBoost != null && localBoost.isNotEmpty) {
    final remoteAt = DateTime.parse(remoteBoost['updated_at']);
    final localAt = DateTime.parse(localBoost.first['updated_at'] as String);
    if (remoteAt.isAfter(localAt)) {
      await db.insert('user_boosts', {
        'user_id': userId,
        'stories_remaining': remoteBoost['stories_remaining'],
        'updated_at': remoteBoost['updated_at'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await supabase.from('user_boosts').upsert({
        'user_id': userId,
        'stories_remaining': localBoost.first['stories_remaining'],
        'updated_at': localBoost.first['updated_at'],
      }, onConflict: 'user_id');
    }
  }

  } catch (e) {
    print("Sync failed (probably offline): $e");
  }
}