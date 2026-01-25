import 'package:flutter/material.dart';

import '../colors.dart';

class TopAppBarTeacher extends StatelessWidget implements PreferredSizeWidget{
  TopAppBarTeacher(this.screenWidth);

  final double screenWidth;
  @override
  Widget build(BuildContext context) {
    return AppBar(
        elevation: 0,
        backgroundColor: teacherAppBar,
        //title: const Text('lvl info'),
        leadingWidth: screenWidth * 0.5, //TODO:: make more responsive
        leading:
            ///clock and time today
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [

          Container(
            margin: EdgeInsets.fromLTRB(screenWidth * 0.08, 0, screenWidth * 0.02, 0),
            child: ImageIcon(
              const AssetImage("assets/icons/profile.png"),
              color: profileIcon,
            ),
          ),

        Center(
        child: Text("Ma'am Cruz",
        style: TextStyle(color: topBarText)
        ),
        ),
        ]),

        );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);///irdk what this does cry emoji cry emoji
}