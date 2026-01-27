import 'dart:ffi';

import 'package:basabuddy/bloc/money_bloc.dart';
import 'package:basabuddy/components/MulchoExercise.dart';
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
  late Future<Map<int, String>> imageURLs;

  ///Fetch the story's pages and exercises from supabase
  /// returns 2 things: story pages+exercises, image urls
  Future<(List, Map<int, String>)> _fetchPagesNexercises() async {
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

    ///get the background image URLs for each page
    Map<int, String> imageURLs = {};
    for(int i = 0; i <pages.length; i++){
      String url = Supabase.instance.client
          .storage
          .from('story-pages')
          .getPublicUrl('${pages[i].storyId}/${pages[i].pageNum}.png');

      /// page number and corresponding url{1: "url"}
      imageURLs[pages[i].pageNum] = url;
    }

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

    return (pagesAndExercises, imageURLs);
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

  //todo:: remove if not needed
  /*
  @override
  void initState() async {
    super.initState();
    var (story, url) = await _fetchPagesNexercises();
    storyComponents = story;
  }*/

  int currentPage = 1;
  @override
  Widget build(BuildContext context) {
    print("story.dart");
    return  FutureBuilder(
        future: _fetchPagesNexercises(),
        builder: (context, snapshot){
          if(snapshot.hasData){

            ///the loaded data
            var ((storyComponents, urls)!) = snapshot.data;
            print("storyShell.dart urls: $urls, current page: $currentPage");
            return Container(
              /*
              decoration: BoxDecoration(
                image: DecorationImage(
                  ///Current page index starts at zero, but urls go by the supabase page number
                  ///which starts at 1
                  image: NetworkImage(urls[currentPage + 1]!),
                  fit: BoxFit.cover,
                ),
              ),*/
              child: Column(
                  children: [
                    storyWidget(storyComponents[currentPage], urls[currentPage + 1]),Row(
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
                          if(currentPage == storyComponents.length - 1){

                            updateUserLevel(widget.storyId);

                            BlocProvider.of<MoneyBloc>(context).add(ChangeMoney(50));

                            //navigate to home
                            context.go('/student/home');
                            return;

                          }
                          setState(() {
                            currentPage+=1;
                          });
                        }, child: Text('Next')),


                      ],
                    )]

              ),
            );
            ///Row containing next button and back button

          } else {return CircularProgressIndicator();}
        });
  }
}