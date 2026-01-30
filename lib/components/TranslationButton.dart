
import 'package:basabuddy/bloc/translation_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../colors.dart';


class TranslationButton extends StatefulWidget {
  final context;

  TranslationButton({required this.context});

  @override
  _TranslationButtonState createState() => _TranslationButtonState();
}

class _TranslationButtonState extends State<TranslationButton> {
  @override
  Widget build(BuildContext context) {

    return BlocBuilder<TranslationBloc, TranslationState>(builder: (_, state){
      String text = state.isEnglish? "Fil" : "Eng";
      return ElevatedButton(onPressed: (){
        BlocProvider.of<TranslationBloc>(widget.context).add(ToggleTranslation());
      }, child: Text(text));
    });
  }
}