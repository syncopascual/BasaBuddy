/// Calculates points earned when a student finishes a story.
///
/// [level]              — story level (1–5)
/// [totalItemCount]     — total number of exercise items across all skills
/// [firstAttemptCount]  — items answered correctly on the first attempt
/// [isFirstCompletion]  — true if the student has never finished this story before
int calculatePoints({
  required int level,
  required int totalItemCount,
  required int firstAttemptCount,
  required bool isFirstCompletion,
}) {
  print("calculating points, level $level, totalItemCt $totalItemCount, 1stAttemptCt $firstAttemptCount, is1stCompletion $isFirstCompletion");
  // Base points per level
  const basePoints = [0, 5, 8, 12, 17, 23]; // index 0 unused

  // Perfect score bonus per level
  const perfectBonus = [0, 3, 4, 5, 6, 8];

  // First completion bonus per level
  const firstTimeBonus = [0, 2, 3, 4, 5, 7];

  // Clamp level to valid range
  final l = level.clamp(1, 5);

  int points = basePoints[l];

  // Perfect score = every item correct on first attempt
  final isPerfect = totalItemCount > 0 && firstAttemptCount >= totalItemCount;
  if (isPerfect) points += perfectBonus[l];

  if (isFirstCompletion) points += firstTimeBonus[l];

  print('calculatePoints: level=$l base=${basePoints[l]} '
      'perfect=$isPerfect(+${isPerfect ? perfectBonus[l] : 0}) '
      'firstTime=$isFirstCompletion(+${isFirstCompletion ? firstTimeBonus[l] : 0}) '
      'total=$points');

  return points;
}