import 'package:basabuddy/router.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//FOR TESTING PURPOSES ONLY, REMEMBER TO DIFFERENTIATE TEACHER/STUDENT WHEN SIGN IN PAGE IS MADE
//FOR TEST BRANCH ONLY, DO NOT MERGE TO MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sdyhiksgcibobqhcaofq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWhpa3NnY2lib2JxaGNhb2ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3OTE3NDMsImV4cCI6MjA4NDM2Nzc0M30.wqzcjBBDwBnkxWszrkMq-wxwH5O2WrBEEHgEKzWQdAY',
  );

  await Supabase.instance.client.auth.signInAnonymously();

  final user = Supabase.instance.client.auth.currentUser;
  print('Current user: ${Supabase.instance.client.auth.currentUser}');
  if (user != null) {
    await ensureProfileExists(user.id, defaultRole: 'teacher');
    await initializeUserData(user.id);
  }
  ///check if this is the user's first time logging in

  runApp(const MyApp());
}

Future<void> ensureProfileExists(String userId, {String defaultRole = 'teacher'}) async {
  //check if there's a profile already in profiles table
  final profileCheck = await Supabase.instance.client
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .maybeSingle(); 
  print('Profile Check Result: ${profileCheck}');
  //if none, make an entry
  if (profileCheck == null) {
    await Supabase.instance.client.from('profiles').insert({
      'id': userId,
      'role': defaultRole,
      'name': 'anon'
    });
    final classesCheck = await Supabase.instance.client
      .from('teacher_classes')
      .select('classes')
      .eq('id', userId)
      .maybeSingle();

  if (classesCheck == null) {
    await Supabase.instance.client.from('teacher_classes').insert({
      'id': userId,
      'classes': ['Class A', 'Class B', 'Class C'],
    });
  }
  }

}
Future<void> initializeUserData(String userId) async {
  final profileRes = await Supabase.instance.client
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .maybeSingle();

  final role = profileRes?['role'] ?? 'student';

  if(role == "student"){
    final levelInfo = await Supabase.instance.client
      .from('user_current_story_progress')
      .select();

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
  } else if(role == "teacher"){
    final teacherInfo = await Supabase.instance.client
        .from('teacher_classes')
        .select('id')
        .eq('id', userId);

    if (teacherInfo.isEmpty) {
      await Supabase.instance.client.from('teacher_classes').insert({
        'id': userId,
        'classes': [], // default empty list
      });
    }
  }  
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


