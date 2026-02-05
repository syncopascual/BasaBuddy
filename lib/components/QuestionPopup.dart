import 'package:flutter/material.dart';

import 'PopUp.dart';

void correctPopup(context, callBack){
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Popup(
        title: "Correct!",
        description:
        "",
        onPressed: () {
          // your callback logic here
          callBack();
        }, theme: 'correct',
      );
    },
  );
}

void wrongPopup(context, callBack){
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Popup(
        title: "Almost!",
        description:
        "Try again",
        onPressed: () {
          // your callback logic here
          callBack();
        }, theme: 'wrong',
      );
    },
  );

}