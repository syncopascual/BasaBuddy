import 'package:flutter/material.dart';

import 'PopUp.dart';

void correctPopup(context, callBack, hint){
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Popup(
        title: "Correct!",
        description:
        hint,
        onPressed: () {
          // your callback logic here
          callBack();
        }, theme: 'correct',
      );
    },
  );
}

void wrongPopup(context, callBack, hint){
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Popup(
        title: "Almost!",
        description:
        hint,
        onPressed: () {
          // your callback logic here
          callBack();
        }, theme: 'wrong',
      );
    },
  );

}