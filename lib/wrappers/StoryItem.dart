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
  bool eq(StoryItem other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType && other.data.id == data.id);
  }
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

class DescriptionItem extends StoryItem {
  final DescriptionData data;
  DescriptionItem(this.data);
}

class DescriptionData {
  final String description;
  DescriptionData(this.description);

  String get skill => '';
  int get afterPage => -1;
  int get id => -1;
}
