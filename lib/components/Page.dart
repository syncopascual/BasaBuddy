import 'package:basabuddy/components/TranslationButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/models/storyPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/translation_bloc.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(

      child: Column(
        children: [
          Container(height:350),
          //Image.asset('assets/story/papaya.png', height: 200),
          ///TRANSLATION BUTTON
          TranslationButton(context: context),

          ///PAGE TEXT
          Container(height: 200,
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            child: BlocBuilder<TranslationBloc, TranslationState>(
                builder: (_, state){
                  if(state.isEnglish){
                    return Text(widget.storyPage.text);
                  } else {
                    return Text(widget.storyPage.tagalogText);
                  }
                })
          ),
            
        ],
      ),
    );
  }
}