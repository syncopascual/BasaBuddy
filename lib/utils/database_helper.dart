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
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade,);
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
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_money (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        money INTEGER
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
          PRIMARY KEY (user_id, story_id, skill)
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

    await db.insert('user_money', {
      'user_id': 'your_user_id',//TODO:: add actual user id from supabase?
      'money': 0,
    });
  }
  Future<T?> queryFirst<T>(
      String table,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    final Database database = await db;
    final result = await database.rawQuery('SELECT * FROM $table LIMIT 1');
    if (result.isEmpty) return null;
    return fromJson(result.first);
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
      ) async {
    final Database database = await db;
    final result = await database.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    print("query where");
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

// Update first matching row
  Future<void> updateFirst<T>(
      String table,
      Map<String, dynamic> values,
      String where,
      List<dynamic> whereArgs,
      ) async {
    final Database database = await db;
    await database.update(
      table,
      values,
      where: '$where LIMIT 1',
      whereArgs: whereArgs,
    );
  }

  Future<void> updateFirstNoWhere(String table, Map<String, dynamic> values) async {
    final Database database = await db;
    await database.update(table, values);
  }

// Update all matching rows
  Future<void> updateAll<T>(
      String table,
      Map<String, dynamic> values,
      String where,
      List<dynamic> whereArgs,
      ) async {
    final Database database = await db;
    await database.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

// Delete first matching row
  Future<void> deleteFirst(
      String table,
      String where,
      List<dynamic> whereArgs,
      ) async {
    final Database database = await db;
    await database.rawDelete(
      'DELETE FROM $table WHERE $where LIMIT 1',
      whereArgs,
    );
  }

// Delete all matching rows
  Future<void> deleteAll(
      String table,
      String where,
      List<dynamic> whereArgs,
      ) async {
    final Database database = await db;
    await database.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }


  }