import 'package:flutter/material.dart';

class FillBlankChoices extends StatelessWidget {
  final List<String> choices;
  final Function(String) onChoiceTap;

  const FillBlankChoices({
    super.key,
    required this.choices,
    required this.onChoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: choices.map((word) {
        return GestureDetector(
          onTap: () => onChoiceTap(word),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              word,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }).toList(),
    );
  }
}
