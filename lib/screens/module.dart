import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Module extends StatefulWidget {

  final String moduleType;
  const Module(this.moduleType, {super.key});

  @override
  State<Module> createState() => _ModuleState();
}

class _ModuleState extends State<Module> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/${widget.moduleType}.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(height:200),

        ],
      ),
    );
  }
}