import 'package:basabuddy/components/MulchoChoices.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../colors.dart';


///multiple choice exercise
class MulchoExercise extends StatefulWidget {

  final String bgImage;
  final Mulcho mulcho;
  const MulchoExercise({
    super.key,
    required this.bgImage,
    required this.mulcho
  });

  @override
  State<MulchoExercise> createState() => _MulchoExerciseState();
}

class _MulchoExerciseState extends State<MulchoExercise> {
  final ValueNotifier<int> choiceIndex = ValueNotifier<int>(-1);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/${widget.bgImage}.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          ///Exercise Label

          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected,
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            //height:60,
            width: 100,
            child: Text("Exercise"),
          ),

          ///Question and Choices Body
          Container(
            padding: EdgeInsets.symmetric(horizontal: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            height: 500,
            child: Column(
              children: [
                Text(widget.mulcho.question, style: TextStyle(color: Colors.black),),
                Container(
                  height: 300,
                  child: MulchoChoices(selectedContainerIndex: choiceIndex, choices: widget.mulcho.choices),
                )
              ],
            ),
          ),

        ],
      ),
    );
  }
}