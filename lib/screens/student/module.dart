import 'package:basabuddy/components/StoryButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/story.dart';
import '../../utils/database_helper.dart';

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
  late Map<String, String> storyThumbnails = {};
  
  ///Fetch Stories from supabase and get user level
  Future<List> _fetchStoriesAndUserLevel() async {
    final supabase = Supabase.instance.client;
    List stories;
    if (widget.moduleType == 'teachers_pick'){
      final userId = supabase.auth.currentUser!.id;
      final classIds = await supabase
        .from('class_students')
        .select('class_id')
        .eq('student_id', userId);
      print("classIdsResponse: $classIds");
      final classIdList = (classIds as List).map((c) => c['class_id']).toList();
      print("classIdList: $classIdList");

      final teacherStoryFirst = await supabase
        .from('list_stories')
        .select()
        .eq('class_id', classIdList[0]);
      print("teacherStoriesResponseOne: $teacherStoryFirst");
      final teacherStories = await supabase
        .from('list_stories')
        .select()
        .inFilter('class_id', classIdList);
      print("teacherStoriesResponse: $teacherStories");
      stories = (teacherStories as List).map((json) => Story.fromJson(json)).toList();

      String folder = widget.moduleType == 'teachers_pick' ? 'default' : widget.moduleType;
      for(int i = 0; i< stories.length;i++){

        try{
          String url = Supabase.instance.client
            .storage
            .from('story-thumbnails')
            .getPublicUrl('$folder/default.png');
          storyThumbnails[stories[i].storyId] = url;
        }
        catch (e) {
          print('Error listing files: $e');
        }
      }
      
      
      return [stories, 1];
    }else {
      ///Fetch stories
      print("MODULE.dart :: _fetchStories() called");

      List<Story> stories = await DatabaseHelper.instance.queryWhere('list_stories', Story.fromJson, 'module = ?', [widget.moduleType]);

      print("Stories");
      print(stories);

      int moduleLevel = 10000; /// User is able to access all stories

      ///get story thumbnails
      for(int i = 0; i< stories.length;i++){

        try{

          storyThumbnails[stories[i].storyId] = 'assets/story_thumbnails/${widget.moduleType}/${stories[i].storyId}.png';
        }
        catch (e) {
          print('Error listing files: $e');
        }
      }

      print("story thumbnails: $storyThumbnails");
      ///sort stories according to level
      stories.sort((a, b) => a.level.compareTo(b.level));

      return [stories, moduleLevel];
    }
    


  }




  @override
  void initState() {
    super.initState();
    storiesAndLevel = _fetchStoriesAndUserLevel(); // Start the async operation in initState

  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(
          "assets/bg_images/${determineBackground(widget.moduleType)}.png",
        ),
        fit: BoxFit.cover,
      ),
    ),
    child: FutureBuilder(
      future: storiesAndLevel,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stories = snapshot.data?[0];
        final userLevel = snapshot.data?[1];

        // S curve horizontal swing
        final minSpacing = 150.0;  // minimum vertical distance between stories
        final topPadding = 50.0;
        final bottomPadding = 50.0;

        // calculate vertical spacing dynamically
        final verticalSpacing = stories.length > 1
            ? minSpacing
            : 0.0;

        final totalHeight = topPadding + bottomPadding +
            (stories.length - 1) * verticalSpacing + 150; // extra buffer for last button
        final offsets = [0, 50, 100, 50, 0, -50, -100, -50];

        return SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            width: screenWidth,
            child: Stack(
              children: [
                for (int i = 0; i < stories.length; i++)
                  Positioned(
                    top: topPadding + i * verticalSpacing,
                    left: screenWidth/2 - 32 + offsets[i % offsets.length],
                    child: StoryButton(
                      userLevel: userLevel,
                      storyLevel: stories[i].level,
                      imageAsset: storyThumbnails[stories[i].storyId]!,
                      onPressed: () =>
                          context.go('/story/${stories[i].storyId}'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}