import 'package:basabuddy/bloc/freeze_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:basabuddy/utils/database_helper.dart';

import '../../bloc/booster_bloc.dart';
import '../../bloc/money_bloc.dart';
import '../../bloc/connectivity_bloc.dart';
import '../../components/StreakServices.dart';

// import your connectivity bloc path here
// import 'package:your_app/bloc/connectivity_bloc.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool loading = true;
  String? error;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Trigger initial load based on bloc state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ConnectivityBloc>().state;
      if (state is ConnectivitySuccess && state.isConnected) {
        loadData();
      } else if (state is ConnectivityInitial) {
        // Wait for bloc to emit — listener will handle it
        setState(() => loading = true);
      } else {
        setState(() => loading = false);
      }
    });
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await getProfileData();
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final db = await DatabaseHelper.instance.db;
        final streakRow = await db.query(
          'user_streak',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        final freezeCount = streakRow.isNotEmpty
            ? (streakRow.first['freeze_count'] as int? ?? 0)
            : 0;

        if (mounted) {
          context.read<FreezeBloc>().add(SetFreeze(freezeCount));
        }
      }
      setState(() {
        profileData = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
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
              const Text("Enter the class code your teacher gave you."),
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

  Future<void> _joinClass(String code) async {
    final context = this.context;
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
        const SnackBar(
            content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  Future<Map<String, dynamic>> getProfileData() async {
    final user = supabase.auth.currentUser;
    final email = user?.email;
    final userId = user?.id;
    if (userId == null) throw Exception("No user logged in");

    final profileRes = await supabase
        .from('profiles')
        .select('id, name, role')
        .eq('id', userId)
        .single();

    final classesRes = await supabase
        .from('class_students')
        .select(
            'classes(class_code,year,name,teacher_id, teacher:profiles(name))')
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

  Widget _buildNoInternetScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF66E1DD),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 80, color: Colors.white70),
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
                style: TextStyle(fontSize: 15, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
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
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF3FC3D4),
                  child:
                      const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['name'],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
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
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showJoinClassSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Join a New Class",
                        style: TextStyle(color: Colors.white)),
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
                      Row(
                        children: [
                          ImageIcon(
                            const AssetImage("assets/icons/fire.png"),
                            color: Color(0xFF7FDBFF),
                          ),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Buy a Streak Freeze"),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text("40"),
                                  Image.asset(
                                    'assets/icons/crystal.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  SizedBox(width: 4),
                                  BlocBuilder<FreezeBloc, FreezeState>(
                                    builder: (context, state) {
                                      return Text(
                                          "Freezes: ${state.freezeCount}/2");
                                    },
                                  )
                                ])
                              ])
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final userId = supabase.auth.currentUser?.id;
                          if (userId == null) return;

                          try {
                            // Freeze streak until end of next day
                            final success =
                                await StreakService().freezeStreak(userId);

                            if (!context.mounted) return;

                            if (!success) {
                              final moneyRow = await DatabaseHelper.instance.db
                                  .then((db) => db.query('user_money',
                                      where: 'user_id = ?',
                                      whereArgs: [userId]));

                              final money = moneyRow.isNotEmpty
                                  ? (moneyRow.first['money'] as int? ?? 0)
                                  : 0;

                              final msg = money < 40
                                  ? 'Not enough crystals! You need 40.'
                                  : 'You already have 2 streak freezes held.';

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                              return;
                            }
                            if (!context.mounted) return;
                            final moneyRow = await DatabaseHelper.instance.db
                                .then((db) => db.query('user_money',
                                    where: 'user_id = ?', whereArgs: [userId]));
                            final newMoney = moneyRow.isNotEmpty
                                ? (moneyRow.first['money'] as int? ?? 0)
                                : 0;
                            context.read<MoneyBloc>().add(SetMoney(newMoney));
                            context.read<FreezeBloc>().add(ChangeFreeze(1));
                            // Optional: show confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Bought a streak freeze! ❄️')),
                            );

                            // Refresh profile data in case you want to show frozen streak in UI
                            loadData();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to freeze streak: $e')),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            const SizedBox(width: 36),
                            const Text("Buy"),
                            const SizedBox(width: 36),
                          ],
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.bolt, color: Color(0xFFFFD700)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("XP Booster"),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text("30"),
                              Image.asset('assets/icons/crystal.png',
                                  width: 20, height: 20),
                              const SizedBox(width: 4),
                              BlocBuilder<BoosterBloc, BoosterState>(
                                builder: (context, state) {
                                  return Text(state.isActive
                                      ? "${state.storiesRemaining} stories left"
                                      : "Inactive");
                                },
                              ),
                            ]),
                          ],
                        ),
                      ]),
                      BlocBuilder<BoosterBloc, BoosterState>(
                        builder: (context, boosterState) {
                          return ElevatedButton(
                            onPressed: boosterState.isActive
                                ? null
                                : () async {
                                    final userId =
                                        supabase.auth.currentUser?.id;
                                    if (userId == null) return;

                                    final moneyRow = await DatabaseHelper
                                        .instance.db
                                        .then((db) => db.query('user_money',
                                            where: 'user_id = ?',
                                            whereArgs: [userId]));
                                    final money = moneyRow.isNotEmpty
                                        ? (moneyRow.first['money'] as int? ?? 0)
                                        : 0;

                                    if (money < 30) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Not enough crystals! You need 30.')),
                                      );
                                      return;
                                    }

                                    final now = DateTime.now()
                                        .toUtc()
                                        .toIso8601String();
                                    final db = await DatabaseHelper.instance.db;
                                    final newMoney = money - 30;

                                    await db.update('user_money',
                                        {'money': newMoney, 'updated_at': now},
                                        where: 'user_id = ?',
                                        whereArgs: [userId]);
                                    try {
                                      await supabase.from('user_money').upsert({
                                        'user_id': userId,
                                        'money': newMoney,
                                        'updated_at': now,
                                      }, onConflict: 'user_id');
                                    } catch (_) {}

                                    if (!context.mounted) return;
                                    context
                                        .read<MoneyBloc>()
                                        .add(SetMoney(newMoney));
                                    context
                                        .read<BoosterBloc>()
                                        .add(SetBooster(3));

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'XP Booster active! Next 3 stories earn 2x 💥')),
                                    );
                                  },
                            child: Row(children: [
                              const SizedBox(width: 20),
                              Text(boosterState.isActive ? "Active" : "Buy"),
                              const SizedBox(width: 20),
                            ]),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                iconColor: const Color(0xFFF28B82),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivitySuccess && state.isConnected) {
          // Came back online — reload if we don't have data yet
          if (profileData == null) {
            loadData();
          }
        }
      },
      child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, state) {
          // Still waiting for the first connectivity result
          if (state is ConnectivityInitial || loading) {
            return const Scaffold(
              backgroundColor: Color(0xFF66E1DD),
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          // No internet
          if (state is ConnectivityFailure) {
            return _buildNoInternetScreen();
          }

          // Online — show profile
          return _buildProfileContent();
        },
      ),
    );
  }
}
