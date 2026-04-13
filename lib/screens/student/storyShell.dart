import 'dart:ffi';

import 'package:basabuddy/Miscellaneous.dart';
import 'package:basabuddy/bloc/money_bloc.dart';
import 'package:basabuddy/components/FinishedStoryPopup.dart';
import 'package:basabuddy/components/question_components/MatchingExercise.dart';
import 'package:basabuddy/components/question_components/MulchoExercise.dart';
import 'package:basabuddy/components/question_components/OrderingExercise.dart';
import 'package:basabuddy/models/orderData.dart';
import 'package:basabuddy/models/stageData.dart';
import 'package:basabuddy/wrappers/StoryItem.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:basabuddy/components/StreakServices.dart';
import 'package:basabuddy/components/StreakNotifier.dart';
import 'package:basabuddy/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../../colors.dart';
import '../../components/question_components/FillBlankExercise.dart';
import '../../components/Page.dart';
import '../../components/ProgressBar.dart';
import '../../models/fillBlankData.dart';
import '../../models/matchingData.dart';
import '../../models/mulcho.dart';
import '../../models/story.dart';
import '../../models/storyPage.dart';
import '../../utils/database_helper.dart';

///This class fetches the story, its pages and exercises, from the database
/// Then orders them, displays them, and keeps track of the current page

class StoryShell extends StatefulWidget {
  final String storyId;
  final bool isTeacherStory;
  const StoryShell({super.key, required this.storyId, this.isTeacherStory = false,});

  @override
  State<StoryShell> createState() => _StoryShellState();
}

Future<void> addStageData(storyId, Map<String, int> skillScores, Map<String, int> totalItems, Map<String, int> totalAttempts,
    Map<String, int> firstAttemptCorrect) async
{
  try{
    print("addStageData called: $storyId, skillScores: $skillScores, totalItems:$totalItems, totalAttempts$totalAttempts");
    //get user id from user_level_info table
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    String userId = user.id;
    String safeDate = DateTime.now().toIsoDate();
    final db = await DatabaseHelper.instance.db;

    for (final entry in skillScores.entries)  {
      final key = entry.key;
      if (!totalItems.containsKey(key) || !totalAttempts.containsKey(key) || !firstAttemptCorrect.containsKey(key)) continue;

      print("Processing skill: $key, date: $safeDate");
      try {
        final existing = await db.query(
          'stage_level',
          where: 'user_id = ? AND story_id = ? AND skill= ? and date = ?',
          whereArgs: [userId, storyId, key, safeDate],
        );
        print("Existing rows found for $key: ${existing.length}");

        if (existing.isEmpty){
          await db.insert(
            "stage_level",
            {
              "user_id": userId,
              "story_id": storyId,
              "skill": key,
              "total_items": totalItems[key]!,
              "total_attempts": totalAttempts[key]!,
              "first_attempt_correct": firstAttemptCorrect[key]!,
              "date": safeDate,
              "updated_at": now,
            },
          );
          print("SQLite: inserted new row for $key");
        } else {
          await db.update(
            'stage_level',
            {
              'total_attempts': (existing.first['total_attempts'] as int) + totalAttempts[key]!,
              'first_attempt_correct': (existing.first['first_attempt_correct'] as int) + firstAttemptCorrect[key]!,
              'updated_at': now,
            },
            where: 'user_id = ? AND story_id = ? AND skill= ? and date = ?',
            whereArgs: [userId, storyId, key, safeDate],
          );
          print("SQLite: updated existing row for $key");
        }
      } catch (e) {
        print("SQLite error for $key: $e");
      }

      try {
        await Supabase.instance.client.rpc('upsert_stage_level', params: {
          'p_user_id': userId,
          'p_story_id': storyId,
          'p_skill': key,
          'p_date': safeDate,
          'p_total_items': totalItems[key]!,
          'p_total_attempts': totalAttempts[key]!,
          'p_first_attempt_correct': firstAttemptCorrect[key]!,
          'p_updated_at': now,
        });
      } catch(e) {
        print("Supabase upsert failed: $e");
      }
  } 
  } catch(e) {
    print("error uploading data");
  }

}

