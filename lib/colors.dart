import 'dart:ui';

import 'package:flutter/material.dart';


Color selected =  const Color(0xFFFFD351);
Color mulchoChoice = const Color(0xFFFFEEBB);
Color darkerAccent = const Color(0xFFFEA940);
Color superDarkAccent = const Color(0xFFB76500);
Color superLightAccent = const Color(0xFFFFEFAF);
Color textColor = const Color(0xFF723B0F);

Map<String, Map<String, Color>> popupTheme = {
  'correct':{
    'bgColor': const Color(0xFFD4FF8A),
    'textColor':const Color(0xFF375933),
    'buttonColor': const Color(0xFF53A250),

  },
  'wrong':{
    'bgColor': const Color(0xFFF6C6C6),
    'textColor':const Color(0xFF6E352F),
    'buttonColor': const Color(0xFFA24F3A),
  }
};

Color finishPopupBg1 = const Color(0xFFF9FFA6);
Color finishPopupBg2 = const Color(0xFFFFD650);



///Home screen different modules button
Color vocabButton = const Color(0xFF71ad49);
Color informationButton = const Color(0xFFFFFFFF);
Color narrativeButton = const Color(0xFFFFD351);

Color loginButton = const Color(0xFF804589);
Color x2Coins =  const Color(0xFFFFE79D);
Color greenText =  const Color(0xFF5CA65F);
Color teacherAppBar = const Color(0xFFFFFFFF);


Color timer = const Color(0xFFB57AE4);
Color narrowButton = const Color(0xFFE4D5F0);
Color narrowButtonText = const Color(0xFF6C5483);
Color topBarText = const Color(0xFFBC9ACD);

///Home: rest mode colors
Color restStroke = const Color(0xFFC2CCFF);
Color restPause = const Color(0xFF545C83);
Color restSkip = const Color(0xFF8D9CC4);

//Insights Screen colors
Color selectedTabText = const Color(0xFF6C5483);
Color unselectedTabText = const Color(0xFFCFB3E5);
Color selectedTab = const Color(0xFFE4D5F0);


//for dialog box 'no' button
Color darkRed = const Color(0xFFA54848);

// for dialog box positive button
Color warmGreen = const Color(0xFF8AC76E);


//for level up level outline
Color warmYellow = const Color(0xFFFFE100);

//shop button color
Color shopButton = const Color(0xFFDCF5D0);
Color shopBg = Colors.white;//Color(0xFFFFFFEC);


//Add subject color
Color inputStroke = const Color(0xFFC3C3C3);
Color hintText = const Color(0xFFCECECE);

//Add subject color map
var subjectColors = {//index : [name, color]
  1: Colors.redAccent,
  2: Colors.orangeAccent,
  3: Colors.yellowAccent,
  4: Colors.greenAccent,
  5: Colors.blueAccent,
  6: Colors.purpleAccent,
};

var idx2Name = {
  1: 'taskRed0',
  2: 'taskOrange0',
  3: 'taskYellow0',
};

var boughtColors = {//each list is composed of the [main color, text color, time color]
  '1' : const Color(0xFFFFF3D3),
  '0' : const Color(0xFFFFFFFF),

};

var shopPalette = {
  'itemStroke': const Color(0xFFD6C672),
  'imgStroke': const Color(0xFFD7D7D7),
  'itemName': const Color(0xFF5A5A5A),
  'selectedStroke': const Color(0xFF83C86B),
  'selectedBg': const Color(0xFFE6F6D2),
};


///todo: there's gotta be a better way lol
var shopDialogPalette = {
  ///Text color
  'text-color': const Color(0xFF7D7D7D),


  ///Background + Stroke Color pairs
  '0': const Color(0xFFFFE8DB),
  '0-0': const Color(0xFFFFC291),

  '1': const Color(0xFFFEFFDB),
  '1-1': const Color(0xFFE4E258),

  '2': const Color(0xFFE2FFDB),
  '2-2': const Color(0xFFA3E571),

  '3': const Color(0xFFEFE2D6),
  '3-3': const Color(0xFFA3926D),

  '4': const Color(0xFFE7DBFF),
  '4-4': const Color(0xFFA690EF),

  '5': const Color(0xFFDBFFEF),
  '5-5': const Color(0xFF73CCB7),

  '6': const Color(0xFFE2E2E2),
  '6-6': const Color(0xFF898989),

  '7': const Color(0xFFFFDBF4),
  '7-7': const Color(0xFFE392D0),

  '8': const Color(0xFFDBECFF),
  '8-8': const Color(0xFF7395CC),


};


