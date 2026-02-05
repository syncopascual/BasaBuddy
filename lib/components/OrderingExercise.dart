import 'package:basabuddy/components/QuestionPopup.dart';
import 'package:flutter/material.dart';
import '../colors.dart';
import '../models/orderData.dart';
import 'OrderColumn.dart';



class OrderingExercise extends StatefulWidget {
  final OrderData orderData;
  final VoidCallback onCorrect;

  const OrderingExercise({
    super.key,
    required this.orderData,
    required this.onCorrect,
  });

  @override
  State<OrderingExercise> createState() => _OrderingExerciseState();
}

class _OrderingExerciseState extends State<OrderingExercise> {
  late final List<String> correctOrder;
  late final ValueNotifier<List<String>> currentOrder;

  @override
  void initState() {
    super.initState();

    // Sort by numeric key to get correct order
    final sortedKeys = widget.orderData.data.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    correctOrder = sortedKeys
        .map((key) => widget.orderData.data[key]!)
        .toList();

    final shuffled = List<String>.from(correctOrder)..shuffle();
    currentOrder = ValueNotifier(shuffled);
  }

  void onSubmit() {
    final isCorrect = List.generate(
      correctOrder.length,
          (i) => correctOrder[i] == currentOrder.value[i],
    ).every((e) => e);

    if (isCorrect) {
      correctPopup(context, widget.onCorrect);
    } else {
      wrongPopup(context, (){});
    }
  }

  @override
  void dispose() {
    currentOrder.dispose();
    super.dispose();
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(45)),
          ),
          height: 420,
          child: Column(

            children: [
              const Text(
                "Arrange the sentences in order",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              OrderColumn(orderNotifier: currentOrder),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: selected),
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }
}
