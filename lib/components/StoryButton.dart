import 'package:flutter/material.dart';

class StoryButton extends StatelessWidget {
  final int userLevel;
  final int storyLevel;
  final String imageAsset;
  final VoidCallback onPressed;
  final double size;

  const StoryButton({
    super.key,
    required this.userLevel,
    required this.storyLevel,
    required this.imageAsset,
    required this.onPressed,
    this.size = 90,
  });

  bool get isCompleted => userLevel > storyLevel;
  bool get isLocked => userLevel < storyLevel;
  bool get isCurrent => userLevel == storyLevel;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isCompleted
        ? const Color(0xFFFFD54F) // gold-ish
        : isCurrent
        ? const Color(0xFFB3E5FC) // light blue
        : Colors.grey.shade300;

    final ColorFilter? imageFilter = isCompleted
        ? const ColorFilter.mode(
      Color(0xFFFFFFFF),
      //Color(0xFFFFC107),
      BlendMode.modulate,
    )
        : isLocked
        ? const ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ])
        : null;

    return GestureDetector(
      onTap: isLocked ? null : onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isLocked
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade400, Colors.grey.shade300],
          )
              : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlueAccent, Colors.lightGreenAccent],
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: imageFilter ?? const ColorFilter.mode(
              Colors.transparent,
              BlendMode.dst,
            ),
            child: Image.asset(
              imageAsset,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
