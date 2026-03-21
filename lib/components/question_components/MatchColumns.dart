import 'dart:async';
import 'package:flutter/material.dart';
import 'package:basabuddy/components/VoiceService.dart';


enum TileState { normal, selected, correct, wrong, disabled }

class MatchColumns extends StatefulWidget {
  final Map<String, String> pairs;
  final VoidCallback onCompleted;

  const MatchColumns({
    super.key,
    required this.pairs,
    required this.onCompleted,
  });

  @override
  State<MatchColumns> createState() => _MatchColumnsState();
}

class _MatchColumnsState extends State<MatchColumns> {
  late List<String> leftWords;
  late List<String> rightWords;

  String? firstSelection;
  bool firstIsLeft = true;

  final Map<String, TileState> tileStates = {};
  final Set<String> matchedWords = {};
  final VoiceService _voice = VoiceService();
  

  @override
  void initState() {
    super.initState();

    leftWords = widget.pairs.keys.toList()..shuffle();
    rightWords = widget.pairs.values.toList()..shuffle();

    for (final word in [...leftWords, ...rightWords]) {
      tileStates[word] = TileState.normal;
    }
  }

  void onTileTap(String word, bool isLeft) {
    if (tileStates[word] == TileState.disabled ||
        tileStates[word] == TileState.correct) return;
    _voice.stop();
    _voice.speak(word, true);
    if (firstSelection == null) {
      setState(() {
        firstSelection = word;
        firstIsLeft = isLeft;
        tileStates[word] = TileState.selected;
      });
      return;
    }

    // Prevent selecting two from same column
    if (firstIsLeft == isLeft) return;

    double cardHeight = 420; // your container height
    int numTiles = widget.pairs.length; // 5
    
    final firstWord = firstSelection!;
    final isCorrect = widget.pairs[firstWord] == word ||
        widget.pairs[word] == firstWord;

    if (isCorrect) {
      setState(() {
        tileStates[firstWord] = TileState.correct;
        tileStates[word] = TileState.correct;
      });

      Timer(const Duration(milliseconds: 600), () {
        setState(() {
          tileStates[firstWord] = TileState.disabled;
          tileStates[word] = TileState.disabled;
          matchedWords.addAll([firstWord, word]);
          firstSelection = null;
        });

        if (matchedWords.length == widget.pairs.length * 2) {
          widget.onCompleted();
        }
      });
    } else {
      setState(() {
        tileStates[word] = TileState.wrong;
      });

      Timer(const Duration(milliseconds: 600), () {
        setState(() {
          tileStates[firstWord] = TileState.normal;
          tileStates[word] = TileState.normal;
          firstSelection = null;
        });
      });
    }
  }

  Color getColor(TileState state) {
    switch (state) {
      case TileState.selected:
        return Colors.blue.shade200;
      case TileState.correct:
        return Colors.green.shade300;
      case TileState.wrong:
        return Colors.red.shade300;
      case TileState.disabled:
        return Colors.grey.shade300;
      case TileState.normal:
      default:
        return Colors.white;
    }
  }

  Widget buildTile(String word, bool isLeft) {
    final state = tileStates[word]!;

    return GestureDetector(
      onTap: () => onTileTap(word, isLeft),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: getColor(state),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        alignment: Alignment.center,
        child: Text(
          word,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
          softWrap: true,                // allow multiple lines
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double cardHeight = 420; // or MediaQuery if you want dynamic
    int numTiles = widget.pairs.length; // 5 pairs
    return Row(
      children: [
        Expanded(
          child: Column(
            children:
            leftWords.map((w) => buildTile(w, true)).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children:
            rightWords.map((w) => buildTile(w, false)).toList(),
          ),
        ),
      ],
    );
  }
}
