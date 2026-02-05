import 'package:basabuddy/components/question_components/MulchoExercise.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/screens/student/home.dart';
import 'package:basabuddy/screens/teacher/home.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:basabuddy/screens/signup.dart';
import 'package:basabuddy/screens/student/module.dart';
import 'package:basabuddy/screens/student/storyShell.dart';
import 'package:basabuddy/screens/student/profileScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'components/StudentHomeShell.dart';
import 'components/TeacherHomeShell.dart';

import 'models/story.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _shellTeacherNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => Login(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => Signup(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return StudentHomeShell(child: child);
      },
      routes: [
        ///Home Route
        GoRoute(
          path: '/student/home',
          pageBuilder: (context, state) => NoTransitionPage(child: StudentHome()),
          routes: [
            GoRoute(
              path: 'module/:moduleType',
              builder: (context, state) {
                final moduleType = state.pathParameters['moduleType']!;
                return Module(moduleType);
              },
            ),
          ],
        ),

        ///Story Route -> Not sure if this is the best placement
        GoRoute(
          path: '/story/:storyId',
          pageBuilder: (context, state) {
            final storyId = state.pathParameters['storyId']!;
            return NoTransitionPage(child: StoryShell(storyId: storyId));
          },
        ),

        GoRoute(
          path: '/b',
          pageBuilder: (context, state) => NoTransitionPage(child: StudentHome()),
        ),
        GoRoute(
          path: '/student/profileScreen',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey, 
            child: ProfileScreen(), 
          ),
        ),
      ],
    ),
    ShellRoute(
      navigatorKey: _shellTeacherNavigatorKey,
      builder: (context, state, child) {
        return TeacherHomeShell(child: child);
      },
      routes: [
        ///Student Home Route
        GoRoute(
          path: '/teacher/home',
          pageBuilder: (context, state) => NoTransitionPage(child: TeacherHome()),
          routes: [
          ],
        ),

  
      ],
    ),
  ],
);
