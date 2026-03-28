import 'package:basabuddy/components/QuestionPopup.dart';
import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../models/matchingData.dart';
import 'MatchColumns.dart';


class MatchingExercise extends StatefulWidget {
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
  State<MatchingExercise> createState() => _MatchingExerciseState();
}

class _MatchingExerciseState extends State<MatchingExercise> {
  bool soundEnabled = false;

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
              SingleChildScrollView( 
                child: MatchColumns(
                pairs: widget.matchingData.pairs,
                soundEnabled: soundEnabled,
                onCompleted: ()
                   => correctPopup(context, widget.onCorrect)
                ,
              ),),

              const SizedBox(height:16),
              Container(
                padding: EdgeInsets.only(top:12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Read words aloud", style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => soundEnabled = !soundEnabled),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: soundEnabled? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              soundEnabled ? Icons.volume_up : Icons.volume_off,
                              size: 16,
                              color: soundEnabled ? Colors.blue.shade700 : Colors.grey,
                            ),
                            SizedBox(width: 6),
                            Text(
                              soundEnabled ? "On" : "Off",
                              style: TextStyle(
                                fontSize: 13,
                                color: soundEnabled ? Colors.blue.shade700 : Colors.grey,
                              ),
                            ),
                          ],),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),


      ],
    );
  }
}
