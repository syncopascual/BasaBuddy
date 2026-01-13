import 'package:basabuddy/screens/home.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:basabuddy/screens/module.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'components/HomeShell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [

    GoRoute(
      path: '/login',
      builder: (context, state) => Login(),
    ),


    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return HomeShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
          NoTransitionPage(child: Home()),
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
        GoRoute(
          path: '/b',
          pageBuilder: (context, state) =>
          NoTransitionPage(child: Home()),
        ),
        GoRoute(
          path: '/c',
          pageBuilder: (context, state) =>
          NoTransitionPage(child: Home()),
        ),
      ],
    ),
  ],
);
