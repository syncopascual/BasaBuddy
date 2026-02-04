import 'package:flutter/material.dart';
import '../models/matchingData.dart';
import 'MatchColumns.dart';


class MatchingExercise extends StatelessWidget {
  final MatchingData matchingData;
  final VoidCallback onCompleted;

  const MatchingExercise({
    super.key,
    required this.matchingData,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tap the matching pairs",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        MatchColumns(
          pairs: matchingData.pairs,
          onCompleted: onCompleted,
        ),
      ],
    );
  }
}
