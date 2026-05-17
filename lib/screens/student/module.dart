import 'package:basabuddy/colors.dart';
import 'package:basabuddy/components/StoryButton.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/story.dart';
import '../../models/userLevelInfo.dart';
import '../../utils/database_helper.dart';

class Module extends StatefulWidget {
  final String moduleType;
  const Module(this.moduleType, {super.key});
  @override
  State<Module> createState() => _ModuleState();
}

///function that sets the background image based on the module type
String determineBackground(moduleType) {
  if (moduleType == 'narrative') {
    return 'desert';
  }
  if (moduleType == 'information') {
    return 'winter';
  } else {
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
    if (widget.moduleType == 'teachers_pick') {
      final userId = supabase.auth.currentUser!.id;
      final progress = await supabase
          .from('user_level_info')
          .select('vocab_lvl, narrative_lvl, information_lvl')
          .eq('user_id', userId)
          .maybeSingle();

      final avg = progress != null
          ? (num.parse(progress['vocab_lvl'].toString()) +
                  num.parse(progress['narrative_lvl'].toString()) +
                  num.parse(progress['information_lvl'].toString())) /
              3.0
          : 0;

      final studentLevel = avg.ceil().toInt().clamp(1, 5);
      print("progress: $progress");
      print("avg: $avg, studentLevel: $studentLevel");

      final classIds = await supabase
          .from('class_students')
          .select('class_id')
          .eq('student_id', userId);
      print("classIdsResponse: $classIds");
      final classIdList = (classIds as List).map((c) => c['class_id']).toList();
      if (classIdList.isEmpty) {
        return [[], 1];
      }
      print("classIdList: $classIdList");

      final teacherStoryFirst = await supabase
          .from('list_stories')
          .select()
          .eq('class_id', classIdList[0]);
      print("teacherStoriesResponseOne: $teacherStoryFirst");
      final teacherStories = await supabase
          .from('list_stories')
          .select()
          .inFilter('class_id', classIdList)
          .lte('level', studentLevel);
      print("teacherStoriesResponse: $teacherStories");
      stories =
          (teacherStories as List).map((json) => Story.fromJson(json)).toList();

      String folder =
          widget.moduleType == 'teachers_pick' ? 'default' : widget.moduleType;
      for (int i = 0; i < stories.length; i++) {
        try {
          storyThumbnails[stories[i].storyId] =
              'assets/story_thumbnails/teachers_pick/default.png';
        } catch (e) {
          print('Error listing files: $e');
        }
      }

      return [stories, studentLevel];
    }
    else {
      ///Fetch stories
      print("MODULE.dart :: _fetchStories() called");

      List<Story> stories = await DatabaseHelper.instance.queryWhere(
          'list_stories', Story.fromJson, 'module = ?', [widget.moduleType]);

      //print("Stories");
      //print(stories);

      ///The user has to be logged in
      final userId = Supabase.instance.client.auth.currentUser?.id;

      ///get story module type
      List<UserLevelInfo> userLevelInfoList = await DatabaseHelper.instance
          .queryWhere('user_level_info', UserLevelInfo.fromJson, 'user_id = ?',
              [userId]);
      UserLevelInfo? userInfo = userLevelInfoList[0];

      print("user level info gotten");
      int moduleLevel = 5;

      switch (widget.moduleType) {
        case "narrative":
          moduleLevel = userInfo!.narrativeLevel;
          break;
        case "information":
          moduleLevel = userInfo!.informationLevel;
          break;
        case "vocab":
          moduleLevel = userInfo!.vocabLevel;
          break;
      }

      ///get story thumbnails
      for (int i = 0; i < stories.length; i++) {
        try {
          storyThumbnails[stories[i].storyId] =
              'assets/story_thumbnails/${widget.moduleType}/${stories[i].storyId}.png';
        } catch (e) {
          print('Error listing files: $e');
        }
      }

      //print("story thumbnails: $storyThumbnails");
      ///sort stories according to level
      stories.sort((a, b) => a.level.compareTo(b.level));

      return [stories, moduleLevel];
    }
  }

  @override
  void initState() {
    super.initState();
    storiesAndLevel =
        _fetchStoriesAndUserLevel(); // Start the async operation in initState
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
          if(snapshot.hasData && widget.moduleType == 'teachers_pick' && snapshot.data?[0].isEmpty)
            {
              return Center(child:  Text("No stories yet!", style: TextStyle(color: textColor, fontSize: 32)));
            }

          final stories = snapshot.data?[0];
          final userLevel = snapshot.data?[1];

          // S curve horizontal swing
          final minSpacing = 150.0; // minimum vertical distance between stories
          final topPadding = 50.0;
          final bottomPadding = 50.0;

          // calculate vertical spacing dynamically
          final verticalSpacing = stories.length > 1 ? minSpacing : 0.0;

          final totalHeight = topPadding +
              bottomPadding +
              (stories.length - 1) * verticalSpacing +
              150; // extra buffer for last button
          final offsets = [0, 70, 0, -70, 0, 70];

          return SingleChildScrollView(
            child: SizedBox(
              height: totalHeight,
              width: screenWidth,
              child: Stack(
                children: [
                  for (int i = 0; i < stories.length; i++)
                    Positioned(
                      top: topPadding + i * verticalSpacing,
                      left: screenWidth / 2 - 32 + offsets[i % offsets.length],
                      child: StoryButton(
                        userLevel: userLevel,
                        storyLevel: stories[i].level,
                        imageAsset: storyThumbnails[stories[i].storyId]!,
                        onPressed: () => context.go(
                            '/story/${stories[i].storyId}/${stories[i].level}',
                            extra: widget.moduleType == 'teachers_pick'),
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
