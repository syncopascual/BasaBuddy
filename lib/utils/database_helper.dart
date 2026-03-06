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
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_money (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        money INTEGER
      )
      
      
      
    ''');
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
    return result.map((row) => fromJson(row)).toList();
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