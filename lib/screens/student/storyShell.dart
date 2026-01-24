import 'dart:ffi';

import 'package:basabuddy/components/MulchoExercise.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/Page.dart';
import '../../models/mulcho.dart';
import '../../models/storyPage.dart';

///This class fetches the story, its pages and exercises, from supabase
/// Then orders them, displays them, and keeps track of the current page

class StoryShell extends StatefulWidget {
  final String storyId;
  const StoryShell({super.key, required this.storyId});

  @override
  State<StoryShell> createState() => _StoryShellState();
}

void updateUserLevel(storyId) async{
  //not the best way to do it lol

  //query story list to see which module this story's a part of
  var storyInfo = await Supabase.instance.client
      .from('list_stories')
      .select()
      .eq('story_id', storyId);

  //query user's current level
  var rawUserLevel = await Supabase.instance.client
      .from('user_level_info')
      .select();

  var userLevel = rawUserLevel[0];

  //update user level based on what module the story is part of
  String moduleType = storyInfo[0]["module"];
   switch (moduleType) {
     case 'vocab':
       userLevel['vocab_lvl'] +=1;
     case 'information':
       userLevel['information_lvl'] +=1;
     case 'narrative':
      userLevel['narrative_lvl'] +=1;
     default:
   }

   //send update to supabase.
  //RLS makes sure that only the user's row(that corresponds to their user_id) is updated
  await Supabase.instance.client
      .from('user_level_info')
      .update(userLevel) .eq('id', userLevel['id']);
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
                  return Column(
                    children: [
                      storyWidget(snapshot.data![currentPage]),Row(
                    children: [

                      ///BACK button
                      ElevatedButton(onPressed: (){
                        ///if its the first page, dont do anything
                        if(currentPage == 0){
                          return;
                        }
                        setState(() {
                          currentPage-=1;
                        });
                      }, child: Text('Back')),

                      ///NEXT Button
                      ElevatedButton(onPressed: () async {
                        ///if last page na
                        /// increase user level for this module and navigate to home screen
                        if(currentPage == snapshot.data!.length - 1){

                          updateUserLevel(widget.storyId);



                          //navigate to home
                          context.go('/home');
                          return;

                        }
                        setState(() {
                          currentPage+=1;
                        });
                      }, child: Text('Next')),


                    ],
                  )]

                  );
                  ///Row containing next button and back button

                } else {return CircularProgressIndicator();}
              }),


        ],
      ),
    );
  }
}