import 'package:flutter/material.dart';

import '../colors.dart';

final Map<String, String> bgImage = {
  'narrative': 'desert',
  'vocab': 'grassy',
  'information': 'winter'
};

class LevelUpPopUp extends StatelessWidget {
  final VoidCallback onContinue;
  final String moduleType;
  final int level;

  const LevelUpPopUp({
    super.key,
    required this.onContinue,
    required this.level,
    required this.moduleType
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero, // makes it fullscreen
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Container(
          decoration:  BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bg_images/${bgImage[moduleType]}.png"),
              fit: BoxFit.cover,
            ),
            // Apply the gradient here
            gradient:  LinearGradient(
              colors: [finishPopupBg1,
                finishPopupBg2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ), // Rounded corners for the pop-up
          ),
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  child: const Text(
                    'Level Up!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                ///BODY
                Container(
                  height: 300,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Great job!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 24),

                      // Points earned row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Level',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$level',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                /// Continue button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: popupTheme['correct']?["buttonColor"],),
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog
                    onContinue(); // trigger callback
                  },
                  child: const Text('Continue', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
