import 'package:basabuddy/bloc/money_bloc.dart';
import 'package:basabuddy/bloc/translation_bloc.dart';
import 'package:basabuddy/router.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:basabuddy/utils/database_functions.dart';
import 'package:basabuddy/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sdyhiksgcibobqhcaofq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWhpa3NnY2lib2JxaGNhb2ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3OTE3NDMsImV4cCI6MjA4NDM2Nzc0M30.wqzcjBBDwBnkxWszrkMq-wxwH5O2WrBEEHgEKzWQdAY',
  );

  ///Setup database
  final db = await DatabaseHelper.instance.db;
  ///Setup story and questions data ---------------------------------
  final List<String> dataTableNames = [
    "fill_in_blank",
    "list_stories",
    "matching_exercise",
    "mulcho_exercise",
    "ordering_exercise",
    "story_page",
    "user_level_info",
    "user_money"
  ];
  List<String> missingTables = await getMissingTables(db, dataTableNames);


  if(missingTables.length == 0){
    print("Not first open -> Tables are already created");
  } else {
    ///if this is user's first open,
    ///or something went wrong with the last open
    ///create and populate missing tables
    for(String tableName in missingTables){
      await createTableFromCsv(db: db, tableName: tableName, csvPath: "csv_data/${tableName}_rows.csv");
    }
  }
  ///Setup user data
  final List<String> userDataTableNames = [
    "user_level_info",
    "user_money"
  ];


  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(fontFamily: 'Nunito'),
      routerConfig: router,
    );
  }
}


