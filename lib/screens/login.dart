import 'package:basabuddy/screens/student/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
        context.go('/student/home');
      } else if (role == 'teacher'){
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
              child: Column(
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
                    ElevatedButton(
                      onPressed: _tryLogin, 
                      child: Text("Login")),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: (){
                        context.go('/signup');
                      },
                      child: Text("Sign Up")),
                  ]
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}