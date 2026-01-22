import 'package:basabuddy/router.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sdyhiksgcibobqhcaofq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWhpa3NnY2lib2JxaGNhb2ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3OTE3NDMsImV4cCI6MjA4NDM2Nzc0M30.wqzcjBBDwBnkxWszrkMq-wxwH5O2WrBEEHgEKzWQdAY',
  );

  await Supabase.instance.client.auth.signInAnonymously();

  ///check if this is the user's first time logging in

  final levelInfo = await Supabase.instance.client
      .from('user_current_story_progress')
      .select();

  ///if user data doesnt exist, insert user data
  if(levelInfo.isEmpty){
    await Supabase.instance.client
        .from('user_level_info')
        .insert({
      'vocab_lvl': 1,
      'narrative_lvl': 1,
      'information_lvl': 1,
    });
  }

  final money = await Supabase.instance.client
      .from('user_money')
      .select();

  ///if user money doesnt exist, insert
  if(money.isEmpty){
    await Supabase.instance.client
        .from('user_money')
        .insert({
      'money': 0,
    });
  }

  runApp(const MyApp());
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


