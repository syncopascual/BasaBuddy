import 'package:basabuddy/utils/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:basabuddy/components/StreakServices.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ProgressScreen  extends StatefulWidget {
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic>? levelsAndStreakData;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }
  void loadData() async {
    final online = await hasInternet();
    print(online ? "WITH INTERNET" : "WITHOUT INTERNET");
    try {
      final data = await getLevelsandStreakData(online: online);
      if (!mounted) return;
      setState(() {
        levelsAndStreakData = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading=false;
      });
    }
    
  }

  void _showJoinClassSheet(BuildContext context) {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Join a Class",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Enter the class code your teacher gave you.",
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: "Class Code",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final code = codeController.text.trim();
                  if (code.isNotEmpty) {
                    _joinClass(code);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color (0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Join Class"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  final supabase = Supabase.instance.client;

  Future<bool> hasInternet() async {
    final connResult = await Connectivity().checkConnectivity();
    if (connResult == ConnectivityResult.none) return false;

    try {
      final response = await http.get(Uri.parse('https://google.com'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  Future<void> _joinClass(String code) async {
    final context = this.context;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    try {
      final classRes = await supabase
        .from('classes')
        .select('id')
        .eq('class_code', code)
        .maybeSingle();
      if (classRes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class code not found')),
        );
        return;
      }

      await supabase.from('class_students').insert({
        'class_id': classRes['id'],
        'student_id': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the class!')),
      );
      loadData();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already joined this class')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
    
  }
  Future<Map<String, dynamic>> getLevelsandStreakData({required bool online}) async {
    final user = supabase.auth.currentUser;
    final userId = user?.id;
    if(userId == null) {
      throw Exception("No user logged in");
    }

    final db = await DatabaseHelper.instance.db;
    final vocab = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM list_stories WHERE module = 'vocab'"
      ),
    );

    final narrative = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM list_stories WHERE module = 'narrative'"
      ),
    );

    final info = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM list_stories WHERE module = 'information'"
      ),
    );
    if (online) {
      final levelsRes = await supabase
        .from('user_level_info')
        .select('user_id, vocab_lvl, narrative_lvl, information_lvl')
        .eq('user_id', userId)
        .single();

      final streak = await StreakService().getCurrentStreak(userId);

      final completedStoriesRes = await supabase
        .from('stage_level')
        .select('user_id, story_id')
        .eq('user_id', userId);

      final uniqueStoryIds = (completedStoriesRes as List)
        .map((row) => row['story_id'] as String)
        .toSet()
        .toList();

      if (uniqueStoryIds.isEmpty) {
        return {
          'levels': levelsRes,
          'streak': streak,
          "storiesCompleted": 0,
          "vocabStories": 0,
          "infoStories": 0,
          "narrativeStories": 0,
          'total_vocab': vocab,
          'total_info': info,
          'total_narrative': narrative,
        };
      }
      final completedStoryIds = uniqueStoryIds; // e.g., ['id1', 'id2', 'id3']

      final orQuery = completedStoryIds.map((story_id) => 'story_id.eq.$story_id').join(',');

      final storiesWithModules = await supabase
          .from('list_stories')
          .select('story_id, module')
          .or(orQuery);

      final modulesMap = <String, Set<String>>{
        'vocab': {},
        'information': {},
        'narrative': {},
      };

      for (final story in storiesWithModules) {
        final module = story['module'] as String;
        final storyId = story['id'] as String;

        if (modulesMap.containsKey(module)) {
          modulesMap[module]!.add(storyId);
        }
      }

      print("${modulesMap['vocab']!.length}, ${modulesMap['information']!.length}, ${modulesMap['vocab']!.length}");
      await db.insert(
        "user_level_info",
        {
          "user_id": userId,
          "vocab_lvl": levelsRes["vocab_lvl"],
          "narrative_lvl": levelsRes["narrative_lvl"],
          "information_lvl": levelsRes["information_lvl"],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      

      return {
        'levels': levelsRes,
        'streak': streak,
        'storiesCompleted': uniqueStoryIds.length,
        'vocab_stories': modulesMap['vocab']!.length,
        'narrative_stories': modulesMap['narrative']!.length,
        'info_stories': modulesMap['information']!.length,
        'total_vocab': vocab,
        'total_info': info,
        'total_narrative': narrative,
      };
    } else {
      final localLevels = await db.query(
        "user_level_info",
        where: "user_id = ?",
        whereArgs: [userId],
      );

      final localStories = await db.query(
        'stage_level',
        columns: ['story_id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final localStreak = await db.query(
        'user_streak',
        columns: ['current_streak'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final uniqueStoryIds = (localStories as List)
        .map((row) => row['story_id'] as String)
        .toSet()
        .toList();
      print("UNIQUE STORIES: $uniqueStoryIds");
      if (uniqueStoryIds.isEmpty) {
        return {
          'levels': localLevels.first,
          'streak': localStreak.isNotEmpty ? localStreak.first['current_streak'] as int : 0,
          "storiesCompleted": 0,
          "vocabStories": 0,
          "infoStories": 0,
          "narrativeStories": 0,
          'total_vocab': vocab,
          'total_info': info,
          'total_narrative': narrative,
        };
      }
      final completedStoryIds = uniqueStoryIds;

      final storiesWithModules = await db.query(
        'list_stories',
        columns: ['story_id, module'],
        where: 'story_id IN (${completedStoryIds.map((_) => '?').join(',')})',
        whereArgs: completedStoryIds,
      );

      final modulesMap = <String, Set<String>>{
        'vocab': {},
        'information': {},
        'narrative': {},
      };

      for (final story in storiesWithModules) {
        final module = story['module'] as String;
        final storyId = story['story_id'] as String;
        print("STORY: $module, $storyId");

        if (modulesMap.containsKey(module)) {
          modulesMap[module]!.add(storyId);
        }
      }

      print("${modulesMap['vocab']!.length}, ${modulesMap['information']!.length}, ${modulesMap['vocab']!.length}");

      int uniqueStoriesOffline = localStories.map((e) => e['story_id']).toSet().length;

      if (localLevels.isEmpty){
        throw Exception("No offline progress available");
      }

      return {
        "levels": localLevels.first,
        "streak": localStreak.isNotEmpty ? localStreak.first['current_streak'] as int : 0,
        'storiesCompleted': uniqueStoriesOffline,
        'vocab_stories': modulesMap['vocab']!.length,
        'narrative_stories': modulesMap['narrative']!.length,
        'info_stories': modulesMap['information']!.length,
        'total_vocab': vocab,
        'total_info': info,
        'total_narrative': narrative,
      };
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null){
      return Center(child: Text('Error: $error'));
    }

    final vocab_lvl = levelsAndStreakData!['levels']['vocab_lvl'];
    final narrative_lvl = levelsAndStreakData!['levels']['narrative_lvl'];
    final information_lvl = levelsAndStreakData!['levels']['information_lvl'];
    final streak = levelsAndStreakData!['streak'];
    final stories_read = levelsAndStreakData!['storiesCompleted'];
    final vocab_stories_read = levelsAndStreakData!['vocab_stories'];
    final information_stories_read = levelsAndStreakData!['info_stories'];
    final narrative_stories_read = levelsAndStreakData!['narrative_stories'];
    final total_vocab = levelsAndStreakData!['total_vocab'];
    final total_info = levelsAndStreakData!['total_info'];
    final total_narrative = levelsAndStreakData!['total_narrative'];

    print("Vocab: $vocab_stories_read / $total_vocab, Info: $information_stories_read / total_info, Narrative: $narrative_stories_read / $total_narrative");
    
    
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border: Border.all(
                  color: const Color(0xFFF6E7B0),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Your Reading Journey",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3D4C),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatTile(icon: Icons.menu_book, label: "Stories", value: stories_read.toString()),
                      StatTile(icon: Icons.local_fire_department, label: "Streak", value: streak.toString()),
                      StatTile(icon: Icons.abc, label: "Vocab", value: vocab_lvl.toString()),
                      StatTile(icon: Icons.auto_stories, label: "Narrative", value: narrative_lvl.toString()),
                      StatTile(icon: Icons.article, label: "Info Texts", value: information_lvl.toString()),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all( // Corrected line
                color: const Color(0xFFF6E7B0),
                width: 1.5, // Specify the width of the border
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Module Progress",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F3D4C)),
                ),
                const SizedBox(height: 12),
                ModuleProgress(
                  title: "Vocabulary",
                  progress: vocab_stories_read/total_vocab,
                  color: Colors.orange,
                ),

                ModuleProgress(
                  title: "Narrative",
                  progress: narrative_stories_read/total_narrative,
                  color: Color(0xFFE5CAF3),
                ),

                ModuleProgress(
                  title: "Informational",
                  progress: information_stories_read/total_info,
                  color: Color(0xFF6DC544),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all( // Corrected line
                color: const Color(0xFFF6E7B0),
                width: 1.5, // Specify the width of the border
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Skills You Practiced",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SkillIcon(icon: Icons.lightbulb, label: "Inference"),
                    SkillIcon(icon: Icons.search, label: "Context"),
                    SkillIcon(icon: Icons.format_list_numbered, label: "Sequence"),
                    SkillIcon(icon: Icons.star, label: "Main Idea"),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all( // Corrected line
                color: const Color(0xFFF6E7B0),
                width: 1.5, // Specify the width of the border
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Badges",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    BadgeIcon(icon: Icons.emoji_events, color: Color(0xFFFACC15)),
                    SizedBox(width: 10),
                    BadgeIcon(icon: Icons.local_fire_department, color: Colors.orange),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 70,
  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  child: Column(
    mainAxisSize: MainAxisSize.min, // <-- tightens the column
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 20, color: Colors.orange),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
    ],
  ),
);
  }
}

class ModuleProgress extends StatelessWidget {
  final String title;
  final double progress;
  final Color color;

  const ModuleProgress({
    required this.title,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
        SizedBox(height: 14),
      ],
    );
  }
}

class SkillIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const SkillIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFFFFF3C4),
          child: Icon(icon, color: Colors.orange),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12))
      ],
    );
  }
}

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const BadgeIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 28),
    );
  }
}