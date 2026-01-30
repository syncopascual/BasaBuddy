import 'dart:ffi';

import 'package:basabuddy/bloc/money_bloc.dart';
import 'package:basabuddy/components/MulchoExercise.dart';
import 'package:basabuddy/wrappers/StoryItem.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  print("updateUserLevel called");
  //not the best way to do it lol

  //query story list to see which module this story's a part of
  var storyInfo = await Supabase.instance.client
      .from('list_stories')
      .select()
      .eq('story_id', storyId);

  print("storyInfo fetched");

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
  print("updating user level...");


   try{
     //send update to supabase.
     //RLS makes sure that only the user's row(that corresponds to their user_id) is updated
     await Supabase.instance.client
         .from('user_level_info')
         .update(userLevel)
         .eq('id', userLevel['id']);
     print("done updating user level!");
   } catch (e){
     print("error updating: $e");
   }

}


class _StoryShellState extends State<StoryShell> {



  late Map<String, int> skillScores = {}; ///scoring for each skill, will be uploaded to stage_data
  Map<int, String> imageURLs = {};
  late int numPages = 0; ///needed for precaching
  int currentPage = 0;


  void _precacheUpcoming(length) {
    final nextIndexes = [
      currentPage + 1,
      currentPage + 2,
    ];

    for (final i in nextIndexes) {
      if (i >= length) continue;

      final url = imageURLs[i];
      precacheImage(NetworkImage(url!), context);
      print("_precacheUpcoming: precached file");
    }
  }



  ///Fetch the story's pages and exercises from supabase, and orders them
  Future<List<StoryItem>> _fetchPagesNexercises() async {
    print("STORYSHELL.dart: _fetchPagesNexercises() called, storyId: ${widget.storyId}");

    /// Fetch the story's pages
    final rawPages = await Supabase.instance.client
        .from('story_page')
        .select()
        .eq('story_id', widget.storyId);

    final List<Storypage> pages = (rawPages as List)
        .map((json) => Storypage.fromJson(json))
        .toList();

    final List<PageItem> wrappedPages = pages
        .map((page) => PageItem(page))
        .toList();

    numPages = pages.length;


    for(int i = 0; i< pages.length;i++){

      try{
        String url = Supabase.instance.client
            .storage
            .from('story-pages')
            .getPublicUrl('${pages[i].storyId}/${pages[i].pageNum}.png');
        imageURLs[pages[i].pageNum] = url;
      }
    catch (e) {
    print('Error listing files: $e');
    }
    }

    ///initial precache
    _precacheUpcoming(pages.length);
    late List<Mulcho> mulcho;
    late List<StoryItem> wrappedMulcho;


    try {
      ///Fetch the story's multiple choice type exercises
      final rawMulcho = await Supabase.instance.client
          .from('mulcho_exercise')
          .select()
          .eq('story_id', widget.storyId);
      print("STORYSHELL.dart: mulcho fetched");

      mulcho = (rawMulcho as List)
          .map((json) => Mulcho.fromJson(json))
          .toList();

      wrappedMulcho = mulcho
        .map((mul) => MulchoItem(mul))
        .toList();

      ///create a map that has all the skills of the story
      for(int i = 0; i< mulcho.length;i++){
        ///If the skill isn't in the dictionary yet, add and set to zero
        ///the value of each skill is the amount of mistakes a student makes
        if(!skillScores.containsKey(mulcho[i].skill)){
          skillScores[mulcho[i].skill] = 0;
        }
      }
      print("skillScores: $skillScores");
    }
    catch(e){
      print(e);
    }



    try {
      ///order this correctly
      final orderedItems = orderItems(wrappedPages, wrappedMulcho);
      print("fetched pages and exercises!");
      return orderedItems;
    } catch(e){
      print(e);
    }

    return [];

  }


  ///called inside _fetchPagesNexercises(), orders the items
  List<StoryItem> orderItems(List<PageItem> pages, List<StoryItem?> exercises){
    List<StoryItem> ordered = [];
    for(int i = 1; i <= pages.length; i++){

      ///page 1 to ...
      final page = pages.firstWhere(
            (m) => m.data.pageNum == i ,
      );

      ordered.add(page);


      ///iterate over questions, check if it comes after page i
      for(int j = 0; j < exercises.length; j++){
        if(exercises[j]?.data.afterPage == i){
          ordered.add(exercises[j]!);
        }
      }



    }
    return ordered;
  }


  Widget storyWidget(component, url){
    print(component.runtimeType);
    switch(component){
      case Storypage page:
        final page = PageContainer(storyPage: component, imageURL: url,);
        return page;
      case Mulcho mulcho:
        final page = MulchoExercise(mulcho: component, bgImage: 'grassy',);
        return page;
      default:
        return Text("story object doesnt match");
    }
  }

  String? determineBg(currentComponent){
    if(currentComponent.runtimeType == PageItem){
      return imageURLs[currentComponent.data.pageNum];
    } else {
      return "grassy";
    }

  }





  @override
  Widget build(BuildContext context) {
    print("story.dart");
    return  FutureBuilder(
        future: _fetchPagesNexercises(),
        builder: (context, snapshot){
          if(snapshot.hasData){

            ///the loaded data
            var orderedStoryItems = snapshot.data!;
            print("ORDERED STORY ITEMS");
            print(orderedStoryItems);
            //print("storyShell.dart urls: $imageURLs, current page: $currentPage");

            return Container(

              child: Column(
                  children: [
                    storyWidget(orderedStoryItems[currentPage].data, determineBg(orderedStoryItems[currentPage])),
                    Row(
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
                          if(currentPage == orderedStoryItems.length - 1){

                            updateUserLevel(widget.storyId);

                            BlocProvider.of<MoneyBloc>(context).add(ChangeMoney(50));

                            //navigate to home
                            context.go('/student/home');
                            return;

                          }
                          setState(() {
                            currentPage+=1;
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _precacheUpcoming(numPages);
                          });
                        }, child: Text('Next')),
                      ],
                    ),
                  ]

              ),
            );
            ///Row containing next button and back button

          } else {return CircularProgressIndicator();}
        });
  }
}