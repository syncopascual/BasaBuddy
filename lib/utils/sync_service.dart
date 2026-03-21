import 'package:basabuddy/models/stageData.dart';
import 'package:basabuddy/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles saving StageData locally and syncing pending rows to Supabase.
///
/// Flow:
///   1. Always write to local `pending_stage_data` first.
///   2. Immediately attempt an upload — if it succeeds, delete the local row.
///   3. On reconnect (or app start), call [flushPending] to retry any rows
///      that failed earlier.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  static const _table = 'pending_stage_data';

  // ─── Schema ───────────────────────────────────────────────────────────────

  /// Call this inside DatabaseHelper._onCreate so the table is created with
  /// the rest of your local schema.
  static String get createTableSql => '''
    CREATE TABLE $_table (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id     TEXT    NOT NULL,
      story_id    TEXT    NOT NULL,
      skill       TEXT    NOT NULL,
      total_items INTEGER NOT NULL,
      total_attempts      INTEGER NOT NULL,
      first_attempt_correct INTEGER NOT NULL,
      date        TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL
    )
  ''';

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Save [data] locally, then immediately attempt to push it to Supabase.
  /// If the push fails (offline / timeout), the row stays in the local table
  /// and will be retried the next time [flushPending] is called.
  Future<void> saveAndSync(StageData data) async {
    final localId = await _insertLocal(data);
    final uploaded = await _uploadOne(data);
    if (uploaded) {
      await _deleteLocal(localId);
    }
    // If not uploaded, the row stays in pending_stage_data for later.
  }

  /// Try to push every pending local row to Supabase.
  /// Call this on app start and whenever the connectivity bloc signals that
  /// the device is back online.
  Future<void> flushPending() async {
    final rows = await _loadPending();
    if (rows.isEmpty) return;

    print('SyncService: flushing ${rows.length} pending row(s)');

    for (final row in rows) {
      final id = row['id'] as int;
      final data = StageData(
        userId: row['user_id'] as String,
        storyId: row['story_id'] as String,
        skill: row['skill'] as String,
        totalItems: row['total_items'] as int,
        totalAttempts: row['total_attempts'] as int,
        firstAttemptCorrect: row['first_attempt_correct'] as int,
        date: row['date'] as String,
        updatedAt: row['updated_at'] as String,
      );

      final uploaded = await _uploadOne(data);
      if (uploaded) {
        await _deleteLocal(id);
        print('SyncService: synced and removed local id=$id');
      } else {
        // Stop trying further rows if the first upload already failed —
        // the device is likely still offline.
        print('SyncService: upload failed, stopping flush for now');
        break;
      }
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<int> _insertLocal(StageData data) async {
    final database = await DatabaseHelper.instance.db;
    final id = await database.insert(
      _table,
      {
        'user_id': data.userId,
        'story_id': data.storyId,
        'skill': data.skill,
        'total_items': data.totalItems,
        'total_attempts': data.totalAttempts,
        'first_attempt_correct': data.firstAttemptCorrect,
        'date': data.date,
        'updated_at': data.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('SyncService: saved locally as id=$id');
    return id;
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    final database = await DatabaseHelper.instance.db;
    return database.query(_table, orderBy: 'id ASC');
  }

  Future<void> _deleteLocal(int id) async {
    final database = await DatabaseHelper.instance.db;
    await database.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns true only when the row was successfully inserted in Supabase.
  Future<bool> _uploadOne(StageData data) async {
    try {
      await Supabase.instance.client
          .from('stage_level')
          .insert(data.toJson())
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      print('SyncService: upload failed – $e');
      return false;
    }
  }
}