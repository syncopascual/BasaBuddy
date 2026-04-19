import 'package:basabuddy/screens/student/home.dart';
import 'package:basabuddy/screens/student/onboarding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:basabuddy/utils/offline_sync.dart';
import 'package:basabuddy/utils/database_helper.dart';

import '../colors.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  void _tryLogin() {
    if (_formKey.currentState!.validate()) {
      _logIn(); // only runs if all validators return null
    }
  }
  Future<void> _logIn() async {
    setState(() => _loading = true);
    
    try{
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed")),
        );
        return;
      }

      final data = await Supabase.instance.client.from('profiles').select('role').eq('id', user.id).single();
      final role = data['role'] as String;

      if (!mounted) return;
      if (role =='student') {
        try {
          print("role is student, syncing from supabase");
          await syncUserProgress();
        } catch (e)
        {
          print("Offline sync failed: $e");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Login Failed, Please Try Again'),
              )
          );

          context.go('/login');
        }

        print("DONE SYNC -> proceeding to whatever AHEFJKDHGEFHISDKJS");

        /// Check if the student has already taken diagnostic test from supabase
        final diagnosticInfo = await Supabase.instance.client
            .from('user_settings')
            .select('diagnostic_completed')
            .eq('user_id', user.id)
            .single();
        print("login 4");

        final isDiagnosticDone = diagnosticInfo["diagnostic_completed"];
        if (!mounted) return;
        print("isDiagnosticDone $isDiagnosticDone ${isDiagnosticDone.runtimeType}");

        if (isDiagnosticDone == 0) {
          print("Diagnostic NOT done");
          /// First time - show onboarding
          context.go('/onboarding');
        } else {
          print("Diagnostic done, skipping onboarding");
          /// Returning student - go home
          context.go('/student/home');
        }
      } else
        if (role == 'teacher'){
        context.go('/teacher/home');
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown role: $role")),
        );
      }
    } on AuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unexpected error: $e")),
    );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                padding: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3), // Shadow color with transparency
                      blurRadius: 0, // How soft the edges are
                      spreadRadius: 3, // How much the shadow expands
                      offset: const Offset(2, 2), // Shifts the shadow (right, down)
                    ),
                  ],
                  color: darkerAccent,
                  borderRadius: BorderRadius.all(Radius.circular(45)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    ///Email text field
                    ///Password text field
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

                    SizedBox(height: 20),

                    if (_loading) CircularProgressIndicator(),
                    if (!_loading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ///SIGN UP BUTTON
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: superDarkAccent),
                              onPressed: (){
                                context.go('/signup');
                              },
                              child: Text("Sign Up", style: TextStyle(color: superLightAccent),)),
                          SizedBox(height: 10),
                          ///LOGIN BUTTON
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: selected),
                              onPressed: _tryLogin,
                              child: Text("Login", style: TextStyle(color: textColor),) ),
                      ],
                      ),




                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}