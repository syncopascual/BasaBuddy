import 'package:basabuddy/components/QuestionPopup.dart';
import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../models/matchingData.dart';
import 'MatchColumns.dart';


class MatchingExercise extends StatelessWidget {
  final MatchingData matchingData;
  final VoidCallback onCorrect;
  //final VoidCallback onWrong;

  const MatchingExercise({
    super.key,
    required this.matchingData,
    required this.onCorrect,
    //required this.onWrong
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 10,),

        ///Exercise Label
        Container(
          margin: EdgeInsets.only(left: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected,
            borderRadius: BorderRadius.all(Radius.circular(45)),
          ),
          //height:60,
          width: 100,
          child: Text("Exercise"),
        ),
        Container(height: 10,),

        Container(
        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(45)),
        ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tap the matching pairs",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),
              SingleChildScrollView( child: MatchColumns(
                pairs: matchingData.pairs,
                onCompleted: ()
                   => correctPopup(context, onCorrect)
                ,
              ),),
            ],
          ),
        ),


      ],
    );
  }
}
