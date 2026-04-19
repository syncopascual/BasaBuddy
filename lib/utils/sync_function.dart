import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> syncTable({
  required String tableName,
  required String userId,
  required Database db,
  required SupabaseClient supabase,
  required List<String> syncColumns, // columns to sync (excluding id, user_id, updated_at)
  String remoteTable = '', // optional: if remote table name differs from local
}) async {
  print("syncing $tableName for userId $userId");
  final remote = remoteTable.isEmpty ? tableName : remoteTable;

  print("1.5");
  // Fetch remote row
  final remoteRes = await supabase
      .from(remote)
      .select()
      .eq('user_id', userId)
      .single();

  print("2");
  // Fetch local row
  final localRows = await db.query(
    tableName,
    where: 'user_id = ?',
    whereArgs: [userId],
  );

  print("3");
  final remoteUpdatedAt = DateTime.parse(remoteRes['updated_at']);
  final localUpdatedAt = localRows.isNotEmpty && localRows.first['updated_at'] != null
      ? DateTime.parse(localRows.first['updated_at'] as String)
      : DateTime.fromMillisecondsSinceEpoch(0);

  if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
    print("4");
    // Remote is newer — update local
    final Map<String, dynamic> localData = {
      'user_id': userId,
      'updated_at': remoteRes['updated_at'],
    };
    for (final col in syncColumns) {
      localData[col] = remoteRes[col];
    }
    await db.insert(tableName, localData, conflictAlgorithm: ConflictAlgorithm.replace);
  } else {
    // Local is newer — push to remote
    if (localRows.isEmpty) return;
    final Map<String, dynamic> remoteData = {
      'user_id': userId,
      'updated_at': localRows.first['updated_at'],
    };
    for (final col in syncColumns) {
      remoteData[col] = localRows.first[col];
    }
    await supabase.from(remote).upsert(remoteData, onConflict: 'user_id',);
  }
  print("successful sync function!");
}