class _StoryShellState extends State<StoryShell> {
  late Future<List<StoryItem>> _storyFuture;
  late Map<String, int> skillScores = {};

  ///scoring for each skill, will be uploaded to stage_data
  Map<int, String> imageURLs = {};
  late int numPages = 0;

  ///needed for precaching
  int currentPage = 0;

  ///stageData data for teacher analytics

  Map<String, int> totalAttempts = {};
  Map<String, int> totalItems = {};

  ///whenever a student gets an item wrong, it will be removed from this list
  ///when the story finishes, the remaining items count will be the firstAttemptCorrect
  List<StoryItem> firstAttemptObjects = [];
  List<StoryItem> allStoryItems = [];
  Map<String, int> firstAttemptCorrect = {};

  //todo: fix this, as currentPage accounts for exercises as well. this should be based on pageNum
  //todo: fix possible Invalid argument(s): No host specified in URI file:/// issues





  void wrongAnswer(StoryItem currentItem) {
    firstAttemptObjects.removeWhere(
          (item) => currentItem.eq(item),
    );
    print("First wrong answer!");
  }

  ///Fetch the story's pages and exercises from supabase, and orders them
  Future<List<StoryItem>> _fetchPagesNexercises() async {
    print(
        "STORYSHELL.dart: _fetchPagesNexercises() called, storyId: ${widget.storyId}");

    /// Fetch the story's pages
    List<Storypage> pages;

    if (widget.isTeacherStory) {
      final response = await Supabase.instance.client
          .from('story_page')
          .select()
          .eq('story_id', widget.storyId);

      pages = (response as List)
          .map((json) => Storypage.fromJson(json))
          .toList();
    } else {
      pages = await DatabaseHelper.instance.queryWhere(
          'story_page',
          Storypage.fromJson,
          'story_id = ?',
          [widget.storyId]);
      print("PAGES HERE: $pages");
    }

    final List<PageItem> wrappedPages =
    pages.map((page) => PageItem(page)).toList();

    numPages = pages.length;

    for (int i = 0; i < pages.length; i++) {
      try {
        String url = 'assets/story_pages/${pages[i].storyId}/${pages[i].pageNum}.png';
        bool exists = true; //TODO: function that verifies that file exists
        print("image path $url");

        if (exists){
          imageURLs[pages[i].pageNum] = url;
        } else {
          imageURLs[pages[i].pageNum] = "";
        }

      } catch (e) {
        imageURLs[pages[i].pageNum] = ""; // fallback
      }
    }

    //print("imageURLs to precache: $imageURLs");

    late List<Mulcho> mulcho;
    List<StoryItem> wrappedMulcho = [];

    ///FETCH MULTIPLE CHOICE EXERCISES
    try {
      if (widget.isTeacherStory) {
        final response = await Supabase.instance.client
            .from('mulcho_exercise')
            .select()
            .eq('story_id', widget.storyId);
        print("RESPONSE: $response");
        for (var item in response) {
          print('--- item ---');
          item.forEach((key, value) {
            print('key: $key, value: $value, type: ${value.runtimeType}');
          });
        }
        mulcho = (response as List)
            .map((json) => Mulcho.fromJson(json))
            .toList();
        print("mulcho: $mulcho");
      } else {
        mulcho = await DatabaseHelper.instance.queryWhere(
            'mulcho_exercise',
            Mulcho.fromJson,
            'story_id = ?',
            [widget.storyId]);
      }
      print("STORYSHELL.dart: mulcho fetched");

      ///for type safety
      wrappedMulcho = mulcho.map<StoryItem>((mul) => MulchoItem(mul)).toList();
      print("wrapped mulcho $wrappedMulcho");

      ///create a map that has all the skills of the story
      for (int i = 0; i < mulcho.length; i++) {
        ///If the skill isn't in the dictionary yet, add and set to zero
        ///the value of each skill is the amount of mistakes a student makes
        if (!skillScores.containsKey(mulcho[i].skill)) {
          skillScores[mulcho[i].skill] = 0;

        }
        totalItems[mulcho[i].skill] = (totalItems[mulcho[i].skill] ?? 0) + 1;

      }
      print("skillScores: $skillScores");
    } catch (e) {
      print("mulcho error");
      print(e);
    }

    ///FETCH ORDERING EXERCISES
    late List<OrderData> orderData;
    List<StoryItem> wrappedOrderData = [];
    try {

      if (widget.isTeacherStory) {
        final response = await Supabase.instance.client
            .from('ordering_exercise')
            .select()
            .eq('story_id', widget.storyId);

        orderData = (response as List)
            .map((json) => OrderData.fromJson(json))
            .toList();
      } else {
        orderData = await DatabaseHelper.instance.queryWhere(
            'ordering_exercise',
            OrderData.fromJson,
            'story_id = ?',
            [widget.storyId]);
      }
      print("STORYSHELL.dart: ordering exercise fetched");


      ///for type safety
      wrappedOrderData =
          orderData.map<StoryItem>((data) => OrderItem(data)).toList();

      ///create a map that has all the skills of the story
      for (int i = 0; i < orderData.length; i++) {
        ///If the skill isn't in the dictionary yet, add and set to zero
        ///the value of each skill is the amount of mistakes a student makes
        if (!skillScores.containsKey(orderData[i].skill)) {
          skillScores[orderData[i].skill] = 0;
        }
        totalItems[orderData[i].skill] = (totalItems[orderData[i].skill] ?? 0) + 1;
      }
    } catch (e) {
      print("order error");
      print(e);
    }

    ///FETCH MATCHING EXERCISES
    late List<MatchingData> matchData;
    List<StoryItem> wrappedMatchData = [];
    try {

      if (widget.isTeacherStory) {
        final response = await Supabase.instance.client
            .from('matching_exercise')
            .select()
            .eq('story_id', widget.storyId);

        matchData = (response as List)
            .map((json) => MatchingData.fromJson(json))
            .toList();
      } else {
        matchData = await DatabaseHelper.instance.queryWhere(
            'matching_exercise',
            MatchingData.fromJson,
            'story_id = ?',
            [widget.storyId]);
      }
      print("STORYSHELL.dart: matching exercise fetched");


      ///for type safety
      wrappedMatchData =
          matchData.map<StoryItem>((data) => MatchItem(data)).toList();

      ///create a map that has all the skills of the story
      for (int i = 0; i < matchData.length; i++) {
        ///If the skill isn't in the dictionary yet, add and set to zero
        ///the value of each skill is the amount of mistakes a student makes
        if (!skillScores.containsKey(matchData[i].skill)) {
          skillScores[matchData[i].skill] = 0;
        }
        totalItems[matchData[i].skill] = (totalItems[matchData[i].skill] ?? 0) + 1;
      }
    } catch (e) {
      print("match error");
      print(e);
    }

    ///FETCH FILL IN THE BLANK EXERCISES
    late List<FillBlankData> fillBlankData;
    List<StoryItem> wrappedFillBlankData = [];
    try {

      if (widget.isTeacherStory) {
        final response = await Supabase.instance.client
            .from('fill_in_blank')
            .select()
            .eq('story_id', widget.storyId);

        fillBlankData = (response as List)
            .map((json) => FillBlankData.fromJson(json))
            .toList();
      } else {
        fillBlankData = await DatabaseHelper.instance.queryWhere(
            'fill_in_blank',
            FillBlankData.fromJson,
            'story_id = ?',
            [widget.storyId]);
      }

      print("STORYSHELL.dart: fill in blank exercise fetched");


      ///for type safety
      wrappedFillBlankData =
          fillBlankData.map<StoryItem>((data) => FillBlankItem(data)).toList();

      print("converted to StoryItem");

      ///create a map that has all the skills of the story
      for (int i = 0; i < fillBlankData.length; i++) {
        ///If the skill isn't in the dictionary yet, add and set to zero
        ///the value of each skill is the amount of mistakes a student makes
        if (!skillScores.containsKey(fillBlankData[i].skill)) {
          skillScores[fillBlankData[i].skill] = 0;
        }
        totalItems[fillBlankData[i].skill] = (totalItems[fillBlankData[i].skill] ?? 0) + 1;
      }

      print("skillScores: $skillScores");
    } catch (e) {
      print("fillblank error");
      print(e);
    }

    try {
      print("MY MULCHO: ${wrappedMulcho}, MY MATCH: ${wrappedMatchData}");
      List<StoryItem> wrappedExercises = wrappedMulcho +
          wrappedFillBlankData +
          wrappedMatchData +
          wrappedOrderData;
      print("story components skills:");
      for (StoryItem item in wrappedExercises) {
        print(item.data.skill);
      }

      ///stage data stuff: create map for totalAttempts
      for(String skill in skillScores.keys){
        totalAttempts[skill] = 0;
      }
      firstAttemptObjects = wrappedExercises;
      print("ordering items...");

      ///order this correctly
      final orderedItems = orderItems(wrappedPages, wrappedExercises);
      allStoryItems = orderedItems;
      print("fetched pages and exercises!");

      return orderedItems;
    } catch (e) {
      print("ORDERING ERROR $e");
    }

    return [];
  }

