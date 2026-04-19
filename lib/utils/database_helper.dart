import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;


  DatabaseHelper._instance();

  Future<Database> get db async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'basabuddy.db');
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade,);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final now = DateTime.now().toUtc().toIso8601String();
      await db.execute("ALTER TABLE stage_level ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE user_level_info ADD COLUMN updated_at TEXT");
      await db.execute("ALTER TABLE user_streak ADD COLUMN updated_at TEXT");

      // Backfill existing rows with current timestamp
      await db.execute("UPDATE stage_level SET updated_at = '$now'");
      await db.execute("UPDATE user_level_info SET updated_at = '$now'");
      await db.execute("UPDATE user_streak SET updated_at = '$now'");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          user_id TEXT PRIMARY KEY,
          diagnostic_completed INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_money (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        money INTEGER,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_exp (
        id INTEGER,
        user_id TEXT PRIMARY KEY,
        narrative_exp INTEGER,
        vocab_exp INTEGER,
        information_exp INTEGER,
        updated_at TEXT
      )
    ''');


    await db.execute('''
        CREATE TABLE stage_level (
          user_id TEXT,
          story_id TEXT,
          skill TEXT,
          total_items INTEGER,
          total_attempts INTEGER,
          first_attempt_correct INTEGER,
          date TEXT,
          updated_at TEXT,
          PRIMARY KEY (user_id, story_id, skill, date)
        )
      ''');

    await db.execute('''
      CREATE TABLE user_level_info (
        user_id TEXT PRIMARY KEY,
        vocab_lvl INTEGER,
        narrative_lvl INTEGER,
        information_lvl INTEGER,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_streak (
        user_id TEXT PRIMARY KEY,
        current_streak INTEGER,
        longest_streak INTEGER,
        last_active_date TEXT,
        streak_frozen_until TEXT,
        updated_at TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE user_settings (
        user_id TEXT PRIMARY KEY,
        diagnostic_completed INTEGER DEFAULT 0,
        updated_at TEXT
      )
      ''');



  }


  Future<List<T>> queryAll<T>(
      String table,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final Database database = await db;
    final result = await database.rawQuery('SELECT * FROM $table');
    return result.map((row) => fromJson(row)).toList();
  }

  // Add a row
  Future<void> add<T>(
      String table,
      T item,
      Map<String, dynamic> Function() toJson,
      ) async {
    final Database database = await db;
    await database.insert(table, toJson());
  }

  Future<List<T>> queryWhere<T>(
      String table,
      T Function(Map<String, dynamic>) fromJson,
      String where,
      List<dynamic> whereArgs,
      )
  async {
    final Database database = await db;
    final result = await database.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    //print("query where result $result");
    return result.map((row) {
      final decoded = Map<String, dynamic>.from(row);
      // Decode any JSON string fields back into Maps
      for (final key in decoded.keys.toList()) {
        final value = decoded[key];
        if (value is String) {
          try {
            final parsed = jsonDecode(value);
            if (parsed is Map) {
              decoded[key] = Map<String, dynamic>.from(parsed);
            } else if (parsed is List) {          // ← add this
              decoded[key] = List<dynamic>.from(parsed);
            }
          } catch (_) {
            // Not a JSON string, leave as-is
          }
        }
      }


      return fromJson(decoded);
    }).toList();
  }









  // Set diagnostic completed for a user -> the value will be the level the user is placed in
  Future<void> setDiagnosticCompleted(String userId, int level) async {
    final Database database = await db;
    final existing = await database.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (existing.isEmpty) {
      await database.insert('user_settings', {
        'user_id': userId,
        'diagnostic_completed': level,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      await database.update(
        'user_settings',
        {
          'diagnostic_completed': level,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  // Get the placed level from diagnostic
  Future<int> getDiagnosticLevel(String userId) async {
    final Database database = await db;
    final result = await database.query(
      'user_level_info',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) return 1;
    // Return the average of all levels as placed level
    final vocab = result.first['vocab_lvl'] as int? ?? 1;
    final narrative = result.first['narrative_lvl'] as int? ?? 1;
    final information = result.first['information_lvl'] as int? ?? 1;
    return ((vocab + narrative + information) / 3).round().clamp(1, 5);
  }

  }