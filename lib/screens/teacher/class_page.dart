import 'package:basabuddy/wrappers/ClassData.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../components/StudentDataDialogBox.dart';
import '../../models/student.dart';
import '../../wrappers/StudentData.dart';

Future<ClassData> fetchClassInfo(String classId) async {
  ///Fetch list of students
  ///Join 'class_students' and 'profiles' tables to get names

  final response = await Supabase.instance.client
      .from('class_students')
      .select('''
          student_id,
          profiles:student_id (
            id,
            name
          )
        ''')
      .eq('class_id', classId);
  print(response);
  List<Student> students = [];
  try{
    students = (response as List)
        .map((e) => Student.fromSupabase(e))
        .toList();
  } catch(e) {
    print(e);
  }

  ///fetch class name and code
  final classNameCode = await Supabase.instance.client
      .from('classes')
      .select()
      .eq('id', classId);

  String className = classNameCode[0]["name"];
  String classCode =  classNameCode[0]["class_code"];

  var (firstAttemptCorrect, averageRetries, storiesRead, topSkills, worstSkills) = await calculateSummary(classId, 'class');

  print("fetchClassInfo: worst and best skills");
  print(worstSkills);
  print(topSkills);
  ClassData classData = ClassData(
      students,
      className,
      classCode,
      firstAttemptCorrect,
      averageRetries,
      storiesRead,
      topSkills,
      worstSkills
  );
  return classData;
}

Future<StudentData> fetchStudentInfo(String studentId) async {

  ///Fetch student name
  final response = await Supabase.instance.client
      .from('class_students')
      .select('''
          student_id,
          profiles:student_id (
            id,
            name
          )
        ''')
      .eq('student_id', studentId);

  final studentName = (response as List)
      .map((e) => Student.fromSupabase(e))
      .toList()[0].name;

  var (firstAttemptCorrect, averageRetries, storiesRead, topSkills, worstSkills) = await calculateSummary(studentId, 'student');

  StudentData studentData = StudentData(
      studentName,
      firstAttemptCorrect,
      averageRetries,
      storiesRead,
      topSkills,
      worstSkills
  );

  return studentData;
}


///returns firstAttemptCorrectRate, averageRetriesRate, storiesRead, top performing skills, and worst performing skills
/// param type is to determine whether the data to be fetched is for the whole class or for a single student
Future<(double, double, int, List<Map<String, double>>, List<Map<String, double>>)> calculateSummary(givenId, type) async{

  List<Map<String, dynamic>> response = [];

  ///fetch data depending on type
  if(type == 'student') {
    ///Get all rows of a student with all stage_level columns
    response = await Supabase.instance.client
        .from('stage_level')
        .select('''
      *,
      profiles!inner (
        *
      )
    ''')
        .eq('profiles.id', givenId);
  }
  else ///else if class id is given
    {
      ///Get all rows of students of the class joined with all stage_level columns
      response = await Supabase.instance.client
          .from('stage_level')
          .select('''
      *,
      profiles!inner (
        class_students!inner (
          class_id
        )
      )
    ''')
          .eq('profiles.class_students.class_id', givenId);
    }


  List<Map<String, dynamic>> classPerformance =  (response as List).cast<Map<String, dynamic>>();



  ///Get firstAttemptCorrect, averageRetry
  var (firstAttemptCorrectRate, averageRetryRate) = getRates(classPerformance);


  ///Get focus areas
  var (:topPerforming, :worstPerforming) =
  getFocusAndStrengthAreas(response);

  ///get total stories read
  int totalStoriesRead = getTotalStoriesRead(response);


  return (firstAttemptCorrectRate, averageRetryRate, totalStoriesRead, topPerforming, worstPerforming);

}

int getTotalStoriesRead(List<Map<String, dynamic>> response){
  ///get total stories read:
  final rows = response as List;

  final uniqueReads = <String>{};

  for (final row in rows) {
    final userId = row['user_id'];
    final storyId = row['story_id'];

    if (userId != null && storyId != null) {
      uniqueReads.add('$userId|$storyId');
    }
  }
  return uniqueReads.length;
}
///returns firstAttemptCorrectRate, averageRetryRate
(double, double) getRates(List rows){
  Map<String, double> sumOfData= {"first_attempt_correct":0,"total_attempts":0, "total_items":0};
  for(Map skillEntry in rows){

    ///first_attempt_correct
    final current = sumOfData["first_attempt_correct"] ?? 0;
    final increment = (skillEntry["first_attempt_correct"] as int?) ?? 0;

    sumOfData["first_attempt_correct"] = current + increment;

    ///total_items
    final current2 = sumOfData["total_items"] ?? 0;
    final increment2 = (skillEntry["total_items"] as int?) ?? 0;

    sumOfData["total_items"] = current2 + increment2;

    ///total_attempts
    final current3 = sumOfData["total_attempts"] ?? 0;
    final increment3 = (skillEntry["total_attempts"] as int?) ?? 0;

    sumOfData["total_attempts"] = current3 + increment3;
  }
  double firstAttemptCorrectRate = sumOfData["first_attempt_correct"]! / sumOfData["total_items"]!;
  double averageRetryRate = (sumOfData["total_attempts"]! - sumOfData["total_items"]!)/ (sumOfData["total_items"]! - sumOfData["first_attempt_correct"]!);


  return (firstAttemptCorrectRate, averageRetryRate);
}

