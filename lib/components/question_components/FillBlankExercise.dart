import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/translation_bloc.dart';
import '../../colors.dart';
import '../../models/fillBlankData.dart';
import '../QuestionPopup.dart';
import '../TranslationButton.dart';
import 'FillBlankChoices.dart';// adjust import
import 'package:basabuddy/components/VoiceService.dart';

class FillBlankExercise extends StatefulWidget {
  final FillBlankData fillBlankData;
  final VoidCallback onCorrectAnswer;
  final VoidCallback onWrongAnswer;
  final int storyLevel;

  const FillBlankExercise({
    super.key,
    required this.fillBlankData,
    required this.onCorrectAnswer,
    required this.onWrongAnswer,
    required this.storyLevel
  });

  @override
  State<FillBlankExercise> createState() => _FillBlankExerciseState();
}

class _FillBlankExerciseState extends State<FillBlankExercise> {
  int? selectedIndex;
  final VoiceService _voice = VoiceService();
  bool soundEnabled = false;

  void selectIndex(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void unselect() {
    setState(() {
      selectedIndex = null;
    });
  }

  @override
  void didUpdateWidget(FillBlankExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillBlankData != widget.fillBlankData) {
      setState(() {
        selectedIndex = null;
      });
    }
  }

  void onSubmit({
    required bool isEnglish,
    required List<String> choices,
    required String answer,
  }) {
    if (selectedIndex == null) {
      widget.onWrongAnswer();
      return;
    }

    final selectedWord = choices[selectedIndex!];

    if (selectedWord == answer) {
      correctPopup(context, widget.onCorrectAnswer, widget.fillBlankData.explanation);
    } else {
      wrongPopup(context,
          widget.onWrongAnswer, widget.fillBlankData.hint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        final isEnglish = state.isEnglish;

        final statement1 = isEnglish
            ? widget.fillBlankData.statement1
            : widget.fillBlankData.tagalogStatement1;

        final statement2 = isEnglish
            ? widget.fillBlankData.statement2
            : widget.fillBlankData.tagalogStatement2;

        final choices = isEnglish
            ? widget.fillBlankData.choices
            : widget.fillBlankData.tagalogChoices;

        final answer = isEnglish
            ? widget.fillBlankData.answer
            : widget.fillBlankData.tagalogAnswer;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///Exercise Label
            Container(height: 10,),
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
            ///QUESTION BODY
            Container(
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(45)),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  /// STATEMENT
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(statement1 == "none" ? "" : statement1, style: const TextStyle(fontSize: 20)),

                      GestureDetector(
                        onTap: unselect,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 80),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedIndex == null
                                ? Colors.grey.shade300
                                : Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            selectedIndex == null
                                ? "_____"
                                : choices[selectedIndex!],
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),

                      Text(statement2 == "none" ? "" : statement2, style: const TextStyle(fontSize: 20)),
                      IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () async {
                            await _voice.stop();
                            List<String> statements = [statement1 == "none" ? "" : statement1];
                            if (selectedIndex != null) {
                              statements.add(choices[selectedIndex!]);
                            }
                            if (statement2 != "none") {
                              statements.add(statement2);
                            }
                            await _voice.speakSequence(statements, state.isEnglish, pauseMs: 300);
                          },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// CHOICES
                  FillBlankChoices(
                    choices: choices,
                    hiddenIndex: selectedIndex,
                    soundEnabled: soundEnabled,
                    onChoiceTap: selectIndex,
                  ),

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

                  const SizedBox(height: 32),
                ],
              ),
            ),



            /// SUBMIT
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected,
                ),
                onPressed: selectedIndex == null
                    ? null
                    : () => onSubmit(
                  isEnglish: isEnglish,
                  choices: choices,
                  answer: answer,
                ),
                child: const Text("Submit"),
              ),
            ),


            ///Translate button only appears level 2 below
            widget.storyLevel > 2 ? Text('') : TranslationButton(context: context),

          ],
        );
      },
    );
  }
}