var wardrobePalette = {
  'equipButton': const Color(0xFF8AC76E),
  'equipText': Colors.white,
  'text': const Color(0xFF6C5483),
  'shopOutline' : const Color(0xFF7EB66A),
  'shopIcon' : const Color(0xFF277D3F),
  'leftContainer' : const Color(0xFFF5EDFF),
  'itemStroke' : const Color (0xFFD694FF),

};

//Icon colors
Color clockIcon = const Color(0xFFF2DBDB);
Color fireIcon = const Color(0xFFF2721C);
Color leavesIcon = const Color(0xFF6DC544);
Color profileIcon = const Color(0xFFE8A3A3);

Color pastelYellow = const Color(0xFFFFF599);


///NOT NEEDED
//Main Task Colors will be stored in a dictionary
Color taskRed0 = const Color(0xFFFFE7E7);
Color taskYellow0 = const Color(0xFFFFF9C5);
Color taskOrange0 = const Color(0xFFFFE1C5);

//Text color associated with main task color
Color textRed0 = const Color(0xFF835454);
Color textYellow0 = const Color(0xFF978E61);
Color textOrange0 = const Color(0xFF977161);

//Time text color associated with main task color
Color timeRed0 = const Color(0xFFC48D97);
Color timeYellow0 = const Color(0xFFC3C48D);
Color timeOrange0 = const Color(0xFFC4978D);

///the key here has to be the same as the one in subjectColors
Map<String, Color> taskColors = {//each list is composed of the [main color, text color, time color]
  'taskRed0' : const Color(0xFFFFE7E7),
  'taskYellow0' : const Color(0xFFFFF9C5),
  'taskOrange0' : const Color(0xFFFFE1C5),
  'taskGreen0' : const Color(0xFFD0FFC4),
  'taskBlue0' : const Color(0xFFD6F3FF),
  'taskIndigo0' : const Color(0xFFD5D4FF),
  'taskPurple0' : const Color(0xFFF0D8FF),
};

var colorKeys = taskColors.keys.toList(); /// List of names of task Colors




String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

///Color Functions
Color darkenColor(Color color, double lightnessAmount, double saturationAmount) {
  assert(lightnessAmount >= 0 && lightnessAmount <= 1, 'Lightness amount should be between 0 and 1');
  assert(saturationAmount >= 0 && saturationAmount <= 1, 'Saturation amount should be between 0 and 1');

  final hsl = HSLColor.fromColor(color);
  final adjustedHsl = hsl.withLightness((hsl.lightness - lightnessAmount).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation - saturationAmount).clamp(0.0, 1.0));


  //print("COLOR: darkenColor called!");
  //print('Original Color: ${colorToHex(color)}');
  //print('Darkened Color: ${colorToHex(adjustedHsl.toColor())}');
  return adjustedHsl.toColor();
}
Color lightenColor(Color color, double lightnessAmount, double saturationAmount) {
  assert(lightnessAmount >= 0 && lightnessAmount <= 1, 'Lightness amount should be between 0 and 1');
  assert(saturationAmount >= 0 && saturationAmount <= 1, 'Saturation amount should be between 0 and 1');

  final hsl = HSLColor.fromColor(color);
  final adjustedHsl = hsl.withLightness((hsl.lightness + lightnessAmount).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation + saturationAmount).clamp(0.0, 1.0));

  //print("COLOR: lighten Color called!");
  //print('Original Color: ${colorToHex(color)}');
  //print('Lightened Color: ${colorToHex(adjustedHsl.toColor())}');
  return adjustedHsl.toColor();
}