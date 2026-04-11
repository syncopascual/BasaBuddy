import 'package:basabuddy/bloc/theme_bloc.dart';
import 'package:basabuddy/components/TopAppBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/connectivity_bloc.dart';
import '../bloc/money_bloc.dart';
import '../bloc/translation_bloc.dart';
import '../bloc/freeze_bloc.dart';
import '../colors.dart';

///A sort of wrapper around the whole app, contains the bottom navigation bar

class StudentHomeShell extends StatefulWidget {
  final Widget child;
  const StudentHomeShell({required this.child});

  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}
class _StudentHomeShellState extends State<StudentHomeShell> {
  late final MoneyBloc moneyBloc;
  late final TranslationBloc translationBloc;
  late final ThemeBloc themeBloc;
  late final FreezeBloc freezeBloc;
  

  @override
  void initState() {
    super.initState();
    moneyBloc = MoneyBloc()..add(SyncMoney());
    translationBloc = TranslationBloc();
    themeBloc = ThemeBloc();
    freezeBloc = FreezeBloc();
  }

  @override
  void dispose() {
    moneyBloc.close();
    translationBloc.close();
    themeBloc.close();
    freezeBloc.close();
    super.dispose();
  }


  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/student/progressScreen')) return 1;
    if (location.startsWith('/student/profileScreen')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student/home');
        break;
      case 1:
        context.go('/student/progressScreen');
        break;
      case 2:
        context.go('/student/profileScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(context);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return const SizedBox.shrink();
      }
    };
    double screenWidth = MediaQuery.of(context).size.width;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: moneyBloc),
        BlocProvider.value(value: translationBloc),
        BlocProvider.value(value: themeBloc),
        BlocProvider.value(value: freezeBloc),
        BlocProvider(lazy: false, create: (_) => GetIt.instance<ConnectivityBloc>()),
      ],
      child: Scaffold(
        appBar: TopAppBar(screenWidth),
        body: widget.child,
        bottomNavigationBar: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (BuildContext context, state) {
            return BottomNavigationBar(
              backgroundColor: moduleTheme[state.theme]!['bottomBarBg'],
              currentIndex: currentIndex,
              onTap: (index) => _onTap(context, index),
              items: [
                BottomNavigationBarItem(

                    icon: const ImageIcon(
                      AssetImage("assets/icons/home.png"),
                    ),
                    label: 'home'),
                const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'progress'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'profile'),
              ],
            );
          },

        ),
      ),
    );
  }
}
