import 'package:basabuddy/components/question_components/MulchoChoices.dart';
import 'package:basabuddy/components/TranslationButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../colors.dart';
import 'package:basabuddy/components/VoiceService.dart';

import 'QuestionPopup.dart';


///multiple choice exercise
class DiagnosticExercise extends StatefulWidget {

  final String bgImage;
  final Mulcho mulcho;
  final VoidCallback onCorrectAnswer;
  final VoidCallback onWrongAnswer;
  const DiagnosticExercise({
    super.key,
    required this.bgImage,
    required this.mulcho,
    required this.onCorrectAnswer,
    required this.onWrongAnswer,

  });

  @override
  State<DiagnosticExercise> createState() => _DiagnosticExerciseState();
}

class _DiagnosticExerciseState extends State<DiagnosticExercise> {
  final ValueNotifier<int> choiceIndex = ValueNotifier<int>(-1);
  final VoiceService _voice = VoiceService();
  bool soundEnabled = false; 

  @override
  Widget build(BuildContext context) {
    return Container(
      height:300,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/${widget.bgImage}.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
          ),
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

          ///Question and Choices Body
          Container(
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: SingleChildScrollView(
                          child: Text(widget.mulcho.question, style: TextStyle(color: Colors.black, fontSize: 20),),
                        )
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        _voice.speak(widget.mulcho.question, true);
                      },
                    ),
                  ],
                ),

                MulchoChoices(selectedContainerIndex: choiceIndex, choices: widget.mulcho.choices.values.toList(), isEnglish: true, soundEnabled: soundEnabled,),
                Container(
                  padding: EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Read words aloud",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => soundEnabled = !soundEnabled),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: soundEnabled ? Colors.blue.shade100 : Colors.grey.shade100,
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),





          ///Submit button
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected, // warm yellow
                ),
                onPressed: (){
                  ///if the user has selected something
                  if(choiceIndex.value != -1){


                    //print("choiceIndex.value ${choiceIndex.value +1}, answer ${widget.mulcho.answer}");
                    ///if correct answer
                    if((choiceIndex.value+1) == int.parse(widget.mulcho.answer)){
                      correctPopup(context, widget.onCorrectAnswer);
                    } else{
                      print("wrong answer, correct answer");
                      print(choiceIndex.value+1);
                      print(widget.mulcho.answer);

                      wrongPopup(context, widget.onWrongAnswer);
                      print("wrong ans");}

                  }

                }, child: Text("Submit", style: TextStyle(color: textColor))),
          ),

        ],
      ),
    );
  }
}