import 'package:basabuddy/models/student.dart';

class ClassData  {
  final String className;
  final String classCode;

  final List<Student> students;

  final double firstAttemptCorrect;
  final double averageRetries;
  final int storiesRead;
  final List<Map<String, double>> topSkills;
  final List<Map<String, double>> worstSkills;

  ClassData(
      this.students,
      this.className,
      this.classCode,
      this.firstAttemptCorrect,
      this.averageRetries,
      this.storiesRead,
      this.topSkills,
      this.worstSkills);
}