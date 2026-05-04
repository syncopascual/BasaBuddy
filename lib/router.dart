import 'package:basabuddy/components/question_components/MulchoExercise.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/screens/student/home.dart';
import 'package:basabuddy/screens/student/onboarding.dart';
import 'package:basabuddy/screens/student/diagnosticExam.dart';
import 'package:basabuddy/screens/teacher/content_detail.dart';
import 'package:basabuddy/screens/teacher/home.dart';
import 'package:basabuddy/screens/login.dart';
import 'package:basabuddy/screens/signup.dart';
import 'package:basabuddy/screens/student/module.dart';
import 'package:basabuddy/screens/student/storyShell.dart';
import 'package:basabuddy/screens/student/profileScreen.dart';
import 'package:basabuddy/screens/student/progressScreen.dart';
import 'package:basabuddy/screens/teacher/add_story_page.dart';
import 'package:basabuddy/screens/teacher/add_questions_page.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/connectivity_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'components/StudentHomeShell.dart';
import 'components/TeacherHomeShell.dart';

import 'models/story.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _shellTeacherNavigatorKey = GlobalKey<NavigatorState>();

class TeacherWrapper extends StatelessWidget {
  final Widget child;

  const TeacherWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        BlocBuilder<ConnectivityBloc, ConnectivityState>(
          builder: (context, state) {
            if (state is ConnectivityFailure) {
              return const NoInternetOverlay();
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class NoInternetOverlay extends StatelessWidget {
  const NoInternetOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D9E75),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                "No Internet Connection",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please check your connection and try again.",
                style: TextStyle(fontSize: 15, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/student/diagnostic',
      builder: (context, state) => const DiagnosticExamScreen(),
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
          path: '/story/:storyId/:storyLevel',
          pageBuilder: (context, state) {
            print("ROUTER EXTRA: ${state.extra}");
            final storyId = state.pathParameters['storyId']!;
            final storyLevel = int.parse(state.pathParameters['storyLevel']!);
            final isTeacher = state.extra as bool? ?? false;
            return NoTransitionPage(
              child: StoryShell(
                storyId: storyId,
                storyLevel: storyLevel,
                isTeacherStory: isTeacher,
              ),
            );
          },
        ),

        GoRoute(
          path: '/student/progressScreen',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: ProgressScreen()),
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
        return TeacherWrapper(
          child: TeacherHomeShell(child: child),
        );
      },
      routes: [
        ///Student Home Route
        GoRoute(
          path: '/teacher/home',
          pageBuilder: (context, state) => NoTransitionPage(child: TeacherHome()),
          routes: [
          ],
        ),
        GoRoute(
          path: '/teacher/add_story_page',
          pageBuilder: (context, state) {
            final classId = state.extra as String;
            print("OUR CLASS ID ${classId}");
            return NoTransitionPage(child: AddStoryPage(classId: classId));
          }
        ),
        GoRoute(
          path: '/teacher/add_questions_page',
          pageBuilder: (context, state) {
            final classId = state.extra as String;
            print("ADD QUESTIONS PAGE");
            return NoTransitionPage(child: AddStagePage(classId: classId));
          }
        ),
        GoRoute(
          path: '/teacher/content_detail',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return ContentDetailPage(
              storyId: data['storyId'],
              isStory: data['isStory'],
            );
          }
        ),
  
      ],
    ),
  ],
);
