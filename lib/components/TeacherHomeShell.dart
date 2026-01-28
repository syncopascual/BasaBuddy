import 'package:basabuddy/components/TopAppBarTeacher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../colors.dart';

///A sort of wrapper around the whole app, contains the bottom navigation bar
class TeacherHomeShell extends StatefulWidget {
  final Widget child;

  const TeacherHomeShell({required this.child, super.key});
  
  @override
  State<TeacherHomeShell> createState() => _TeacherHomeShellState();
}
class _TeacherHomeShellState extends State<TeacherHomeShell> {
  String? teacherName;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchTeacherName();
  }

  Future<void> fetchTeacherName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      teacherName = profile?['name'] ?? 'Teacher';
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: TopAppBarTeacher(screenWidth, teacherName: teacherName!),
      body: widget.child,
    );
  }
}
