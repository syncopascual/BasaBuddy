import 'package:basabuddy/wrappers/ClassData.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../components/StudentDataDialogBox.dart';
import '../../models/student.dart';
import '../../wrappers/StudentData.dart';

class ClassContentItem {
  final String id;
  final String title;
  final bool isStory;
  final int pageCount;
  final int exerciseCount;

  const ClassContentItem({
    required this.id,
    required this.title,
    required this.isStory,
    required this.pageCount,
    required this.exerciseCount,
  });

  String get subtitle => isStory
      ? '$pageCount page${pageCount != 1 ? 's' : ''} · '
        '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''}'
      : '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''}';
}

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

  final className = classNameCode[0]["name"] as String;
  final classCode =  classNameCode[0]["class_code"] as String;

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

Future<List<ClassContentItem>> fetchClassContent(String classId) async {
  final response = await Supabase.instance.client
      .from('list_stories')
      .select('''
        story_id,
        title,
        story_page (count),
        mulcho_exercise (count),
        ordering_exercise (count),
        matching_exercise (count),
        fill_in_blank (count)
      ''')
      .eq('class_id', classId)
      .eq('module', 'teachers_pick');

  int _count(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      final first = raw[0];
      if (first is Map && first.containsKey('count')) {
        return (first['count'] as int?) ?? 0;
      }
      return raw.length;
    }
    return 0;
  }

  return (response as List).map((item) {
    final pageCount     = _count(item['story_page']);
    final exerciseCount = _count(item['mulcho_exercise']) +
                          _count(item['ordering_exercise']) +
                          _count(item['matching_exercise']) +
                          _count(item['fill_in_blank']);

    return ClassContentItem(
      id:            item['story_id'] as String,
      title:         item['title'] as String? ?? 'Untitled',
      isStory:       pageCount > 0,
      pageCount:     pageCount,
      exerciseCount: exerciseCount,
    );
  }).toList();
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

String formatRate(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return '--';
  return '${(value * 100).toStringAsFixed(0)}%';
}

String formatRetryRate(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return '--';
  return '${value.toStringAsFixed(1)}×';
}

