import 'package:flutter/material.dart';
import 'package:basabuddy/components/VoiceService.dart';

class FillBlankChoices extends StatelessWidget {
  final List<String> choices;
  final int? hiddenIndex;
  final Function(int) onChoiceTap;
  final bool isEnglish;
  final bool soundEnabled;

  const FillBlankChoices(
      {super.key,
      required this.choices,
      required this.hiddenIndex,
      required this.onChoiceTap,
      required this.isEnglish,
      required this.soundEnabled});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(choices.length, (index) {
        if (index == hiddenIndex) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            onChoiceTap(index);
            if (soundEnabled) {
              VoiceService().speak(choices[index], isEnglish);
            }
          },
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
              choices[index],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }),
    );
  }
}
