import 'package:basabuddy/screens/student/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
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
        child: Column(
          children: [
            Container(height: 200),
            ///Email text field
            TextField(
              maxLength: 20,
              //controller: nameController,
              decoration: InputDecoration(
                  fillColor: Colors.white, // Set the desired color
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 2.0,color: inputStroke),
                      borderRadius: const BorderRadius.all(Radius.circular(20))),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(width: 2.0,color: inputStroke),
                      borderRadius: const BorderRadius.all(Radius.circular(20))),
                  hintText: 'email',
                  hintStyle: TextStyle(color: hintText)
              ),
            ),
            ///Password text field
            TextField(
              maxLength: 20,

              //controller: nameController,
              decoration: InputDecoration(
                  fillColor: Colors.white, // Set the desired color
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(width: 2.0,color: inputStroke),
                      borderRadius: const BorderRadius.all(Radius.circular(20))),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(width: 2.0,color: inputStroke),
                      borderRadius: const BorderRadius.all(Radius.circular(20))),
                  hintText: 'password',
                  hintStyle: TextStyle(color: hintText)
              ),
            ),

            ///Login Button
            ElevatedButton(
                onPressed: (){
                  context.go('/student/home');
                },
                child: Text("Login")),
            ElevatedButton(
                onPressed: (){
                  context.go('/teacher/home');
                },
                child: Text("Teacher Login")),
            ElevatedButton(
                onPressed: (){
                  context.go('/signup');
                },
                child: Text("Sign Up")),
          ],
        ),
      ),
    );
  }
}