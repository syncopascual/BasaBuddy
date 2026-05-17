import 'package:basabuddy/screens/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../colors.dart';

class Signup extends StatefulWidget {
  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _role = 'student';
  bool _loading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;
      if (user == null) throw "Signup Failed";

      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'role': _role,
        'name': _nameController.text.trim(),
      });

      await initializeUserData(user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully created account!")),
      );

      context.go('/login');
    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg_images/bahay_kubo.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                            onTap: () {
                              context.go('/login');
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: const Icon(Icons.arrow_back),
                            )),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),

                  ///Email text field
                  _input(_nameController, "Full Name"),
                  _input(_emailController, "Email", validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Email cannot be empty";
                    if (!value.contains('@')) return "Enter a valid email";
                    return null;
                  }),
                  _input(_passwordController, "Password", obscure: true,
                      validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Password cannot be empty";
                    if (value.length < 6)
                      return "Password must be at least 6 characters";
                    return null;
                  }),
                  _input(_confirmController, "Confirm Password", obscure: true,
                      validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Please confirm your password";
                    if (value != _passwordController.text)
                      return "Passwords do not match";
                    return null;
                  }),

                  SizedBox(height: 10),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white, // or your app's accent color
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Role: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey.shade800)),
                        DropdownButton<String>(
                          value: _role,
                          underline: SizedBox(),
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.grey.shade800),
                          items: const [
                            DropdownMenuItem(
                                value: 'student', child: Text("Student")),
                            DropdownMenuItem(
                                value: 'teacher', child: Text("Teacher")),
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  if (_loading) CircularProgressIndicator(),
                  if (!_loading)
                    ElevatedButton(
                      onPressed: _signUp,
                      child: Text("Create Account"),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2.0, color: inputStroke),
              borderRadius: BorderRadius.circular(20),
            ),
            hintText: hint,
            hintStyle: TextStyle(color: hintText)),
      ),
    );
  }

  Future<void> initializeUserData(String userId) async {
    final profileRes = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    final role = profileRes?['role'] ?? 'student';
    final now = DateTime.now().toUtc().toIso8601String();

    if (role == "student") {
      final levelInfo = await Supabase.instance.client
          .from('user_current_story_progress')
          .select()
          .eq('user_id', userId);

      if (levelInfo.isEmpty) {
        print("inserting user_level_info row into supabase");
        await Supabase.instance.client.from('user_level_info').insert({
          'user_id': userId,
          'vocab_lvl': 1,
          'narrative_lvl': 1,
          'information_lvl': 1,
          'updated_at': now
        });
      }

      final money = await Supabase.instance.client
          .from('user_money')
          .select()
          .eq('user_id', userId);

      ///if user money doesnt exist, insert
      if (money.isEmpty) {
        print("inserting user_money row into supabase");
        await Supabase.instance.client.from('user_money').upsert(
          {'user_id': userId, 'money': 0, 'updated_at': now},
          onConflict: 'user_id',
        );
      }
      final exp = await Supabase.instance.client
          .from('user_exp')
          .select()
          .eq('user_id', userId);

      ///if user exp info doesnt exist, insert
      if (exp.isEmpty) {
        print("inserting user_exp row into supabase");
        await Supabase.instance.client.from('user_exp').insert({
          'user_id': userId,
          'narrative_exp': 100,
          'vocab_exp': 100,
          'information_exp': 100,
          'updated_at': now
        });
      }

      final settingsDiagnostic = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', userId);

      ///if user money doesnt exist, insert
      if (settingsDiagnostic.isEmpty) {
        await Supabase.instance.client.from('user_settings').insert(
            {'user_id': userId, 'diagnostic_completed': 0, 'updated_at': now});
      }
      final boosts = await Supabase.instance.client
          .from('user_boosts')
          .select()
          .eq('user_id', userId);
      if (boosts.isEmpty) {
        await Supabase.instance.client.from('user_boosts').upsert({
          'user_id': userId,
          'stories_remaining': 0,
          'updated_at': now,
        }, onConflict: 'user_id');
      }
    } else if (role == "teacher") {
      final teacherInfo = await Supabase.instance.client
          .from('teacher_classes')
          .select('id')
          .eq('id', userId);

      if (teacherInfo.isEmpty) {
        await Supabase.instance.client.from('teacher_classes').insert({
          'id': userId,
          'classes': [], // default empty list
        });
      }
    }
  }
}
