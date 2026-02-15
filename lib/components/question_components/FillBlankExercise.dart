import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/translation_bloc.dart';
import '../../colors.dart';
import '../../models/fillBlankData.dart';
import '../QuestionPopup.dart';
import '../TranslationButton.dart';
import 'FillBlankChoices.dart';// adjust import

class FillBlankExercise extends StatefulWidget {
  final FillBlankData fillBlankData;
  final VoidCallback onCorrectAnswer;
  final VoidCallback onWrongAnswer;

  const FillBlankExercise({
    super.key,
    required this.fillBlankData,
    required this.onCorrectAnswer,
    required this.onWrongAnswer,
  });

  @override
  State<FillBlankExercise> createState() => _FillBlankExerciseState();
}

class _FillBlankExerciseState extends State<FillBlankExercise> {
  int? selectedIndex;

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
      correctPopup(context, widget.onCorrectAnswer);
    } else {
      wrongPopup(context,
          widget.onWrongAnswer);
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
              height: 420,
              width: double.infinity,
              child: Column(
                children: [
                  /// STATEMENT
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(statement1, style: const TextStyle(fontSize: 20)),

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

                      Text(statement2, style: const TextStyle(fontSize: 20)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// CHOICES
                  FillBlankChoices(
                    choices: choices,
                    hiddenIndex: selectedIndex,
                    onChoiceTap: selectIndex,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),



            /// SUBMIT
            SizedBox(
              width: double.infinity,
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

            ///Translate button
            TranslationButton(context: context),
          ],
        );
      },
    );
  }
}
