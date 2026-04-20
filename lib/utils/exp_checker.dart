// Threshold map: exp needed to reach each level (level -> min exp required)
import 'package:basabuddy/models/userLevelInfo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/userExp.dart';
import 'database_helper.dart';

const Map<int, int> kLevelExpThresholds = {
  1: 100,
  2: 200,
  3: 300,
  4: 400,
  5: 500,
};

/// Returns the level a user should be at given their exp
int _expToLevel(int exp) {
  int level = 1;
  for (final entry in kLevelExpThresholds.entries) {
    if (exp >= entry.value) {
      level = entry.key;
    }
  }
  return level;
}

/// Checks if any modules have levelled up, updates the DB if so,
/// and returns a map indicating which modules levelled up.
/// e.g. {'narrative': true, 'vocab': false, 'information': false}
Future<Map<String, int>> checkAndApplyLevelUps() async {
  print("checkAndApplyLevelUps called");

  // 1. Query current exp
  final userId = Supabase.instance.client.auth.currentUser?.id;
  List<UserExp> expList = await DatabaseHelper.instance
      .queryWhere('user_exp', UserExp.fromJson, 'user_id = ?', [userId]);

  if (expList.isEmpty) {
    print("exp_checker: expList is empty! cancelling level updating");
    return {};
  }
  UserExp? expRow = expList[0];
  print("user_id $userId checkAndApplyLevelUps current exp: nar: ${expRow.narrativeExp} voc: ${expRow.vocabExp} inf: ${expRow.informationExp}");

  if (expRow == null) return {};

  final int narrativeExp = expRow.narrativeExp as int? ?? 0;
  final int vocabExp = expRow.vocabExp as int? ?? 0;
  final int informationExp = expRow.informationExp as int? ?? 0;

  // 2. Query current levels
  List<UserLevelInfo> userLevelInfoList = await DatabaseHelper.instance
      .queryWhere('user_level_info', UserLevelInfo.fromJson, 'user_id = ?', [userId]);
  UserLevelInfo? levelRow = userLevelInfoList[0];

  if (levelRow == null) return {};

  final int currentNarrativeLvl = levelRow.narrativeLevel as int? ?? 1;
  final int currentVocabLvl = levelRow.vocabLevel as int? ?? 1;
  final int currentInformationLvl = levelRow.informationLevel as int? ?? 1;

  // 3. Calculate new levels from exp
  final int newNarrativeLvl = _expToLevel(narrativeExp);
  final int newVocabLvl = _expToLevel(vocabExp);
  final int newInformationLvl = _expToLevel(informationExp);

  // 4. Determine which modules levelled up, storing the new level
  final Map<String, int> leveledUp = {
    if (newNarrativeLvl > currentNarrativeLvl) 'narrative': newNarrativeLvl,
    if (newVocabLvl > currentVocabLvl) 'vocab': newVocabLvl,
    if (newInformationLvl > currentInformationLvl) 'information': newInformationLvl,
  };

  print("checkAndApplyLevelUps: $leveledUp");

  // 5. If any levelled up, persist the new levels
  if (leveledUp.isNotEmpty) {
    print("checkAndApplyLevelUps: LEVEL UP! levels:");
    print("nar $newNarrativeLvl");
    print("voc $newVocabLvl");
    print("inf $newInformationLvl");

    final realdb = await DatabaseHelper.instance.db;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    await realdb.update(
      'user_level_info',
      {
        'narrative_lvl': newNarrativeLvl,
        'vocab_lvl': newVocabLvl,
        'information_lvl': newInformationLvl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  return leveledUp;
}