import 'package:flutter/material.dart';
import 'StreakServices.dart'; // your StreakService file
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakNotifier extends ValueNotifier<int> {
  StreakNotifier() : super(0);

  Future<void> refresh(String userId) async {
    final newStreak = await StreakService().getCurrentStreak(userId);
    value = newStreak;
  }
}

// This is a global instance you can import anywhere
final streakNotifier = StreakNotifier();