import 'package:basabuddy/components/question_components/MulchoChoices.dart';
import 'package:basabuddy/components/TranslationButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/translation_bloc.dart';
import '../../colors.dart';
import '../PopUp.dart';
import '../QuestionPopup.dart';
import 'package:basabuddy/components/VoiceService.dart';


///multiple choice exercise
class MulchoExercise extends StatefulWidget {

  final String bgImage;
  final Mulcho mulcho;
  final VoidCallback onCorrectAnswer;
  final VoidCallback onWrongAnswer;
  final int storyLevel;
  const MulchoExercise({
    super.key,
    required this.bgImage,
    required this.mulcho,
    required this.onCorrectAnswer,
    required this.onWrongAnswer,
    required this.storyLevel
  });

  @override
  State<MulchoExercise> createState() => _MulchoExerciseState();
}

class _MulchoExerciseState extends State<MulchoExercise> {
  final ValueNotifier<int> choiceIndex = ValueNotifier<int>(-1);
  final VoiceService _voice = VoiceService();
  bool soundEnabled = false;

  @override
  void didUpdateWidget(MulchoExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mulcho != widget.mulcho) {
      choiceIndex.value = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/${widget.bgImage}.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: SingleChildScrollView(
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
            child: BlocBuilder<TranslationBloc, TranslationState>(
              builder: (context, state) {
                late String question = "";
                late Map<String, String> choices = {};
                if(!state.isEnglish){
                  question = widget.mulcho.tagalogQuestion!;
                  choices = widget.mulcho.tagalogChoices!;
                } else {
                  question = widget.mulcho.question;
                  choices = widget.mulcho.choices;
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(question, style: TextStyle(color: Colors.black, fontSize: 20),),
                          )
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {
                            _voice.speak(question, state.isEnglish);
                          },
                        ),
                      ],
                    ),
                    
                    MulchoChoices(selectedContainerIndex: choiceIndex, choices: choices.values.toList(), isEnglish: state.isEnglish, soundEnabled: soundEnabled),

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
                );
              }
            ),
          ),

          ///Translate button
          widget.storyLevel > 2 ? Text('') : TranslationButton(context: context),



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
                  correctPopup(context, widget.onCorrectAnswer, widget.mulcho.explanation);
                } else{
                  print("wrong answer, correct answer");
                  print(choiceIndex.value+1);
                  print(widget.mulcho.answer);

                  wrongPopup(context, widget.onWrongAnswer, widget.mulcho.hint);
                  print("wrong ans");}
            
              }
            
            }, child: Text("Submit", style: TextStyle(color: textColor))),
          ),

        ],
      ),
    ),
    );
  }
}