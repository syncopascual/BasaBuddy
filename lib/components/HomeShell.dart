import 'package:basabuddy/components/TopAppBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';

///A sort of wrapper around the whole app, contains the bottom navigation bar
class StudentHomeShell  extends StatelessWidget {
  final Widget child;

  const StudentHomeShell({required this.child});

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/b')) return 1;
    if (location.startsWith('/c')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student/home');
        break;
      case 1:
        context.go('/b');
        break;
      case 2:
        context.go('/c');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(context);
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: TopAppBar(screenWidth),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: clockIcon,
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        items: [
          BottomNavigationBarItem(

              icon: const ImageIcon(
                AssetImage("assets/icons/home.png"),
              ),
              label: 'home'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'B'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'C'),
        ],
      ),
    );
  }
}
