
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:basabuddy/components/VoiceService.dart';

import '../../colors.dart';



class MulchoChoices extends StatefulWidget {
  final ValueNotifier<int?> selectedContainerIndex;
  final List<String> choices;
  final bool isEnglish;

  MulchoChoices({required this.selectedContainerIndex, required this.choices, required this.isEnglish});

  @override
  _MulchoChoicesState createState() => _MulchoChoicesState();
}

class _MulchoChoicesState extends State<MulchoChoices> {
  final VoiceService _voice = VoiceService();
  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      itemCount: widget.choices.length, // Number of containers
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            widget.selectedContainerIndex.value = index;
            setState(() {}); // Redraw the UI
            _voice.speak(widget.choices[index], widget.isEnglish);
          },
          child: ValueListenableBuilder<int?>(
            valueListenable: widget.selectedContainerIndex,
            builder: (context, selectedIndex, child) {
              return Container(
                alignment: Alignment.center,
                height: 40,
                width: 10,
                margin: EdgeInsets.all(10),//todo: unhardcode?
                decoration: BoxDecoration(
                  color:  selectedIndex == index ? selected : mulchoChoice,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Text(widget.choices[index], style: TextStyle(fontSize: 16),),

                //child: Center(child: Text('Item $index')),
              );
            },
          ),
        );
      },
    );
  }
}