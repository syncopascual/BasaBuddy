import 'package:basabuddy/components/QuestionPopup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/translation_bloc.dart';
import '../../colors.dart';
import '../../models/orderData.dart';
import '../TranslationButton.dart';
import 'OrderColumn.dart';

class OrderingExercise extends StatefulWidget {
  final OrderData orderData;
  final VoidCallback onCorrectAnswer;
  final VoidCallback onWrongAnswer;
  final int storyLevel;

  const OrderingExercise(
      {super.key,
      required this.orderData,
      required this.onCorrectAnswer,
      required this.onWrongAnswer,
      required this.storyLevel});

  @override
  State<OrderingExercise> createState() => _OrderingExerciseState();
}

class _OrderingExerciseState extends State<OrderingExercise> {
  late final List<String> correctOrderKeys;
  late final ValueNotifier<List<String>> currentOrderKeys;

  @override
  void initState() {
    super.initState();

    final missingFilipino = widget.orderData.tagalogData.isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isEnglish = context.read<TranslationBloc>().state.isEnglish;
      if (!isEnglish && missingFilipino) {
        context.read<TranslationBloc>().add(SetEnglish());
      }
    });

    correctOrderKeys = widget.orderData.data.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    final shuffled = List<String>.from(correctOrderKeys)..shuffle();
    currentOrderKeys = ValueNotifier(shuffled);
  }

  void onSubmit() {
    final isCorrect = List.generate(
      correctOrderKeys.length,
      (i) => correctOrderKeys[i] == currentOrderKeys.value[i],
    ).every((e) => e);

    if (isCorrect) {
      correctPopup(context, widget.onCorrectAnswer, "");
    } else {
      wrongPopup(context, widget.onWrongAnswer, "Try Again");
    }
  }

  @override
  void dispose() {
    currentOrderKeys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missingFilipino = widget.orderData.tagalogData == null ||
        widget.orderData.tagalogData.values.any((v) => v.trim().isEmpty);
    print("TAGALOG DATA: ${widget.orderData.tagalogData.values}");
    final shouldHide = widget.storyLevel > 2 || missingFilipino;
    return BlocBuilder<TranslationBloc, TranslationState>(
      builder: (context, state) {
        final isEnglish = state.isEnglish;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// Exercise Label
            Container(
              margin: const EdgeInsets.only(left: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected,
                borderRadius: BorderRadius.circular(45),
              ),
              width: 100,
              child: const Text("Exercise"),
            ),

            const SizedBox(height: 10),

            /// Body
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(45),
              ),
              child: Column(
                children: [
                  const Text(
                    "Arrange the sentences in order",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  OrderColumn(
                    orderKeysNotifier: currentOrderKeys,
                    englishData: widget.orderData.data,
                    tagalogData: widget.orderData.tagalogData,
                    isEnglish: isEnglish,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected,
                      ),
                      child: const Text("Submit"),
                    ),
                  ),
                ],
              ),
            ),

            /// Translate button
            shouldHide ? Text('') : TranslationButton(context: context),
          ],
        );
      },
    );
  }
}
