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

    try{
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

      context.go('/login');
    } catch (e) {
      _showError(e.toString());
    }
    setState(() => _loading = false);
  } 

  void _showError(String msg){
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
                          )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  ///Email text field
                  _input(_nameController, "Full Name"),
                  _input(_emailController, "Email", validator: (value) {
                    if (value == null || value.isEmpty) return "Email cannot be empty";
                    if (!value.contains('@')) return "Enter a valid email";
                    return null;
                  }),
                  _input(_passwordController, "Password", obscure: true, validator: (value) {
                  if (value == null || value.isEmpty) return "Password cannot be empty";
                  if (value.length < 6) return "Password must be at least 6 characters";
                  return null;
                }),
                  _input(_confirmController, "Confirm Password", obscure: true, validator: (value) {
                  if (value == null || value.isEmpty) return "Please confirm your password";
                  if (value != _passwordController.text) return "Passwords do not match";
                  return null;
                }),

                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Role: "),
                      DropdownButton<String>(
                        value: _role,
                        items: const[
                          DropdownMenuItem(value: 'student', child: Text("Student")),
                          DropdownMenuItem(value: 'teacher', child: Text("Teacher")),
                        ], 
                        onChanged: (v) => setState(()=>_role = v!),
                        ),
                    ],
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

  Widget _input(TextEditingController controller, String hint, {bool obscure = false, String? Function(String?)? validator}) {
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
          hintStyle: TextStyle(color: hintText)
        ),
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

  if(role == "student"){
    final levelInfo = await Supabase.instance.client
      .from('user_current_story_progress')
      .select()
      .eq('user_id', userId);

    if(levelInfo.isEmpty){
      await Supabase.instance.client
          .from('user_level_info')
          .insert({
            'user_id': userId,
            'vocab_lvl': 1,
            'narrative_lvl': 1,
            'information_lvl': 1,
          }
          );
    }
    final money = await Supabase.instance.client
      .from('user_money')
      .select()
      .eq('user_id', userId);

  ///if user money doesnt exist, insert
    if(money.isEmpty){
      await Supabase.instance.client
          .from('user_money')
          .insert({
            'user_id': userId, 
            'money': 0,
      });
    }
  } else if(role == "teacher"){
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