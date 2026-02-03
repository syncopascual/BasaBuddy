import 'package:flutter/material.dart';

class GradientLinearProgressBar extends StatelessWidget {
  final double value; // 0.0 → 1.0
  final Color leftColor;
  final Color rightColor;
  final Color unfilledColor;
  final double thickness;

  const GradientLinearProgressBar({
    super.key,
    required this.value,
    required this.leftColor,
    required this.rightColor,
    required this.unfilledColor,
    this.thickness = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(thickness / 2),
      child: SizedBox(
        height: thickness,
        child: Stack(
          children: [
            // Unfilled background (always full width)
            Container(
              decoration: BoxDecoration(
                color: unfilledColor,
              ),
            ),

            // Filled gradient bar
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth * value.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [leftColor, rightColor],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