  ///called inside _fetchPagesNexercises(), orders the items
  List<StoryItem> orderItems(List<PageItem> pages, List<StoryItem?> exercises) {
    List<StoryItem> ordered = [];
    print("MY PAGES $pages");
    if (pages.isEmpty) {
      print("EXERCISING! $exercises");
      for (var ex in exercises) {
        print("MY EX IS $ex");
        if (ex != null) {
          ordered.add(ex);
        }
      }
      print("ORDER UP: $ordered");
      return ordered;
    }
    if(exercises.isEmpty){
      return pages;
    }
    for (int i = 1; i <= pages.length; i++) {
      final page = pages.firstWhere((m) => m.data.pageNum == i);

      /// exercises before first page
      if (i == 1) {
        for (var ex in exercises) {
          if (ex?.data.afterPage == 0) {
            ordered.add(ex!);
          }
        }
      }

      ordered.add(page);

      /// exercises after this page
      for (var ex in exercises) {
        if (ex?.data.afterPage == i) {
          ordered.add(ex!);
        }
      }
    }
    return ordered;
  }

  ///
  Widget storyWidget(component, url, orderedStoryItems) {
    //print("component runtime type: ${component.runtimeType}");
    switch (component) {
      case Storypage page:
        final page = PageContainer(
          storyPage: component,
          imageURL: url,
        );
        return page;
      case Mulcho mulcho:
        final page = MulchoExercise(
          mulcho: component,
          bgImage: 'grassy',
          onCorrectAnswer: () {
            ///initialize if doesnt exist yet, else add one
            totalAttempts[component.skill] =
                (totalAttempts[component.skill] ?? 1) + 1;
            nextPage(orderedStoryItems);
          },
          onWrongAnswer: () {
            wrongAnswer(allStoryItems[currentPage]);
            totalAttempts[component.skill] =
                (totalAttempts[component.skill] ?? 1) + 1;
          },
        );
        return page;
      case OrderData order:
        final page = OrderingExercise(
          orderData: component,
          onCorrect: () {
            totalAttempts[component.skill] =
                (totalAttempts[component.skill] ?? 1) + 1;
            nextPage(orderedStoryItems);
          },
          onWrong: () {
            wrongAnswer(allStoryItems[currentPage]);
            totalAttempts[component.skill] = (totalAttempts[component.skill] ?? 0) + 1;
          },
        );
        return page;
      case FillBlankData fillBlank:
        final page = FillBlankExercise(
          fillBlankData: component,
          onCorrectAnswer: () {
            totalAttempts[component.skill] = (totalAttempts[component.skill] ?? 0) + 1;
            nextPage(orderedStoryItems);
          },
          onWrongAnswer: () {
            wrongAnswer(allStoryItems[currentPage]);
            totalAttempts[component.skill] = (totalAttempts[component.skill] ?? 0) + 1;
          },
        );
        return page;
      case MatchingData match:
        final page = MatchingExercise(
          matchingData: component,
          onCorrect: () {
            totalAttempts[component.skill] = (totalAttempts[component.skill] ?? 0) + 1;
            nextPage(orderedStoryItems);
          },
        );
        return page;

      default:
        return Text("story object doesnt match");
    }
  }

