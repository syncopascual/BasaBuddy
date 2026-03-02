import 'package:basabuddy/screens/student/module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/bg_images/islands.png",
              fit: BoxFit.cover,
            ),),
          Positioned(
            top: 290,
            left: 170,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vocabButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                )),
              onPressed: (){
                context.push('/student/home/module/vocab');
              },
              child: Text("Vocab Island", style: TextStyle(color: textColor))),
          ),

          Positioned(
            top: 440,
            left: 190,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: informationButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                )),
              onPressed: (){
                context.push('/student/home/module/information');
              },
              child: Text("Knowledge Island", style: TextStyle(color: textColor))),
          ),

          Positioned(
            top: 550,
            left: 25,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                backgroundColor: narrativeButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                )),
                onPressed: (){
                  context.push('/student/home/module/narrative');
                },
                child: Text("Story Island", style: TextStyle(color: textColor))),
          ),
          Positioned(
            top: 340,
            left: -20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teachersPickButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                )),
              onPressed: () {
                context.push('/student/home/module/teachers_pick');
              },
              child: Text("Teachers' Pick Island", style: TextStyle(color: textColor)),
            ),
          ),

        ]
      ),
       );
  }
}