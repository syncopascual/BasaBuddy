import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

Future<void> createTableFromCsv({
  required Database db,
  required String tableName,
  required String csvPath,
}) async {
  print("createTableFromCsv $tableName");
  // Check if table already exists
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [tableName],
  );

  if (result.isNotEmpty) {
    print("Table $tableName already exists. Skipping import.");
    return;
  }


  // Read and parse CSV
  final csvString = (await rootBundle.loadString(csvPath))
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  final List<List<dynamic>> csvTable = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(csvString);

  //final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

  if (csvTable.isEmpty) throw Exception("CSV file is empty: $csvPath");
  if (csvTable.length < 2) throw Exception("CSV has no data rows: $csvPath");

  final List<String> headers = csvTable.first.map((e) => e.toString()).toList();
  final List<dynamic> firstDataRow = csvTable[1];

  String _inferType(dynamic value) {
    // Handle native Dart types first (CsvToListConverter may parse these)
    if (value is int) return 'INTEGER';
    if (value is double) return 'REAL';

    final str = value.toString().trim();

    // Numeric
    if (int.tryParse(str) != null) return 'INTEGER';
    if (double.tryParse(str) != null) return 'REAL';

    // UUID — e.g. 550e8400-e29b-41d4-a716-446655440000
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (uuidRegex.hasMatch(str)) return 'TEXT'; // store as TEXT, UUIDs have no SQLite native type

    // JSONB — starts with { or [
    try {
      final trimmed = str.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        jsonDecode(trimmed); // validates it's actually JSON
        return 'TEXT'; // store as TEXT, query with JSON SQLite functions if needed
      }
    } catch (_) {}

    // Timestamp — e.g. 2024-01-15 10:30:00+00 or 2024-01-15T10:30:00.000Z
    final timestampRegex = RegExp(
      r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}',
    );
    if (timestampRegex.hasMatch(str)) return 'TEXT'; // store as TEXT, SQLite has no native timestamp

    // Date — e.g. 2024-01-15
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dateRegex.hasMatch(str)) return 'TEXT';

    return 'TEXT';
  }

  if (firstDataRow.length < headers.length) {
    print('WARNING: Header has ${headers.length} columns but first data row only has ${firstDataRow.length}');
    print('Headers: $headers');
    print('First row: $firstDataRow');
  }
  final String columns = List.generate(
    headers.length,
        (i) => '"${headers[i]}" ${_inferType(firstDataRow[i])}',
  ).join(', ');

  await db.execute("CREATE TABLE $tableName ($columns)");

  // Bulk insert using a transaction
  await db.transaction((txn) async {
    for (final row in csvTable.skip(1)) {
      final Map<String, dynamic> rowMap = {
        for (int i = 0; i < headers.length; i++)
          headers[i]: row[i],
      };
      await txn.insert(tableName, rowMap);
    }
  });

  print("Table $tableName created and populated with ${csvTable.length - 1} rows.");
}


Future<List<String>> getMissingTables(Database db, Iterable<String> tableNames) async {
  List<String> missingTables = [];

  for (String tableName in tableNames) {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );

    if (result.isEmpty) {
      missingTables.add(tableName);
    }
  }

  return missingTables;
}