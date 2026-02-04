import 'package:flutter/material.dart';
import '../models/orderData.dart';
import 'OrderColumn.dart';



class OrderingExercise extends StatefulWidget {
  final OrderData orderData;
  final VoidCallback onCompleted;

  const OrderingExercise({
    super.key,
    required this.orderData,
    required this.onCompleted,
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
      widget.onCompleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Try again!")),
      );
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
            child: const Text("Submit"),
          ),
        ),
      ],
    );
  }
}
