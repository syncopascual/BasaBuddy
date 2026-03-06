import 'package:basabuddy/screens/student/module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../colors.dart';

class StudentHome  extends StatefulWidget {
  @override
  State<StudentHome > createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome > {

  int index = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg_images/islands.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(height:200),
            ///Vocab Island Button
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: vocabButton),
                onPressed: (){
                  context.push('/student/home/module/vocab');
                },
                child: Text("Vocab Island", style: TextStyle(color: textColor))),

            ///Information Island Button
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: informationButton),
                onPressed: (){
                  context.push('/student/home/module/information');
                },
                child: Text("Information Island", style: TextStyle(color: textColor))),

            ///Narrative Island Button
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: narrativeButton),
                onPressed: (){
                  context.push('/student/home/module/narrative');
                },
                child: Text("Narrative Island", style: TextStyle(color: textColor))),
            /// Teachers' Pick Island Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: teachersPickButton),
              onPressed: () {
                context.push('/student/home/module/teachers_pick');
              },
              child: Text("Teachers' Pick Island", style: TextStyle(color: textColor)),
            ),
          ],
        ),
      ),
       );
  }
}