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

  String _role = 'student';
  bool _loading = false;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmController.text) {
      _showError("Passwords do not match");
      return;
    }
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
            child: Column(
              children: [
                SizedBox(height: 40),
                ///Email text field
                _input(_nameController, "Full Name"),
                _input(_emailController, "Email"),
                _input(_passwordController, "Password", obscure: true),
                _input(_confirmController, "Confirm Password", obscure: true),

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
    );
  }

  Widget _input(TextEditingController controller, String hint, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
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
}