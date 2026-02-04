
import 'package:basabuddy/models/matchingData.dart';
import 'package:basabuddy/models/mulcho.dart';
import 'package:basabuddy/models/orderData.dart';
import 'package:basabuddy/models/storyPage.dart';

import '../models/fillBlankData.dart';


///Wrapper class for easier display in storyShell.dart
///So all components share the same base class, and can be bundled into a list
///
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

class OrderItem extends StoryItem {
  final OrderData data;

  OrderItem(this.data);

}

class FillBlankItem extends StoryItem {
  final FillBlankData data;

  FillBlankItem(this.data);

}
class MatchItem extends StoryItem {
  final MatchingData data;

  MatchItem(this.data);

}