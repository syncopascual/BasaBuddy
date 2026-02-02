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
    this.size = 64,
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
      Color(0xFFFFC107),
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
        margin: EdgeInsets.symmetric(vertical:12),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ColorFiltered(
            colorFilter: imageFilter ?? const ColorFilter.mode(
              Colors.transparent,
              BlendMode.dst,
            ),
            child: Image.network(
              imageAsset,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
