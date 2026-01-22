import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/models/storyPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

///UI that displays a story page
class PageContainer extends StatefulWidget {

  final Storypage storyPage;
  const PageContainer({
    super.key,
    required this.storyPage,
  });

  @override
  State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/grassy.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(height:200),
          Image.asset('assets/story/papaya.png', height: 200),
          Container(height: 200,
            padding: EdgeInsets.symmetric(horizontal: 36, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            child: Text(widget.storyPage.text),
          ),
            
        ],
      ),
    );
  }
}