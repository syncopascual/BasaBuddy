import 'package:basabuddy/components/StoryButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/story.dart';

class Module extends StatefulWidget {

  final String moduleType;
  const Module(this.moduleType, {super.key});

  @override
  State<Module> createState() => _ModuleState();
}

///function that sets the background image based on the module type
String determineBackground(moduleType){
  if(moduleType == 'narrative'){
    return 'desert';
  }
  if(moduleType == 'information'){
    return 'winter';
  }
  else{
    return 'grassy';
  }
}

class _ModuleState extends State<Module> {
  late Future<List> storiesAndLevel;

  ///Fetch Stories from supabase and get user level
  Future<List> _fetchStoriesAndUserLevel() async {

    ///Fetch stories
    print("MODULE.dart :: _fetchStories() called");
    //print(Supabase.instance.client.auth.currentUser);
    final response = await Supabase.instance.client
        .from('list_stories')
        .select()
        .eq('module', widget.moduleType);
    print("After Supabase query");
    print(response);

    final stories = (response as List)
        .map((json) => Story.fromJson(json))
        .toList();
    print("Stories");
    print(stories);

    ///Get user level
    final rawUserLevel = await Supabase.instance.client
        .from('user_level_info')
        .select();

    int moduleLevel = rawUserLevel[0]["${widget.moduleType}_lvl"];
    return [stories, moduleLevel];

  }

  //Todo: improve type safety
  ///Returns the user's level for this particular module


  @override
  void initState() {
    super.initState();
    storiesAndLevel = _fetchStoriesAndUserLevel(); // Start the async operation in initState

  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/${determineBackground(widget.moduleType)}.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        height: 600,
        child: FutureBuilder(
            future: storiesAndLevel,
            builder: (context, snapshot){
              if(snapshot.hasData){
                return ListView.builder(
                    itemCount: snapshot.data?[0].length,
                    itemBuilder: (_, i){
                      return Container(
                        height: 150,
                        child: Column(
                          children: [
                            StoryButton(
                                userLevel: snapshot.data?[1],
                                storyLevel: snapshot.data?[0][i].level,
                                imageAsset: 'assets/story/papaya.png',
                                onPressed: () {
                                  context.go('/story/${snapshot.data?[0][i].storyId}');
                                }),

                          ],
                        ),
                      );
                    });
              } else {
                return const Center(child: CircularProgressIndicator());

              }
            }),
      ),
    );
  }
}