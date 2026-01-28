import 'package:basabuddy/router.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sdyhiksgcibobqhcaofq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWhpa3NnY2lib2JxaGNhb2ZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3OTE3NDMsImV4cCI6MjA4NDM2Nzc0M30.wqzcjBBDwBnkxWszrkMq-wxwH5O2WrBEEHgEKzWQdAY',
  );


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


