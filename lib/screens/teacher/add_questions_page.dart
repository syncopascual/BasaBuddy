import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exercise_models.dart'; // ← shared models

class AddStagePage extends StatefulWidget {
  final String classId;
  const AddStagePage({super.key, required this.classId});

  @override
  State<AddStagePage> createState() => _AddStagePageState();
}

// Skills available for filtering standalone questions
const List<String> allSkills = [
  // Vocabulary
  'synonyms and antonyms', 'verbs', 'nouns', 'pronouns',
  'adjectives', 'content vocabulary',
  // Narrative
  'story details', 'sequencing events', 'problem and solution',
  'characters feelings and traits', 'cause and effect', 'drawing conclusions',
  // Informational
  'key details', 'identify text types', 'text structure',
];

class _AddStagePageState extends State<AddStagePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<StoryContentItem> contentItems = [];
  bool isPublishing = false;
  bool loadingStandalone = false;

  String? filterSkill;
  String? filterType;
  final List<String> exerciseTypes = ['mulcho', 'ordering', 'matching', 'fill_in_blanks'];

  Map<String, List<Map<String, dynamic>>> standaloneQuestions = {
    'mulcho': [],
    'ordering': [],
    'matching': [],
    'fill_in_blanks': [],
  };

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    for (final item in contentItems) {
      if (item is ExerciseInput) item.dispose();
    }
    super.dispose();
  }

  Future<void> fetchStandaloneQuestions() async {
    setState(() => loadingStandalone = true);
    final supabase = Supabase.instance.client;

    try {
      final typeMap = {
        'mulcho_exercise': 'mulcho',
        'ordering_exercise': 'ordering',
        'matching_exercise': 'matching',
        'fill_in_blank': 'fill_in_blanks',
      };

      for (final entry in typeMap.entries) {
        final response = await supabase
            .from(entry.key)
            .select()
            .eq('is_standalone', true);

        if (mounted) {
          standaloneQuestions[entry.value] =
              List<Map<String, dynamic>>.from(response);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching questions: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loadingStandalone = false);
    }
  }

  void addStandaloneQuestionToStage(Map<String, dynamic> question, String type) {
    final exercise = ExerciseInput(type: type);

    if (question['skill'] != null) exercise.skill = question['skill'];

    switch (type) {
      case 'mulcho':
        exercise.englishQuestionController.text = question['question'] ?? '';
        exercise.tagalogQuestionController.text =
            (question['tagalog_question'] ?? '').replaceAll('\r', '').replaceAll('\n', '');
        exercise.choices = Map<String, TextEditingController>.fromEntries(
          (question['choices'] as Map)
              .entries
              .map((e) => MapEntry(e.key, TextEditingController(text: e.value))),
        );
        exercise.tagalogChoices = Map<String, TextEditingController>.fromEntries(
          (question['tagalog_choices'] as Map)
              .entries
              .map((e) => MapEntry(e.key, TextEditingController(text: e.value))),
        );
        exercise.correctMulchoIndex = question['answer'] != null
            ? int.parse(question['answer'].toString()) - 1
            : null;
        break;

      case 'ordering':
        exercise.choices = Map<String, TextEditingController>.fromEntries(
          (question['data'] as Map)
              .entries
              .map((e) => MapEntry(e.key, TextEditingController(text: e.value))),
        );
        exercise.tagalogChoices = Map<String, TextEditingController>.fromEntries(
          (question['tagalog_data'] as Map)
              .entries
              .map((e) => MapEntry(e.key, TextEditingController(text: e.value))),
        );
        break;

      case 'matching':
        exercise.pairs = [];
        (question['pairs'] as Map).forEach((left, right) {
          final pair = MatchingPair();
          pair.left.text = left;
          pair.right.text = right;
          exercise.pairs.add(pair);
        });
        break;

      case 'fill_in_blanks':
        exercise.statement1Controller.text = question['statement_1'] ?? '';
        exercise.statement2Controller.text = question['statement_2'] ?? '';
        exercise.statement1TagalogController.text = question['tagalog_statement_1'] ?? '';
        exercise.statement2TagalogController.text = question['tagalog_statement_2'] ?? '';
        exercise.fillChoices =
            (question['choices'] as List).map((c) => TextEditingController(text: c)).toList();
        exercise.fillTagalogChoices =
            (question['tagalog_choices'] as List).map((c) => TextEditingController(text: c)).toList();
        exercise.correctFillBlanksIndex = question['answer'] != null
            ? exercise.fillChoices.indexWhere((c) => c.text == question['answer'])
            : null;
        break;
    }

    setState(() => contentItems.add(exercise));
  }

  String capitalizeEachWord(String input) => input
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
      .join(' ');

  Future<void> publishStage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isPublishing = true);
    final supabase = Supabase.instance.client;

    try {
      final stageResponse = await supabase.from('list_stories').insert({
        'class_id': widget.classId,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'level': 1,
        'module': 'teachers_pick',
      }).select().single();

      final stageId = stageResponse['story_id'];
      const int pageNumber = 0;

      for (final item in contentItems) {
        if (item is ExerciseInput) {
          final extra = item.extraData();
          switch (item.type) {
            case 'mulcho':
              await supabase.from('mulcho_exercise').insert({
                'story_id': stageId,
                'after_page': pageNumber,
                'skill': item.skill,
                'question': extra['question'],
                'tagalog_question': extra['tagalog_question'],
                'choices': extra['choices'],
                'tagalog_choices': extra['tagalog_choices'],
                'answer': extra['answer'],
              });
              break;
            case 'ordering':
              await supabase.from('ordering_exercise').insert({
                'story_id': stageId,
                'after_page': pageNumber,
                'skill': item.skill,
                'data': extra['data'],
                'tagalog_data': extra['tagalog_data'],
              });
              break;
            case 'matching':
              await supabase.from('matching_exercise').insert({
                'story_id': stageId,
                'after_page': pageNumber,
                'skill': item.skill,
                'pairs': extra['pairs'],
              });
              break;
            case 'fill_in_blanks':
              await supabase.from('fill_in_blank').insert({
                'story_id': stageId,
                'after_page': pageNumber,
                'skill': item.skill,
                'statement_1': extra['statement_1'],
                'statement_2': extra['statement_2'],
                'tagalog_statement_1': extra['tagalog_statement_1'],
                'tagalog_statement_2': extra['tagalog_statement_2'],
                'choices': extra['choices'],
                'tagalog_choices': extra['tagalog_choices'],
                'answer': extra['answer'],
                'tagalog_answer': extra['tagalog_answer'],
              });
              break;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stage published successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error publishing stage: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Stage")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stage title
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Stage Title"),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              Row(children: [
                const Text("Standalone Questions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: loadingStandalone ? null : fetchStandaloneQuestions,
                  child: loadingStandalone
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Load"),
                ),
              ]),

              const SizedBox(height: 12),

              // Filters
              Row(children: [
                Flexible(
                  child: DropdownButtonFormField<String>(
                    value: filterType,
                    isExpanded: true,
                    hint: const Text("Filter by Type"),
                    items: [null, ...exerciseTypes].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type == null
                            ? "All Types"
                            : capitalizeEachWord(type.replaceAll('_', ' '))),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => filterType = val),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: DropdownButtonFormField<String>(
                    value: filterSkill,
                    isExpanded: true,
                    hint: const Text("Filter by Skill"),
                    items: [null, ...allSkills].map((skill) {
                      return DropdownMenuItem(
                        value: skill,
                        child: Text(skill == null ? "All Skills" : capitalizeEachWord(skill)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => filterSkill = val),
                  ),
                ),
              ]),

              TextButton(
                onPressed: () => setState(() {
                  filterType = null;
                  filterSkill = null;
                }),
                child: const Text('Reset Filters'),
              ),

              ...standaloneQuestions.entries.expand((entry) {
                final type = entry.key;
                final questions = entry.value;

                return questions.where((q) {
                  final matchesType = filterType == null || filterType == type;
                  final matchesSkill = filterSkill == null ||
                      (q['skill'] ?? '').toString().toLowerCase() ==
                          filterSkill!.toLowerCase();
                  return matchesType && matchesSkill;
                }).map((q) => Card(
                      child: ListTile(
                        title: Text(capitalizeEachWord(
                            q['skill'] ?? q['question'] ?? q['statement_1'] ?? 'Question')),
                        subtitle: Text(type.toUpperCase()),
                        trailing: ElevatedButton(
                          onPressed: () => addStandaloneQuestionToStage(q, type),
                          child: const Text("Add to Stage"),
                        ),
                      ),
                    ));
              }),

              const SizedBox(height: 20),

              // Added exercises (reorderable)
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    contentItems.insert(newIndex, contentItems.removeAt(oldIndex));
                  });
                },
                children: contentItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  if (item is ExerciseInput) {
                    return item.buildExerciseWidget(
                      context,
                      key: ValueKey(item.id),
                      index: index,
                      onDelete: () => setState(() => contentItems.removeAt(index)),
                      onUpdate: () => setState(() {}),
                    );
                  }
                  return SizedBox(key: ValueKey('placeholder_$index'));
                }).toList(),
              ),

              // Publish button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isPublishing ? null : publishStage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isPublishing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Publish Stage",
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}