import 'package:basabuddy/screens/student/module.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/connectivity_bloc.dart';
import '../../bloc/theme_bloc.dart';
import '../../colors.dart';

class StudentHome  extends StatefulWidget {
  @override
  State<StudentHome > createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome > {

  int index = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/bg_images/islands.png",
              fit: BoxFit.cover,
            ),),
          Positioned(
            top: 270,
            left: 170,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vocabButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                )),
              onPressed: (){
                BlocProvider.of<ThemeBloc>(context).add(SetVocab());
                context.push('/student/home/module/vocab');
              },
              child: Text("Vocab Island", style: TextStyle(color: textColor, fontFamily: 'Nunito'))),
          ),

          Positioned(
            top: 420,
            left: 180,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: informationButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                )),
              onPressed: (){
                BlocProvider.of<ThemeBloc>(context).add(SetInformation());
                context.push('/student/home/module/information');
              },
              child: Text("Knowledge Island", style: TextStyle(color: textColor, fontFamily: 'Nunito'))),
          ),

          Positioned(
            top: 550,
            left: 25,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                backgroundColor: narrativeButton,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                )),
                onPressed: (){
                  BlocProvider.of<ThemeBloc>(context).add(SetNarrative());
                  context.push('/student/home/module/narrative');
                },
                child: Text("Story Island", style: TextStyle(color: textColor, fontFamily: 'Nunito'))),
          ),

          /// Teachers' Pick Island Button — only shown when online
          BlocBuilder<ConnectivityBloc, ConnectivityState>(
            builder: (context, state) {
              final isOnline = state is ConnectivitySuccess && state.isConnected;
              if (!isOnline) return const SizedBox.shrink();
              return  Positioned(
                top: 320,
                left: -20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: teachersPickButton,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      )),
                  onPressed: () {
                    context.push('/student/home/module/teachers_pick');
                  },
                  child: Text("Teachers' Pick Island", style: TextStyle(color: textColor, fontFamily: 'Nunito')),
                ),
              );
            },
          ),


        ]
      ),
       );
  }
}