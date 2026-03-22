import 'package:basabuddy/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStagePage extends StatefulWidget {
  final String classId;
  const AddStagePage({super.key, required this.classId});

  @override
  State<AddStagePage> createState() => _AddStagePageState();
}

final List<String> allSkills = [
  // =========================
  // Vocabulary Skills
  // =========================
  'synonyms and antonyms',
  'verbs',
  'nouns',
  'pronouns',
  'adjectives',
  'content vocabulary',

  // =========================
  // Narrative Skills
  // =========================
  'story details',
  'sequencing events',
  'problem and solution',
  'characters feelings and traits',
  'cause and effect',
  'drawing conclusions',

  // =========================
  // Informational Skills
  // =========================
  'key details',
  'identify text types',
  'text structure',
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

  // Store fetched standalone questions
  Map<String, List<Map<String, dynamic>>> standaloneQuestions = {
    'mulcho': [],
    'ordering': [],
    'matching': [],
    'fill_in_blanks': [],
  };

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchStandaloneQuestions() async {
    setState(() => loadingStandalone = true);
    final supabase = Supabase.instance.client;

    try {
      // Fetch each type
      for (var type in ['mulcho_exercise','ordering_exercise','matching_exercise','fill_in_blank']) {
        final response = await supabase
            .from(type)
            .select()
            .eq('is_standalone', true);
        
        if (mounted) {
          switch(type){
            case 'mulcho_exercise':
              standaloneQuestions['mulcho'] = List<Map<String,dynamic>>.from(response);
              break;
            case 'ordering_exercise':
              standaloneQuestions['ordering'] = List<Map<String,dynamic>>.from(response);
              break;
            case 'matching_exercise':
              standaloneQuestions['matching'] = List<Map<String,dynamic>>.from(response);
              break;
            case 'fill_in_blank':
              standaloneQuestions['fill_in_blanks'] = List<Map<String,dynamic>>.from(response);
              break;
          }
        }
      }
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching questions: $e")));
    }

    setState(() => loadingStandalone = false);
  }

  void addStandaloneQuestionToStage(Map<String,dynamic> question, String type) {
    ExerciseInput exercise = ExerciseInput(type: type);

    if (question['skill'] != null) {
      exercise.skill = question['skill'];
    }

    switch(type){
      case 'mulcho':
        exercise.englishQuestionController.text = question['question'];
        exercise.tagalogQuestionController.text = (question['tagalog_question'] ?? '').replaceAll('\r', '').replaceAll('\n', '');
        exercise.choices = Map<String, TextEditingController>.fromEntries(
          (question['choices'] as Map).entries.map(
            (e) => MapEntry(e.key, TextEditingController(text: e.value))
          )
        );
        exercise.tagalogChoices = Map<String, TextEditingController>.fromEntries(
          (question['tagalog_choices'] as Map).entries.map(
            (e) => MapEntry(e.key, TextEditingController(text: e.value))
          )
        );
        exercise.correctMulchoIndex = (question['answer'] != null)
          ? (int.parse(question['answer'].toString())) - 1
          : null;
        break;

      case 'ordering':
        exercise.choices = Map<String, TextEditingController>.fromEntries(
          (question['data'] as Map).entries.map(
            (e) => MapEntry(e.key, TextEditingController(text: e.value))
          )
        );
        exercise.tagalogChoices = Map<String, TextEditingController>.fromEntries(
          (question['tagalog_data'] as Map).entries.map(
            (e) => MapEntry(e.key, TextEditingController(text: e.value))
          )
        );
        break;

      case 'matching':
        exercise.pairs = [];
        (question['pairs'] as Map).forEach((left, right){
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
        exercise.fillChoices = (question['choices'] as List).map((c) => TextEditingController(text: c)).toList();
        exercise.fillTagalogChoices = (question['tagalog_choices'] as List).map((c) => TextEditingController(text: c)).toList();
        exercise.correctFillBlanksIndex = (question['answer'] != null) 
            ? exercise.fillChoices.indexWhere((c) => c.text == question['answer'])
            : null;
        break;
    }

    setState(() => contentItems.add(exercise));
  }
  String capitalizeEachWord(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }
  Future<void> publishStage() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isPublishing = true);
  final supabase = Supabase.instance.client;

  try {
    // 1️⃣ Insert the stage
    final stageResponse = await supabase.from('list_stories').insert({
      'class_id': widget.classId,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'level': 1,
      'module': 'teachers_pick',
    }).select().single();

    final stageId = stageResponse['story_id'];

    int pageNumber = 0; // if you have pages

    // 2️⃣ Insert exercises one by one (or batch)
    for (var item in contentItems) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Stage published successfully!")),
    );

    Navigator.pop(context);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error publishing stage: $e")),
    );
  } finally {
    setState(() => isPublishing = false);
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

              // Stage Details
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Stage Title"),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Standalone Questions Section
              Row(
                children: [
                  const Text("Standalone Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: fetchStandaloneQuestions,
                    child: loadingStandalone ? const CircularProgressIndicator(color: Colors.white) : const Text("Load"),
                  )
                ],
              ),

              // Filters Row
              Row(
                children: [
                  Flexible(
                    child: DropdownButtonFormField<String>(
                      value: filterType,
                      isExpanded: true,
                      hint: const Text("Filter by Exercise Type"),
                      items: [null, ...exerciseTypes].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type == null ? "All Types" : capitalizeEachWord(type.replaceAll('_', ' '))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => filterType = val);
                      },
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
                      onChanged: (val) {
                        setState(() => filterSkill = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  filterType = null;
                  filterSkill = null;
                }),
                child: Text('Reset Filters'),
              ),

              const SizedBox(height: 10),

              ...standaloneQuestions.entries.expand((entry) {
                final type = entry.key;
                final questions = entry.value;

                // Filter by type and skill
                final filteredQuestions = questions.where((q) {
                  final matchesType = filterType == null || filterType == type;
                  final matchesSkill = filterSkill == null || (q['skill'] ?? '').toString() == filterSkill;
                  return matchesType && matchesSkill;
                }).toList();

                return filteredQuestions.map((q) => Card(
                  child: ListTile(
                    title: Text("${capitalizeEachWord(q['skill'] ?? '') ?? q['question'] ?? q['statement_1'] ?? 'Question'}"),
                    subtitle: Text(type.toUpperCase()),
                    trailing: ElevatedButton(
                      onPressed: () => addStandaloneQuestionToStage(q, type),
                      child: const Text("Add to Stage"),
                    ),
                  ),
                ));
              }).toList(),

              const SizedBox(height: 20),

              // Pages & Exercises (reuse your ReorderableListView)
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex,newIndex){
                  if(newIndex>oldIndex)newIndex--;
                  final item = contentItems.removeAt(oldIndex);
                  contentItems.insert(newIndex, item);
                  setState(() {});
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
                      onUpdate: () => setState((){}),
                    );
                  }
                  return SizedBox(key: ValueKey('placeholder_$index'));
                }).toList(),
              ),
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
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Publish Stage",
                            style: TextStyle(fontSize: 16),
                          ),
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

