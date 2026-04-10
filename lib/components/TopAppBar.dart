import 'package:basabuddy/bloc/money_bloc.dart';
import 'package:basabuddy/bloc/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:basabuddy/components/StreakServices.dart';
import 'package:basabuddy/components/StreakNotifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../colors.dart';

class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double screenWidth;
  const TopAppBar(this.screenWidth, {super.key});

  @override
  State<TopAppBar> createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopAppBarState extends State<TopAppBar> {
  int? streak;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }
  Future<void> _loadStreak() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final fetchedStreak = await StreakService().getCurrentStreak(user.id);
      print("FETCHED STREAK: $fetchedStreak");
      streakNotifier.value = fetchedStreak;
    } catch (e) {
      print("Error fetching streak: $e");
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (BuildContext context, state) {
        return AppBar(
            elevation: 0,
            backgroundColor: moduleTheme[state.theme]!['topBarBg'],
            //title: const Text('lvl info'),
            leadingWidth: widget.screenWidth * 0.5, //TODO:: make more responsive
            leading:
            ///clock and time today
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [

              Container(
                margin: EdgeInsets.fromLTRB(widget.screenWidth * 0.08, 0, widget.screenWidth * 0.02, 0),
                child: ImageIcon(
                  const AssetImage("assets/icons/clock.png"),
                  color: clockIcon,
                ),
              ),

              Center(
                child: Text("5:00",
                    style: TextStyle(color: moduleTheme[state.theme]!['bottomBarUnselectedIcon'])
                ),
              ),
            ]),
            actions: [
              ///fire and streak
              ImageIcon(
                const AssetImage("assets/icons/fire.png"),
                color: fireIcon,
              ),
              ValueListenableBuilder<int>(
                valueListenable: streakNotifier,
                builder: (context, streakValue, _) {
                  return Container(
                    margin: EdgeInsets.fromLTRB(0, 0, widget.screenWidth * 0.03, 0),
                    child: Text(streakValue.toString(),
                        style: TextStyle(color: moduleTheme[state.theme]!['bottomBarUnselectedIcon'])),
                  );},),

              ///gem icon -> workaround to keep original colors!
              IconButton(
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // No press effect
                  minimumSize: WidgetStateProperty.all(Size.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                padding: EdgeInsets.all(0),
                icon: Image.asset(
                  'assets/icons/crystal.png',
                  width: IconTheme.of(context).size,
                  height: IconTheme.of(context).size,
                ),

                onPressed: () {},
              ),

              Container(
                margin: EdgeInsets.fromLTRB(0, 0, widget.screenWidth * 0.04, 0),
                child: BlocBuilder<MoneyBloc, MoneyState>(
                    builder: (_, moneyState){
                      return Text("${moneyState.money}",
                          style: TextStyle(color: moduleTheme[state.theme]!['bottomBarUnselectedIcon']));
                    }
                ),
              ),

              ImageIcon(
                const AssetImage("assets/icons/leaves.png"),
                color: leavesIcon,
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, widget.screenWidth * 0.08, 0),
                child: Text("123",
                    style: TextStyle(color: moduleTheme[state.theme]!['bottomBarUnselectedIcon'])),
              ),

            ]);
      },

    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);///irdk what this does cry emoji cry emoji
}