({
List<Map<String, double>> topPerforming,
List<Map<String, double>> worstPerforming
}) getFocusAndStrengthAreas(
    List<Map<String, dynamic>> response, {
      double threshold = 0.7,
    })
{

  ///different skills summaries
  Map<String, Map<String, double>> perSkillSummaries = {};

  ///separate entries into different skills
  Map<String, List<Map<String, dynamic>>> rowsPerSkill = {};
  for(var entry in response){
    final skill = entry["skill"];
    if(rowsPerSkill[entry["skill"]] == null){
      perSkillSummaries[skill] = {};
      rowsPerSkill[skill] = [];
      rowsPerSkill[skill]?.add(entry);
    } else
    {
      rowsPerSkill[skill]?.add(entry);
    }

  }

  ///for each skill, get firstAttemptCorrectRates and averageRetryRates
  rowsPerSkill.forEach((skill, listEntry){
    var(firstAttemptCorrectRateSkill, averageRetryRateSkill) = getRates(listEntry);
    perSkillSummaries[skill]!["firstAttemptCorrect"] = firstAttemptCorrectRateSkill;
    perSkillSummaries[skill]!["averageRetryRate"] = averageRetryRateSkill;
  });
  if (perSkillSummaries.isEmpty) {
    return (topPerforming: [], worstPerforming: []);
  }

  // Convert map → list of (skill, score)
  final skills = perSkillSummaries.entries
      .where((e) => e.value.containsKey('firstAttemptCorrect'))
      .map((e) => (
  skill: e.key,
  score: e.value['firstAttemptCorrect']!,
  ))
      .toList();

  if (skills.length <= 3) {
    final top = <Map<String, double>>[];
    final worst = <Map<String, double>>[];

    for (final s in skills) {
      if (s.score >= threshold) {
        top.add({s.skill: s.score});
      } else {
        worst.add({s.skill: s.score});
      }
    }

    return (topPerforming: top, worstPerforming: worst);
  }

  // More than 3 skills → sort
  skills.sort((a, b) => b.score.compareTo(a.score));

  final topPerforming = skills
      .take(2)
      .map((s) => {s.skill: s.score})
      .toList();

  final worstPerforming = skills
      .reversed
      .take(2)
      .map((s) => {s.skill: s.score})
      .toList();

  return (
  topPerforming: topPerforming,
  worstPerforming: worstPerforming,
  );
}

class ClassPage extends StatelessWidget {
  final String classId;



  const ClassPage({
    super.key,
    required this.classId
  });



  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchClassInfo(classId),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          return Scaffold(
            appBar: AppBar(
              title: Text(snapshot.data!.className),
              backgroundColor: Colors.blueAccent,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Code: ${snapshot.data!.classCode}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Stories read this month: ${snapshot.data?.storiesRead}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 4),
                          Text('Accuracy Rate: ${snapshot.data?.firstAttemptCorrect}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 4),
                          Text('Average retry rate: ${snapshot.data?.averageRetries}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              )),


                          const SizedBox(height: 8),
                          Text('Needs focus:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          Wrap(
                            children: snapshot.data!.worstSkills.map((skillMap) {
                              final entry = skillMap.entries.first;
                              return Chip(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                label: Text('${entry.key}'),
                                backgroundColor: Colors.pink.shade100
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text('Excelling areas:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          Wrap(
                            children: snapshot.data!.topSkills.map((skillMap) {
                              final entry = skillMap.entries.first;
                              return Chip(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                label: Text('${entry.key}'),
                                backgroundColor: Colors.green.shade100,
                              );
                            }).toList(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                            onPressed: (){
                              context.push('/teacher/add_story_page', extra: classId);
                            },
                            child: Text("Add a New Story", style: TextStyle(color: Colors.black))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(209, 255, 193, 7)),
                            onPressed: (){
                              context.push('/teacher/add_questions_page', extra: classId);
                            },
                            child: Text("Add New Questions", style: TextStyle(color: Colors.black))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Student list
                  const Text(
                    'Student List',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.students.length,
                      itemBuilder: (context, index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: ()async {
                              ///Fetch student data
                              StudentData studentData = await fetchStudentInfo(snapshot.data!.students[index].studentId);
                              ///Display student data
                              showDialog(
                                context: context,
                                builder: (_) => StudentDataDialogBox(
                                  name: studentData.studentName,
                                  storiesRead: studentData.storiesRead.toString(),
                                  accuracyRate: studentData.firstAttemptCorrect.toString(),
                                  averageRetryRate: studentData.averageRetries.toString(),
                                  strengths: [
                                    {'Synonym-antonym': 92},
                                    {'Ordering events': 88},
                                    {'Story Elements': 85},
                                  ],
                                  needsReview: [
                                    {'Possessive Pronouns': 60},
                                    {'Verbs': 55},
                                  ],
                                ),
                              );
                            },
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(snapshot.data!.students[index].name),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        } else
        {
          return const Center(child:CircularProgressIndicator());
        }
      }
    );
  }
}
