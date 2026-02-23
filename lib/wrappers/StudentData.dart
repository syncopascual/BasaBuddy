
class StudentData  {
  final String studentName;
  final double firstAttemptCorrect;
  final double averageRetries;
  final int storiesRead;
  final List<Map<String, double>> topSkills;
  final List<Map<String, double>> worstSkills;

  StudentData(
      this.studentName,
      this.firstAttemptCorrect,
      this.averageRetries,
      this.storiesRead,
      this.topSkills,
      this.worstSkills);
}