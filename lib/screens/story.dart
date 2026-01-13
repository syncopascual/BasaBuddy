import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/mulcho.dart';

class Story extends StatefulWidget {

  const Story({super.key});

  @override
  State<Story> createState() => _StoryState();
}

class _StoryState extends State<Story> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/winter.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(height:200),
          ElevatedButton(onPressed: (){
            Mulcho sampleMulcho = Mulcho(
              id: "1",
              storyId: "2",
              page: 2,
              question: 'what is',
              choices: ['slay', 'boots', 'house'],
              answer: 'house',
              createdAt: DateTime.now(),

            );
            context.go('/story/exercise_mulcho', extra: sampleMulcho);
          }, child: Text("Sample exercise"))
        ],
      ),
    );
  }
}