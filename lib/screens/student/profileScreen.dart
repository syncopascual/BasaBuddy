import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:basabuddy/components/StreakServices.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool loading = true;
  String? error;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  Future<bool> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _checkAndLoad() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await loadData(); // will handle SocketException internally
    } catch (_) {
      setState(() {
        hasInternet = false;
        loading = false;
      });
    }
  }

  Future<void> loadData() async {
    try {
      final data = await getProfileData();
      setState(() {
        profileData = data;
        loading = false;
        hasInternet = true; // success means we have internet
      });
    } on SocketException catch (_) {
      setState(() {
        error = null;
        loading = false;
        hasInternet = false; // show offline page
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
        hasInternet = true; // we tried to connect, just some other error
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
                  backgroundColor: const Color(0xFF4CAF50),
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

  Future<Map<String, dynamic>> getProfileData() async {
    final user = supabase.auth.currentUser;
    final email = user?.email;
    final userId = user?.id;
    if (userId == null) {
      throw Exception("No user logged in");
    }

    final profileRes = await supabase
        .from('profiles')
        .select('id, name, role')
        .eq('id', userId)
        .single();

    final classesRes = await supabase
        .from('class_students')
        .select('classes(class_code,year,name,teacher_id, teacher:profiles(name))')
        .eq('student_id', userId);

    return {
      'profile': profileRes,
      'classes': classesRes,
      'email': email,
    };
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    context.go('/login');
  }

  // --- No Internet Screen ---
  Widget _buildNoInternetScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF66E1DD),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              const Text(
                "No Internet Connection",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please check your connection and try again.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkAndLoad,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF35ADD3),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF66E1DD),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!hasInternet) {
      return _buildNoInternetScreen();
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    final profile = profileData!['profile'];
    final classes = profileData!['classes'] as List;
    final email = profileData!['email'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF66E1DD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF3FC3D4),
              child: const Icon(Icons.person, size:40, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile['name'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
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
              ...classes.map((c) {
                final classData = c['classes'];
                return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.class_),
                  title: Text(classData['name']),
                  subtitle: Text(classData['year']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              );
              }),
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
                  Text(email),
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