abstract class StoryContentItem {
  final String id;
  StoryContentItem() : id = UniqueKey().toString();
}


// =======================================================
// EXERCISE INPUT MODEL
// =======================================================
class MatchingPair {
  TextEditingController left;
  TextEditingController right;

  MatchingPair()
      : left = TextEditingController(),
        right = TextEditingController();
}

class ExerciseInput extends StoryContentItem {
  final String type;
  int afterPage = 1;
  String skill = '';
  int _choiceCounter = 3;

  int? correctMulchoIndex;
  int? correctFillBlanksIndex;
  String selectedSkill = 'synonyms and antonyms';
  final List<String> skills = [
    // Vocabulary skills
    'sight words',
    'word patterns',
    'word functions',
    'synonyms antonyms',
    'word roots',
    'content vocabulary',

    // Narrative comprehension skills
    'story elements',
    'sequence',
    'problem solution',
    'character traits',
    'cause effect',
    'prediction',
    'summary',

    // Informational text skills
    'key details',
    'text structure',
    'discourse markers',
    'drawing conclusions',
  ];
  

  final TextEditingController englishQuestionController = TextEditingController();
  final TextEditingController tagalogQuestionController = TextEditingController();
  final TextEditingController statement1Controller = TextEditingController();
  final TextEditingController statement2Controller = TextEditingController();
  final TextEditingController statement1TagalogController = TextEditingController();
  final TextEditingController statement2TagalogController = TextEditingController();

