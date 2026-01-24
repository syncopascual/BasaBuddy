import 'package:basabuddy/components/TopAppBarTeacher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';

///A sort of wrapper around the whole app, contains the bottom navigation bar
class TeacherHomeShell extends StatelessWidget {
  final Widget child;

  const TeacherHomeShell({required this.child});
  
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: TopAppBarTeacher(screenWidth),
      body: child,
    );
  }
}