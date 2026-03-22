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
  List<String> skillsPracticed = [];
  final Map<String, IconData> skillIcons = {
    // =========================
    // Vocabulary Skills
    // =========================
    'synonyms and antonyms': Icons.sync_alt,      // opposite/paired words
    'verbs': Icons.directions_run,                // action
    'nouns': Icons.category,                      // things/categories
    'pronouns': Icons.record_voice_over,          // referring to people
    'adjectives': Icons.color_lens,               // describing (color/quality)
    'content vocabulary': Icons.menu_book,        // subject words

    // =========================
    // Narrative Skills
    // =========================
    'story details': Icons.list_alt,              // details list
    'sequencing events': Icons.format_list_numbered, // order/sequence
    'problem and solution': Icons.lightbulb,      // solution/idea
    'characters feelings and traits': Icons.emoji_emotions, // emotions
    'cause and effect': Icons.call_split,         // cause → effect
    'drawing conclusions': Icons.check_circle,    // conclusion

    // =========================
    // Informational Skills
    // =========================
    'key details': Icons.star,                    // important info
    'identify text types': Icons.category,        // classification
    'text structure': Icons.view_week,            // structure/layout
  };

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
  String capitalizeEachWord(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
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
        .select('user_id, vocab_lvl, narrative_lvl, information_lvl, updated_at')
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
          "vocab_stories": 0,
          "info_stories": 0,
          "narrative_stories": 0,
          'total_vocab': vocab,
          'total_info': info,
          'total_narrative': narrative,
          'skillsPracticed': [],
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
        final storyId = story['story_id'] as String;

        if (modulesMap.containsKey(module)) {
          modulesMap[module]!.add(storyId);
        }
      }

      final completedSkillsRes = await supabase
        .from('stage_level')
        .select('skill')
        .eq('user_id', userId);

      final uniqueSkills = <String>{};
      for (final row in completedSkillsRes) {
        final skill = row['skill'] as String;
        uniqueSkills.add(skill);
      }
      final skillsWithIcons = uniqueSkills.map((s) => {
        'skill': s,
        'icon': skillIcons[s] ?? Icons.help_outline,
      }).toList();

      print("${modulesMap['vocab']!.length}, ${modulesMap['information']!.length}, ${modulesMap['vocab']!.length}");
      await db.insert(
        "user_level_info",
        {
          "user_id": userId,
          "vocab_lvl": levelsRes["vocab_lvl"],
          "narrative_lvl": levelsRes["narrative_lvl"],
          "information_lvl": levelsRes["information_lvl"],
          'updated_at': levelsRes["updated_at"]
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
        'skillsPracticed': skillsWithIcons,
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
          "vocab_stories": 0,
          "info_stories": 0,
          "narrative_stories": 0,
          'total_vocab': vocab,
          'total_info': info,
          'total_narrative': narrative,
          'skillsPracticed': [],
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

      final completedSkillsRes = await db.query(
        'stage_level',
        columns: ['skill'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final uniqueSkills = <String>{};
      for (final row in completedSkillsRes) {
        final skill = row['skill'] as String;
        uniqueSkills.add(skill);
      }

      final skillsWithIcons = uniqueSkills.map((s) => {
        'skill': s,
        'icon': skillIcons[s] ?? Icons.help_outline,
      }).toList();

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
        'skillsPracticed': skillsWithIcons,
      };
    }
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

    print("Vocab: $vocab_stories_read / $total_vocab, Info: $information_stories_read / $total_info, Narrative: $narrative_stories_read / $total_narrative");
    print("Skills: ${levelsAndStreakData!['skillsPracticed']}");
    
    
    
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
                  progress: total_vocab > 0 ? vocab_stories_read / total_vocab : 0.0,
                  color: Colors.orange,
                ),

                ModuleProgress(
                  title: "Narrative",
                  progress: total_narrative > 0 ? narrative_stories_read / total_narrative : 0.0,
                  color: Color(0xFFE5CAF3),
                ),

                ModuleProgress(
                  title: "Informational",
                  progress: total_info > 0 ? information_stories_read / total_info : 0.0,
                  color: Color(0xFF6DC544),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
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
                if (levelsAndStreakData!['skillsPracticed'] != null &&
                  (levelsAndStreakData!['skillsPracticed'] as List).isNotEmpty)
                LayoutBuilder(
          builder: (context, constraints) {
            final skillList = levelsAndStreakData!['skillsPracticed'] as List;
            final spacing = 12.0; // horizontal spacing
            final iconsPerRow = 4;
            final iconWidth = (constraints.maxWidth - spacing * (iconsPerRow - 1)) / iconsPerRow;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: skillList.map((skillMap) {
                final skillName = capitalizeEachWord(skillMap['skill'] as String);
                final skillIcon = skillMap['icon'] as IconData;
                return SizedBox(
                  width: iconWidth,
                  child: SkillIcon(icon: skillIcon, label: skillName),
                );
              }).toList(),
            );
          },
        )
              else
                const Text("No skills practiced yet."),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFFFFF3C4),
          child: Icon(icon, color: Colors.orange),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12), textAlign: TextAlign.center,)
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