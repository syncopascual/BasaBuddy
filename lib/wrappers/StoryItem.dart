import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/models/storyPage.dart';


///Wrapper class for easier display in storyShell.dart
///So all components share the same base class
abstract class StoryItem {
  late final data;
}


class PageItem extends StoryItem {
  final Storypage data;

  PageItem(this.data);

}

class MulchoItem extends StoryItem {
  final Mulcho data;

  MulchoItem(this.data);

}