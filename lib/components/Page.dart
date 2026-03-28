import 'package:basabuddy/components/TranslationButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/models/storyPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/translation_bloc.dart';
import 'package:basabuddy/components/VoiceService.dart';
///UI that displays a story page
class PageContainer extends StatefulWidget {

  final Storypage storyPage;
  final String imageURL;
  const PageContainer({
    super.key,
    required this.storyPage,
    required this.imageURL
  });

  @override
  State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
  final VoiceService _voice = VoiceService();

  @override
  void dispose() {
    _voice.stop();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(height:350),
          //Image.asset('assets/story/papaya.png', height: 200),
          ///TRANSLATION BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Container(
            margin: EdgeInsets.only(right: 10),
              child: TranslationButton(context: context))],
          ),
          
          SizedBox(height: 10),

          ///PAGE TEXT
          Container(
            width: double.infinity,
            height: 200,
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            child: BlocBuilder<TranslationBloc, TranslationState>(
                builder: (_, state){
                  final text = state.isEnglish
                    ? widget.storyPage.text
                    : widget.storyPage.tagalogText;
                  return Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(text)
                        )
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          _voice.speak(text, state.isEnglish);
                        },
                      ),
                    ],
                  );
                })
          ),  
        ],
      ),
    );
  }
}