  final ValueNotifier<bool> isEnglish = ValueNotifier(true);

  Map<String, TextEditingController> choices = {};
  Map<String, TextEditingController> tagalogChoices = {};
  List<TextEditingController> fillChoices = [];
  List<TextEditingController> fillTagalogChoices = [];
  List<MatchingPair> pairs = [];

  ExerciseInput({required this.type}) {
    if (type == 'mulcho' || type =='ordering'){
      choices['1'] = TextEditingController();
      choices['2'] = TextEditingController();
      choices['3'] = TextEditingController();
      tagalogChoices['1'] = TextEditingController();
      tagalogChoices['2'] = TextEditingController();
      tagalogChoices['3'] = TextEditingController();
    }
    if (type == 'fill_in_blanks') {
      fillChoices = [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
      fillTagalogChoices = [
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
    }
    if (type == 'matching'){
      for (int i = 0; i < 3; i++) {
        pairs.add(MatchingPair());
      }
    }
  }

  Map<String, dynamic> extraData() {
    final Map<String, dynamic> data = {};
    if(type == 'mulcho'){
      final Map<String, String> englishJsonChoices = {};
      final Map<String, String> tagalogJsonChoices = {};
      choices.forEach((key,controller) {
        englishJsonChoices[key] = controller.text;
      });
      tagalogChoices.forEach((key,controller) {
        tagalogJsonChoices[key] = controller.text;
      });
      data['question'] = englishQuestionController.text;
      data['tagalog_question'] = tagalogQuestionController.text;
      data['choices'] = englishJsonChoices;
      data['tagalog_choices'] = tagalogJsonChoices;
      data['answer'] = correctMulchoIndex != null ?(correctMulchoIndex! + 1) : null;
    }
    if(type == 'ordering'){
      final Map<String, String> englishJsonChoices = {};
      final Map<String, String> tagalogJsonChoices = {};
      choices.forEach((key,controller) {
        englishJsonChoices[key] = controller.text;
      });
      tagalogChoices.forEach((key,controller) {
        tagalogJsonChoices[key] = controller.text;
      });
      data['data'] = englishJsonChoices;
      data['tagalog_data'] = tagalogJsonChoices;
    }
    if(type == 'matching'){
      final Map<String, String> jsonPairs = {};
      for (var pair in pairs) {
        final leftText = pair.left.text.trim();
        final rightText = pair.right.text.trim();

        if (leftText.isNotEmpty && rightText.isNotEmpty ) {
          jsonPairs[leftText] = rightText;
        }
      }
      data['pairs'] = jsonPairs;
    }
    if(type == 'fill_in_blanks'){
      data['statement_1'] = statement1Controller.text;
      data['statement_2'] = statement2Controller.text;
      data['tagalog_statement_1'] = statement1TagalogController.text;
      data['tagalog_statement_2'] = statement2TagalogController.text;
      data['choices'] = fillChoices.map((c) => c.text).toList();
      data['tagalog_choices'] = fillTagalogChoices.map((c) => c.text).toList();
      data['answer'] = correctFillBlanksIndex != null ? fillChoices[correctFillBlanksIndex!].text : 'none';
      data['tagalog_answer'] = correctFillBlanksIndex != null ? fillTagalogChoices[correctFillBlanksIndex!].text : 'none';
    }
    return data;
  }

  void renumberChoices(correctKey, lan_choices) {
    final oldControllers = lan_choices.values.toList();
    lan_choices.clear();
    for (int i = 0; i < oldControllers.length; i++) {
      lan_choices[(i + 1).toString()] = oldControllers[i];
    }
    if (correctKey != null && !lan_choices.containsKey(correctKey)) {
      correctKey = null;
    }
  }

  

  Widget buildExerciseWidget(BuildContext context, {required Key key, required int index, required VoidCallback onDelete,required VoidCallback onUpdate}) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ValueListenableBuilder(
          valueListenable: isEnglish, 
          builder: (context, englishSelected, _) {
            final currentChoices = englishSelected ? choices : tagalogChoices;
            final currentFillChoices = englishSelected ? fillChoices : fillTagalogChoices;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        const SizedBox(width: 8),
                        Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                    
                  ],
                ),
                type != 'matching' ?
                  ToggleButtons(
                    isSelected: [englishSelected, !englishSelected],
                    borderRadius: BorderRadius.circular(10),
                    onPressed: (i) {
                      isEnglish.value = i == 0;
                    },
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text("English"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text("Tagalog"),
                      ),
                    ],
                  ) : SizedBox.shrink(),
                if(type == 'mulcho')...[
                  TextFormField(
                    key: ValueKey("${id}_${englishSelected ? 'en' : 'tl'}_question"),
                    maxLines: null, 
                    minLines: 2,    
                    controller: englishSelected ? englishQuestionController : tagalogQuestionController,
                    decoration:  InputDecoration(labelText: englishSelected ? "Question (English)" : "Tanong (Tagalog)"),
                  ),
                  FormField(
                    initialValue: correctMulchoIndex,
                    validator: (val) {
                      return correctMulchoIndex == null ? 'Please select the correct answer' : null;
                    },
                    builder: (state) {
                      return Column(children: [...currentChoices.entries.map((entry) {
                      final key = entry.key;
                      final controller = entry.value;
                      
                      return Row(
                      children: [
                        Radio<int>(
                          value: int.parse(key) - 1,
                          groupValue: correctMulchoIndex,
                          onChanged: (val) {
                            correctMulchoIndex = val;
                            onUpdate();
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(labelText: englishSelected ? 'Choice $key' : 'Pagpipilian $key'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            final removedIndex = int.parse(key) - 1;
                            if (correctMulchoIndex == removedIndex) {
                              correctMulchoIndex = null;
                            } else if (correctMulchoIndex != null &&
                                      correctMulchoIndex! > removedIndex) {
                              correctMulchoIndex = correctMulchoIndex! - 1;
                            }
                            choices.remove(key);
                            tagalogChoices.remove(key);
                            onUpdate();
                          },
                        ),
                        ],
                      );
                    }).toList(),
                  

                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          state.errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      ],
                    );
              
                    },
                  ),
                  
                  TextButton(
                    onPressed: () {
                      _choiceCounter++;
                      choices[_choiceCounter.toString()] = TextEditingController();
                      tagalogChoices[_choiceCounter.toString()] = TextEditingController();
                      onUpdate();
                    },
                    child: const Text('+ Add Choice'),
                  ),
                ],
                if(type == 'ordering')...[
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;

                      final englishValues = choices.values.toList();
                      final tagalogValues = tagalogChoices.values.toList();

                      final movedEnglish = englishValues.removeAt(oldIndex);
                      englishValues.insert(newIndex, movedEnglish);

                      final movedTagalog = tagalogValues.removeAt(oldIndex);
                      tagalogValues.insert(newIndex, movedTagalog);


                      choices
                        ..clear()
                        ..addEntries(
                          List.generate(
                            englishValues.length,
                            (i) => MapEntry((i + 1).toString(), englishValues[i]),
                          ),
                        );

                      tagalogChoices
                        ..clear()
                        ..addEntries(
                          List.generate(
                            tagalogValues.length,
                            (i) => MapEntry((i + 1).toString(), tagalogValues[i]),
                          ),
                        );

                      onUpdate();
                    },
                    children: [...currentChoices.entries.map((entry) {
                    final key = entry.key;
                    final controller = entry.value;
                    return Row(
                      key: ValueKey(key),
                      children: [
                      ReorderableDragStartListener(
                          index: int.parse(key) - 1,
                          child: const Icon(Icons.drag_handle),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(labelText: englishSelected ? 'Event $key' : 'Pangyayari $key'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          currentChoices.remove(key);
                          renumberChoices(null, currentChoices);
                          onUpdate();
                        },
                      ),
                      ],
                    );
                  })]),
                  TextButton(
                    onPressed: () {
                      currentChoices[(currentChoices.length + 1).toString()] = TextEditingController();
                      onUpdate();
                    },
                    child: const Text('+ Add Choice'),
                  ),
                ],
                if(type == 'matching')...[
                  Column(
                    children: [...pairs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pair = entry.value;
                    return Row(
                      children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: pair.left,
                          decoration: InputDecoration(labelText: 'Left ${index+1}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: pair.right,
                          decoration: InputDecoration(labelText: 'Right ${index+1}'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          final removed = pairs.removeAt(index);
                          removed.left.dispose();
                          removed.right.dispose();
                          onUpdate();
                        },
                      ),
                      ],
                    );
                  })]),
                  TextButton(
                    onPressed: () {
                      pairs.add(MatchingPair());
                      onUpdate();
                    },
                    child: const Text('+ Add Pair'),
                  ),
                ],
                if(type == 'fill_in_blanks')...[

                  TextFormField(
                    controller: englishSelected ? statement1Controller : statement1TagalogController,
                    decoration:  InputDecoration(
                      labelText: englishSelected ? "Sentence (before blank)" : "Pangungusap (bago blangko)",
                    ),
                  ),
                  

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: englishSelected ? statement2Controller : statement2TagalogController,
                    decoration:  InputDecoration(
                      labelText: englishSelected ? "Sentence (after blank)" : "Pangungusap (bago blangko)",
                    ),
                  ),
                  

                  FormField(
                    initialValue: correctFillBlanksIndex,
                    validator: (val) {
                      return correctFillBlanksIndex == null ? 'Please select the correct answer' : null;
                    },
                    builder: (state) {
                      return Column(children: [...List.generate(currentFillChoices.length, (i) {
                      return Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctFillBlanksIndex,
                          onChanged: (val) {
                            correctFillBlanksIndex = val;
                            onUpdate();
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: currentFillChoices[i],
                            decoration: InputDecoration(labelText: 'Choice ${i+1}'),
                            onChanged: (val) {
                              onUpdate();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            if (correctFillBlanksIndex == i) {
                              correctFillBlanksIndex = null;
                            } else if (correctFillBlanksIndex != null &&
                                      correctFillBlanksIndex! > i) {
                              correctFillBlanksIndex = correctFillBlanksIndex! - 1;
                            }
                            fillChoices.removeAt(i);
                            fillTagalogChoices.removeAt(i);
                            onUpdate();
                          },
                        ),
                        ],
                      );
                    }),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          state.errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      ],
                    );
              
                    },
                  ),
                  
                  TextButton(
                    onPressed: () {
                      fillChoices.add(TextEditingController());
                      fillTagalogChoices.add(TextEditingController());
                      onUpdate();
                    },
                    child: const Text('+ Add Choice'),
                  ),
                ],
                DropdownButtonFormField(
                  value: skill.isEmpty? null : skill,
                  items: skills.map((skill) {
                    return DropdownMenuItem(
                      value: skill,
                      child: Text(skill),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: "Skill", border: OutlineInputBorder(),),
                  onChanged: (val) {
                    if (val != null){
                      skill = val;
                      onUpdate();
                    }
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please select a skill' : null,
                ),
              ],
            );
          }
        )
      ),
    );
  }
}
