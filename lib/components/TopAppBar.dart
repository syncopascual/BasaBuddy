import 'package:basabuddy/bloc/money_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../colors.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget{
  TopAppBar(this.screenWidth);

  final double screenWidth;
  @override
  Widget build(BuildContext context) {
    return AppBar(
        elevation: 0,
        backgroundColor: x2Coins,
        //title: const Text('lvl info'),
        leadingWidth: screenWidth * 0.5, //TODO:: make more responsive
        leading:
            ///clock and time today
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [

          Container(
            margin: EdgeInsets.fromLTRB(screenWidth * 0.08, 0, screenWidth * 0.02, 0),
            child: ImageIcon(
              const AssetImage("assets/icons/clock.png"),
              color: clockIcon,
            ),
          ),

        Center(
        child: Text("5:00",
        style: TextStyle(color: topBarText)
        ),
        ),
        ]),
        actions: [
          ///fire and streak
          ImageIcon(
            const AssetImage("assets/icons/fire.png"),
            color: fireIcon,
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, screenWidth * 0.03, 0),
            child: Text("5",
                style: TextStyle(color: topBarText)),
          ),

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
            margin: EdgeInsets.fromLTRB(0, 0, screenWidth * 0.04, 0),
            child: BlocBuilder<MoneyBloc, MoneyState>(
              builder: (_, state){
                return Text("${state.money}",
                    style: TextStyle(color: topBarText));
              }
            ),
          ),

          ImageIcon(
            const AssetImage("assets/icons/leaves.png"),
            color: leavesIcon,
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, screenWidth * 0.08, 0),
            child: Text("123",
                style: TextStyle(color: topBarText)),
          ),

        ]);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);///irdk what this does cry emoji cry emoji
}