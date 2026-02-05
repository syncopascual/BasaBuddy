import 'package:basabuddy/components/QuestionPopup.dart';
import 'package:flutter/material.dart';
import '../colors.dart';
import '../models/fillBlankData.dart';
import 'FillBlankChoices.dart';


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
  String? selectedWord;

  late List<String> availableChoices;

  @override
  void initState() {
    super.initState();
    availableChoices = List<String>.from(widget.fillBlankData.choices);
  }

  void selectWord(String word) {
    setState(() {
      selectedWord = word;
      availableChoices.remove(word);
    });
  }

  void unselectWord() {
    if (selectedWord == null) return;

    setState(() {
      availableChoices.add(selectedWord!);
      selectedWord = null;
    });
  }

  void onSubmit() {
    if (selectedWord == widget.fillBlankData.answer) {

      correctPopup(context, widget.onCorrectAnswer);
    }
      else {
        wrongPopup(context, widget.onWrongAnswer);

    }
  }

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
        /// STATEMENT AREA
        Container(
          padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(45)),
          ),
          height: 420,
          child: Column(
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    widget.fillBlankData.statement1,
                    style: const TextStyle(fontSize: 20),
                  ),

                  GestureDetector(
                    onTap: unselectWord,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 80),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: selectedWord == null
                            ? Colors.grey.shade300
                            : Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedWord ?? "_____",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  Text(
                    widget.fillBlankData.statement2,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              /// CHOICES
              FillBlankChoices(
                choices: availableChoices,
                onChoiceTap: selectWord,
              ),

              const SizedBox(height: 32),

              /// SUBMIT BUTTON
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: selected),
                  onPressed: selectedWord == null ? null : onSubmit,
                  child: const Text("Submit"),
                ),
              ),
            ],
          )
        ),


      ],
    );
  }
}