int getTotalStoriesRead(List<Map<String, dynamic>> response){
  ///get total stories read:
  final uniqueReads = <String>{};

  for (final row in response) {
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
  double firstAttemptCorrectRate = sumOfData["total_items"]! == 0 ? double.nan : sumOfData["first_attempt_correct"]! / sumOfData["total_items"]!;
  double averageRetryRate = (sumOfData["total_items"]! - sumOfData["first_attempt_correct"]!) == 0 ? double.nan : (sumOfData["total_attempts"]! - sumOfData["total_items"]!)/ (sumOfData["total_items"]! - sumOfData["first_attempt_correct"]!);


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

const List<_AvatarTheme> _avatarThemes = [
  _AvatarTheme(bg: Color(0xFFB5D4F4), text: Color(0xFF0C447C)),
  _AvatarTheme(bg: Color(0xFF9FE1CB), text: Color(0xFF085041)),
  _AvatarTheme(bg: Color(0xFFF4C0D1), text: Color(0xFF72243E)),
  _AvatarTheme(bg: Color(0xFFCECBF6), text: Color(0xFF3C3489)),
  _AvatarTheme(bg: Color(0xFFFAC775), text: Color(0xFF633806)),
];

class _AvatarTheme {
  final Color bg;
  final Color text;
  const _AvatarTheme({required this.bg, required this.text});
}

_AvatarTheme _themeForName(String name) {
  final index = name.isNotEmpty ? name.codeUnitAt(0) % _avatarThemes.length : 0;
  return _avatarThemes[index];
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
  return '?';
}

class ClassPage extends StatelessWidget {
  final String classId;



  const ClassPage({
    super.key,
    required this.classId
  });



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClassData>(
      future: fetchClassInfo(classId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final data = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(data),
          body: _ClassPageBody(classId: classId, data: data),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ClassData data) {
    return AppBar(
      backgroundColor: const Color(0xFF1D9E75),
      foregroundColor: const Color(0xFFE1F5EE),
      elevation: 0,
      title: Row(
        children: [
          Expanded(
            child: Text(
              data.className,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE1F5EE),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Code: ${data.classCode}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9FE1CB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPageBody extends StatefulWidget {
  final String classId;
  final ClassData data;

  const _ClassPageBody({required this.classId, required this.data});

  @override
  State<_ClassPageBody> createState() => _ClassPageBodyState();
}

class _ClassPageBodyState extends State<_ClassPageBody> {
  // Tracks which student row is currently loading
  String? _loadingStudentId;

  Future<List<ClassContentItem>>? _contentFuture;

  @override
  void initState() {
    super.initState();
  }

  void _refreshContent() {
  setState(() {
    _contentFuture = fetchClassContent(widget.classId);
  });
}

  Future<void> _onStudentTap(Student student) async {
    setState(() => _loadingStudentId = student.studentId);

    try {
      final studentData = await fetchStudentInfo(student.studentId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => StudentDataDialogBox(
          name: studentData.studentName,
          storiesRead: studentData.storiesRead.toString(),
          accuracyRate: formatRate(studentData.firstAttemptCorrect),
          averageRetryRate: formatRetryRate(studentData.averageRetries),
          strengths: studentData.topSkills
              .map((m) => {m.keys.first: (m.values.first * 100)})
              .toList(),
          needsReview: studentData.worstSkills
              .map((m) => {m.keys.first: (m.values.first * 100)})
              .toList(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load student data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingStudentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricGrid(data),
        const SizedBox(height: 12),
        _buildSkillsCard(data),
        const SizedBox(height: 12),
        _buildActionButtons(context),
        const SizedBox(height: 20),
        _buildContentSection(),
        const SizedBox(height: 20),
        _buildStudentListHeader(data),
        const SizedBox(height: 8),
        ...data.students.map((s) => _buildStudentRow(s)),
      ],
    );
  }

  Widget _buildContentSection() {
    return FutureBuilder<List<ClassContentItem>>(
      future: _contentFuture ??= fetchClassContent(widget.classId),
      builder: (context, snapshot) {
        // Header always shows — even while loading
        final itemCount = snapshot.data?.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Class content',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (itemCount != null)
                  Text('$itemCount item${itemCount != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Could not load content: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              )
            else if (snapshot.data!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No content added yet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              )
            else
              ...snapshot.data!.map((item) => _buildContentCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildContentCard(ClassContentItem item) {
    // Stories → blue, Stages → purple
    final Color badgeBg   = item.isStory ? const Color(0xFFE6F1FB) : const Color(0xFFEEEDFE);
    final Color badgeIcon = item.isStory ? const Color(0xFF185FA5) : const Color(0xFF534AB7);
    final Color pillBg    = item.isStory ? const Color(0xFFE6F1FB) : const Color(0xFFEEEDFE);
    final Color pillText  = item.isStory ? const Color(0xFF0C447C) : const Color(0xFF3C3489);
    final String pillLabel = item.isStory ? 'Story' : 'Stage';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push('/teacher/content_detail', extra: {'storyId': item.id, 'isStory': item.isStory});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: item.isStory
                        ? _storyIcon(badgeIcon)
                        : _stageIcon(badgeIcon),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(item.subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Type pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(pillLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: pillText)),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Story icon: lined page
  Widget _storyIcon(Color color) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _StoryIconPainter(color),
    );
  }

  // Stage icon: list rows
  Widget _stageIcon(Color color) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _StageIconPainter(color),
    );
  }

  // ── Metric grid ──────────────────────────────

  Widget _buildMetricGrid(ClassData data) {
    final accuracy = data.firstAttemptCorrect;
    final retries = data.averageRetries;

    final accuracyColor = (!accuracy.isNaN && accuracy >= 0.7)
        ? const Color(0xFF0F6E56)
        : const Color(0xFF854F0B);

    final retryColor = (!retries.isNaN && retries > 1.5)
        ? const Color(0xFF854F0B)
        : const Color(0xFF0F6E56);

    return Row(
      children: [
        Expanded(child: _metricTile('Stories read', '${data.storiesRead}', Colors.black87)),
        const SizedBox(width: 8),
        Expanded(child: _metricTile('Accuracy', formatRate(accuracy), accuracyColor)),
        const SizedBox(width: 8),
        Expanded(child: _metricTile('Avg retries', formatRetryRate(retries), retryColor)),
      ],
    );
  }

  Widget _metricTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFF5F4ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }

  // ── Skills card ──────────────────────────────

  Widget _buildSkillsCard(ClassData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skillSection('Needs focus', data.worstSkills,
              const Color(0xFFFBEAF0), const Color(0xFF72243E)),
          if (data.worstSkills.isNotEmpty && data.topSkills.isNotEmpty)
            const SizedBox(height: 12),
          _skillSection('Excelling in', data.topSkills,
              const Color(0xFFEAF3DE), const Color(0xFF27500A)),
        ],
      ),
    );
  }

  Widget _skillSection(
      String label, List<Map<String, double>> skills, Color bg, Color textColor) {
    if (skills.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.05,
                color: Colors.grey.shade800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((skillMap) {
            final entry = skillMap.entries.first;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(entry.key,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Action buttons ───────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: '+ Add story',
            bg: const Color(0xFFE1F5EE),
            textColor: const Color(0xFF085041),
            onTap: () async {
              await context.push('/teacher/add_story_page', extra: widget.classId);
              _refreshContent();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            label: '+ Add questions',
            bg: const Color(0xFFFAEEDA),
            textColor: const Color(0xFF633806),
            onTap: () async {
              await context.push('/teacher/add_questions_page', extra: widget.classId);
              _refreshContent();
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color bg,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
          ),
        ),
      ),
    );
  }

  // ── Student list ─────────────────────────────

  Widget _buildStudentListHeader(ClassData data) {
    return Text(
      'Students · ${data.students.length}',
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildStudentRow(Student student) {
    final theme = _themeForName(student.name);
    final initials = _initials(student.name);
    final isLoading = _loadingStudentId == student.studentId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isLoading ? null : () => _onStudentTap(student),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.bg,
                  child: Text(initials,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.text)),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Text(student.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                // Loading spinner or chevron
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryIconPainter extends CustomPainter {
  final Color color;
  _StoryIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Page outline
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 0, size.width - 2, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);

    // Lines
    canvas.drawLine(Offset(4, size.height * 0.35), Offset(size.width - 4, size.height * 0.35), paint);
    canvas.drawLine(Offset(4, size.height * 0.55), Offset(size.width - 4, size.height * 0.55), paint);
    canvas.drawLine(Offset(4, size.height * 0.75), Offset(size.width * 0.6,  size.height * 0.75), paint);
  }

  @override
  bool shouldRepaint(_StoryIconPainter old) => old.color != color;
}

class _StageIconPainter extends CustomPainter {
  final Color color;
  _StageIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rr = Radius.circular(2);
    final h = size.height;
    final w = size.width;

    // Three rows of decreasing width
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0,       w,       h * 0.25), rr), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.4, w,       h * 0.25), rr), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.8, w * 0.6, h * 0.25), rr), paint);
  }

  @override
  bool shouldRepaint(_StageIconPainter old) => old.color != color;
}