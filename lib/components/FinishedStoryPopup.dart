import 'package:flutter/material.dart';

import '../colors.dart';

class FinishedStoryPopup extends StatelessWidget {
  final VoidCallback onContinue;

  const FinishedStoryPopup({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero, // makes it fullscreen
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Container(
          decoration:  BoxDecoration(
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

                // 📝 Content
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:  selected,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                  child: const Text(
                    'Story Completed!',
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
                  padding: EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'You totally nailed it!!',
                        textAlign: TextAlign.center,
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
