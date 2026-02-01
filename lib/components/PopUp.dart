import 'package:flutter/material.dart';

import '../colors.dart';

class Popup extends StatelessWidget {
  final String title;
  final String description;
  final String theme;
  final VoidCallback onPressed;

  const Popup({
    super.key,
    required this.title,
    required this.description,
    required this.onPressed,
    required this.theme
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration:  BoxDecoration(
        color: popupTheme[theme]?["bgColor"],
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: popupTheme[theme]?["textColor"],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: popupTheme[theme]?["textColor"],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close sheet
                onPressed();                 // run callback
              },
              style: ElevatedButton.styleFrom(backgroundColor: popupTheme[theme]?["buttonColor"],),
              child: const Text("Continue", style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }
}
