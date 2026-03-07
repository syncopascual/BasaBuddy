import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:basabuddy/components/StreakServices.dart';

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
    try {
      final data = await getLevelsandStreakData();
      setState(() {
        levelsAndStreakData = data;
        loading = false;
      });
    } catch (e) {
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
  Future<Map<String, dynamic>> getLevelsandStreakData() async {
    final user = supabase.auth.currentUser;
    final userId = user?.id;
    if(userId == null) {
      throw Exception("No user logged in");
    }

    final levelsRes = await supabase
      .from('user_level_info')
      .select('id, vocab_lvl, narrative_lvl, information_lvl')
      .eq('user_id', userId)
      .single();

    final streak = await StreakService().getCurrentStreak(userId);

    return {
      'levels': levelsRes,
      'streak': streak,
    };
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
    
    return Scaffold(
      backgroundColor: const Color(0xFF66E1DD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Text(
              "Your Reading Journey",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Stories Completed: ",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Reading Streak: $streak",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Vocabulary: $vocab_lvl",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Narrative Stories: $narrative_lvl",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Information Texts: $information_lvl",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),]
            )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "My Classes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showJoinClassSheet(context), 
                  icon: const Icon(Icons.add),
                  label: const Text("Join a New Class", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF35ADD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Account Info",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Email"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Shop",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      ImageIcon(
                        const AssetImage("assets/icons/fire.png"),
                        color: Color(0xFF7FDBFF),
                      ),
                      const SizedBox(width: 12),
                      const Text("Buy a Streak Freeze"),
                    ],),
                    
                    ElevatedButton(
                      onPressed: () async {
                        final userId = supabase.auth.currentUser?.id;
                        if (userId == null) return;

                        try {
                          // Freeze streak until end of next day
                          await StreakService().freezeStreak(userId);

                          // Optional: show confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Streak frozen until tomorrow! ❄️')),
                          );

                          // Refresh profile data in case you want to show frozen streak in UI
                          loadData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to freeze streak: $e')),
                          );
                        }
                      },
                      child: Row(children: [
                        const SizedBox(width: 36),
                        const Text("Buy"),
                        const SizedBox(width: 36),
                      ],),
            
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    iconColor: Color(0xFFF28B82), // soft red
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 48), // full width like "Join a New Class"
                  ),
                  child: const Text("Logout"),
          ),
        ],
      ),
      ),
    );
  }
}