  ImageProvider<Object> determineBg(currentComponent) {
    int? pageNum;
    if (widget.isTeacherStory) {
      return AssetImage("assets/bg_images/grassy.png");
    }
    if (currentComponent is PageItem) {
      pageNum = currentComponent.data.pageNum;
    } else if (currentComponent is Storypage) {pageNum = currentComponent.pageNum;}

    if (pageNum != null) {
      final url = imageURLs[pageNum];
      if (url != null && url.isNotEmpty) {
        return AssetImage(url);
      }
    }

    return AssetImage("assets/bg_images/grassy.png");
  }

  @override
  void initState() {
    super.initState();
    _storyFuture = _fetchPagesNexercises();
  }

  @override
  Widget build(BuildContext context) {
    print("story.dart");
    return FutureBuilder(
        future: _storyFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            ///the loaded data
            var orderedStoryItems = snapshot.data!;

            if (orderedStoryItems.isEmpty) {
              return Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/bg_images/grassy.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "This stage has no story pages yet.",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              );
            }
            //print("storyShell.dart urls: $imageURLs, current page: $currentPage");

            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: determineBg(orderedStoryItems[currentPage]),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(children: [
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GradientLinearProgressBar(
                    value: currentPage / orderedStoryItems.length,
                    leftColor: Color(0xFF22C03A),
                    rightColor: Color(0xFFB2FF3E),
                    unfilledColor: Colors.grey,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: storyWidget(
                    orderedStoryItems[currentPage].data, "", orderedStoryItems),
                  ),
                ),
                
                SizedBox(height: 12),

                ///Don't display back and next button for question items
                orderedStoryItems[currentPage].runtimeType == PageItem
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ///BACK button
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected, // warm yellow
                          ),
                          onPressed: () {
                            ///if its the first page, dont do anything
                            if (currentPage == 0) {
                              return;
                            }
                            setState(() {
                              currentPage -= 1;
                            });
                          },
                          child: Text('Back',
                              style: TextStyle(color: textColor))),
                    ),

                    ///NEXT Button
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected, // warm yellow
                          ),
                          onPressed: () async {
                            ///if last page na
                            /// increase user level for this module and navigate to home screen
                            nextPage(orderedStoryItems);
                          },
                          child: Text('Next',
                              style: TextStyle(color: textColor))),
                    )
                  ],
                )
                    : Text(""),
              ]),
            );

            ///Row containing next button and back button
          } else {
            return  Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/bg_images/grassy.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Center(child: CircularProgressIndicator())
            );
          }
        });
  }
  bool _storyFinished = false;
  Future<void> nextPage(orderedStoryItems) async {
    ///if its the last page
    if (currentPage == orderedStoryItems.length - 1) {
      if (_storyFinished) return; // ← prevent double trigger
      _storyFinished = true;
      ///get stage_data

      for(StoryItem storyItem in firstAttemptObjects){
        ///tally items gotten correct in the first attempt per skill
        firstAttemptCorrect[storyItem.data.skill] = (firstAttemptCorrect[storyItem.data.skill] ?? 0) + 1;
      }

      final user = Supabase.instance.client.auth.currentUser;
      final streakService = StreakService();
      if (user != null) {
        await streakService.updateStreak(user.id);
        if (!mounted) return;
        streakNotifier.refresh(user.id);
      }
      print("firstAttemptCorrect, totalItems, totalAttempts");
      print("$firstAttemptCorrect, $totalItems, $totalAttempts");
      await addStageData(widget.storyId, skillScores, totalItems, totalAttempts, firstAttemptCorrect);

      if (!mounted) return; 

      BlocProvider.of<MoneyBloc>(context).add(ChangeMoney(50));

      ///Display onfinished popup
      showDialog(
        context: context,
        barrierDismissible: false, // user must act
        builder: (_) => FinishedStoryPopup(
          onContinue: () {
            //navigate to home
            context.go('/student/home');
          },
        ),
      );

      return;
    }
    setState(() {
      currentPage += 1;
    });


  }
}