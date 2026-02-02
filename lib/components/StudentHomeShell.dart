import 'package:basabuddy/components/TopAppBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/money_bloc.dart';
import '../bloc/translation_bloc.dart';
import '../colors.dart';

///A sort of wrapper around the whole app, contains the bottom navigation bar
class StudentHomeShell  extends StatelessWidget {
  final Widget child;
  final MoneyBloc moneyBloc = MoneyBloc();
  final TranslationBloc translationBloc = TranslationBloc();

  StudentHomeShell({required this.child});

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
        context.go('/student/profileScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(context);
    final user = Supabase.instance.client.auth.currentUser!;
    double screenWidth = MediaQuery.of(context).size.width;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
            lazy: false,
            create: (BuildContext context) => moneyBloc..add(SyncMoney())),
        BlocProvider(
            lazy: false,
            create: (BuildContext context) => translationBloc),
      ],
      child: Scaffold(
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
      ),
    );
  }
}
