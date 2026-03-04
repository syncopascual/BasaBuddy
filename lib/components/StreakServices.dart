import 'package:supabase_flutter/supabase_flutter.dart';

class StreakService {
  final supabase = Supabase.instance.client;

  // Get current streak
  Future<int> getCurrentStreak(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('currentStreak')
        .eq('id', userId)
        .single();
    return response['currentStreak'] ?? 0;
  }

  // Update streak after completing a story
  Future<void> updateStreak(String userId) async {
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);

    final response = await supabase
        .from('profiles')
        .select('currentStreak, longestStreak, lastActiveDate')
        .eq('id', userId)
        .single();

    final currentStreak = response['currentStreak'] ?? 0;
    final longestStreak = response['longestStreak'] ?? 0;
    final lastActiveDate = response['lastActiveDate'];

    int newStreak;
    int newLongest = longestStreak;

    if (lastActiveDate == null) {
      newStreak = 1;
      newLongest = 1;
    } else {
      final lastDate = DateTime.parse(lastActiveDate).toUtc();
      final lastDateOnly =
          DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
      final difference = todayUtc.difference(lastDateOnly).inDays;

      if (difference == 0) return;
      newStreak = difference == 1 ? currentStreak + 1 : 1;
      if (newStreak > newLongest) newLongest = newStreak;
    }

    await supabase.from('profiles').update({
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastActiveDate': todayUtc.toIso8601String(),
    }).eq('id', userId);
  }
}