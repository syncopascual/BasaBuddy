import 'package:basabuddy/components/MulchoExercise.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/Page.dart';
import '../models/mulcho.dart';
import '../models/storyPage.dart';

///This class fetches the story, its pages and exercises, from supabase
/// Then orders them, displays them, and keeps track of the current page

class StoryShell extends StatefulWidget {
  final String storyId;
  const StoryShell({super.key, required this.storyId});

  @override
  State<StoryShell> createState() => _StoryShellState();
}

class _StoryShellState extends State<StoryShell> {
  late Future<List> storyComponents; ///pages and the different exercises

  ///Fetch the story's pages and exercises from supabase
  Future<List> _fetchPagesNexercises() async {
    print("STORYSHELL.dart: _fetchPagesNexercises() called, storyId: ${widget.storyId}");
    /// Fetch the story's pages
    final rawPages = await Supabase.instance.client
        .from('story_page')
        .select()
        .eq('story_id', widget.storyId);

    print("STORYSHELL.dart: pages fetched");
    final List pages = (rawPages as List)
        .map((json) => Storypage.fromJson(json))
        .toList();

    /*
    ///Fetch the story's multiple choice type exercises
    final rawMulcho = await Supabase.instance.client
        .from('mulcho_exercise')
        .select()
        .eq('story_id', widget.storyId);
    print("STORYSHELL.dart: mulcho fetched");

    final List mulcho = (rawMulcho as List)
        .map((json) => Mulcho.fromJson(json))
        .toList();

     */

    ///TODO:: order this correctly
    final pagesAndExercises = pages; //A mixed list

    return pagesAndExercises;
  }

  Widget storyWidget(component){
    print(component.runtimeType);
    switch(component){
      case Storypage page:
        final page = PageContainer(storyPage: component);
        return page;
      case Mulcho mulcho:
        final page = MulchoExercise(mulcho: component, bgImage: 'grassy',);
        return page;
      default:
        return Text("story object doesnt match");
    }
  }


  @override
  void initState() {
    super.initState();
    storyComponents = _fetchPagesNexercises() ; // Start the async operation in initState
  }

  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    print("story.dart");
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/winter.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          FutureBuilder(
              future: storyComponents,
              builder: (context, snapshot){
                if(snapshot.hasData){
                  return (storyWidget(snapshot.data![currentPage]));
                } else {return CircularProgressIndicator();}
              }),

          ///Row containing next button and back button
          Row(
            children: [
              ElevatedButton(onPressed: (){
                setState(() {
                  currentPage-=1;
                });
              }, child: Text('Back')),
              ElevatedButton(onPressed: (){
                setState(() {
                  currentPage+=1;
                });
              }, child: Text('Next')),


            ],
          )
        ],
      ),
    );
  }
}