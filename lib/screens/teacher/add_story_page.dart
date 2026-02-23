import 'package:basabuddy/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStoryPage extends StatefulWidget {
  final String classId;
  const AddStoryPage({super.key, required this.classId});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String selectedModule = 'teachers_pick';
  int level = 1;

  List<StoryContentItem> contentItems = [];

  bool isPublishing = false;

  @override
  void initState() {
    super.initState();
    contentItems.add(StoryPageInput());
  }


  void addPage() {
    setState(() {
      contentItems.add(StoryPageInput());
    });
  }

  void addExercise(String type) {
    setState(() {
      contentItems.add(ExerciseInput(type: type));
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    for (var item in contentItems) {
      if (item is StoryPageInput) {
        item.textController.dispose();
      }
      if (item is ExerciseInput) {
        item.questionController.dispose();
      }
    }
    super.dispose();
  }

  void _onReorderContent(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = contentItems.removeAt(oldIndex);
      contentItems.insert(newIndex, item);

    });
  }
  

  Future<void> publishStory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isPublishing = true);

    final supabase = Supabase.instance.client;

    try {
      final storyResponse = await supabase
        .from('list_stories')
        .insert({
          'title': titleController.text,
          'description': descriptionController.text,
          'module': selectedModule,
          'level': level,
          'class_id': widget.classId,
        })
        .select()
        .single();

      final storyId = storyResponse['story_id'];

      int pageNumber = 0;

      for (var item in contentItems) {

        if (item is StoryPageInput){
          pageNumber++;
         
          await supabase.from('story_page').insert({
            'story_id': storyId, 
            'page_num': pageNumber,
            'text': item.textController.text,
          });
        }
        if (item is ExerciseInput) {
          if (item.type == 'mulcho') {
            final extra = item.extraData();
            await supabase.from('mulcho_exercise').insert({
            'story_id': storyId,
            'after_page': pageNumber,
            'skill': item.skill,
            'question': extra['question'], 
            'choices': extra['choices'], 
            'answer': extra['answer'], 
          });
          }
          if (item.type == 'ordering') {
            final extra = item.extraData();
            await supabase.from('ordering_exercise').insert({
            'story_id': storyId,
            'after_page': pageNumber,
            'skill': item.skill,
            'data': extra['data'], 
          });
          }
          if (item.type == 'matching') {
            final extra = item.extraData();
            await supabase.from('matching_exercise').insert({
            'story_id': storyId,
            'after_page': pageNumber,
            'skill': item.skill,
            'pairs': extra['pairs'], 
          });
          }
          if (item.type == 'fill_in_blanks') {
            final extra = item.extraData();
            await supabase.from('fill_in_blank').insert({
            'story_id': storyId,
            'after_page': pageNumber,
            'skill': item.skill,
            'statement_1': extra['statement_1'], 
            'statement_2': extra['statement_2'], 
            'choices': extra['choices'],
            'answer': extra['answer'],
          });
          }
        }
        
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Story published successfully!")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isPublishing = false);
  }

  @override
  Widget build(BuildContext context) {
    int pageCounter = 0;
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Story")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("Story Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Story Title"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // PAGES
              const Text("Pages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _onReorderContent,
                
                children: contentItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  if (item is StoryPageInput) {
                    pageCounter++;
                    return item.buildPageWidget(
                      context,
                      key: ValueKey(item.id),
                      index: index,
                      pageNumber: pageCounter,
                      onDelete: () {
                        setState(() => contentItems.removeAt(index));
                      },
                    );
                  }
                  if (item is ExerciseInput) {
                    return item.buildExerciseWidget(
                      context,
                      key: ValueKey(item.id),
                      index: index,
                      onDelete: () {
                        setState(() => contentItems.removeAt(index));
                      },
                      onUpdate: () => setState(() {}),
                    );
                  }
                  return const SizedBox();
                }).toList(),
              ),

              ElevatedButton(
                onPressed: addPage,
                child: const Text("+ Add Page"),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () => addExercise('mulcho'),
                    child: const Text("+ Multiple Choice"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => addExercise('ordering'),
                    child: const Text("+ Ordering"),
                  ),
                  ElevatedButton(
                    onPressed: () => addExercise('matching'),
                    child: const Text("+ Matching"),
                  ),
                  ElevatedButton(
                    onPressed: () => addExercise('fill_in_blanks'),
                    child: const Text("+ Fill in the Blanks"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // PUBLISH
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPublishing ? null : publishStory,
                  child: isPublishing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Publish Story"),
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
// PAGE INPUT MODEL
// =======================================================

class StoryPageInput extends StoryContentItem {
  final TextEditingController textController = TextEditingController();

  Widget buildPageWidget(BuildContext context, {required Key key, required int index, required int pageNumber, required VoidCallback onDelete,}) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children : [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    const SizedBox(width: 8),
                    Text("Page $pageNumber", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],),

                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
            ],),
            
            const SizedBox(width: 12),
            TextFormField(
              controller: textController,
              decoration: const InputDecoration(labelText: "Page Text"),
              maxLines: 4,
              validator: (value) => value!.isEmpty ? "Required" : null,
            ),
          ],
        ),
      ),
    );
  }
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

  String? correctMulchoKey;
  String? correctFillBlanksKey;
  String selectedSkill = 'synonyms and antonyms';
  final List<String> skills = ['synonyms and antonyms', 'story details'];

  final TextEditingController questionController = TextEditingController();
  final TextEditingController statement1Controller = TextEditingController();
  final TextEditingController statement2Controller = TextEditingController();

  Map<String, TextEditingController> choices = {};
  List<TextEditingController> fillChoices = [];
  List<MatchingPair> pairs = [];

  ExerciseInput({required this.type}) {
    if (type == 'mulcho' || type =='ordering'){
      choices['1'] = TextEditingController();
      choices['2'] = TextEditingController();
      choices['3'] = TextEditingController();
    }
    if (type == 'fill_in_blanks') {
      fillChoices = [
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
      final Map<String, String> jsonChoices = {};
      choices.forEach((key,controller) {
        jsonChoices[key] = controller.text;
      });
      data['question'] = questionController.text;
      data['choices'] = jsonChoices;
      data['answer'] = correctMulchoKey;
    }
    if(type == 'ordering'){
      final Map<String, String> jsonChoices = {};
      choices.forEach((key,controller) {
        jsonChoices[key] = controller.text;
      });
      data['data'] = jsonChoices;
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
      data['choices'] = fillChoices.map((c) => c.text).toList();;
      data['answer'] = correctFillBlanksKey;
    }
    return data;
  }

  void renumberChoices(correctKey) {
    final oldControllers = choices.values.toList();
    choices.clear();
    for (int i = 0; i < oldControllers.length; i++) {
      choices[(i + 1).toString()] = oldControllers[i];
    }
    if (correctKey != null && !choices.containsKey(correctKey)) {
      correctKey = null;
    }
  }

  Widget buildExerciseWidget(BuildContext context, {required Key key, required int index, required VoidCallback onDelete,required VoidCallback onUpdate}) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
            if(type == 'mulcho')...[
              TextFormField(
                controller: questionController,
                decoration: const InputDecoration(labelText: "Question"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              FormField(
                initialValue: correctMulchoKey,
                validator: (val) {
                  return correctMulchoKey == null ? 'Please select the correct answer' : null;
                },
                builder: (state) {
                  return Column(children: [...choices.entries.map((entry) {
                  final key = entry.key;
                  final controller = entry.value;
                  return Row(
                   children: [
                    Radio<String>(
                      value: key,
                      groupValue: correctMulchoKey,
                      onChanged: (val) {
                        correctMulchoKey = val;
                        onUpdate();
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(labelText: 'Choice $key'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        choices.remove(key);
                        renumberChoices(correctMulchoKey);
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
                  choices[(choices.length + 1).toString()] = TextEditingController();
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

                  final values = choices.values.toList();

                  final movedValue = values.removeAt(oldIndex);
                  values.insert(newIndex, movedValue);

                  choices
                    ..clear()
                    ..addEntries(
                      List.generate(
                        values.length,
                        (i) => MapEntry((i + 1).toString(), values[i]),
                      ),
                    );

                  onUpdate();
                },
                children: [...choices.entries.map((entry) {
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
                      decoration: InputDecoration(labelText: 'Event $key'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      choices.remove(key);
                      renumberChoices(null);
                      onUpdate();
                    },
                  ),
                  ],
                );
              })]),
              TextButton(
                onPressed: () {
                  choices[(choices.length + 1).toString()] = TextEditingController();
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
                controller: statement1Controller,
                decoration: const InputDecoration(
                  labelText: "Sentence (before blank)",
                ),
              ),
              

              const SizedBox(height: 8),

              TextFormField(
                controller: statement2Controller,
                decoration: const InputDecoration(
                  labelText: "Sentence (after blank)",
                ),
              ),
              

              FormField(
                initialValue: correctFillBlanksKey,
                validator: (val) {
                  return correctFillBlanksKey == null ? 'Please select the correct answer' : null;
                },
                builder: (state) {
                  return Column(children: [...List.generate(fillChoices.length, (i) {
                  final choiceText = fillChoices[i].text;
                  return Row(
                   children: [
                    Radio<String>(
                      value: choiceText,
                      groupValue: correctFillBlanksKey,
                      onChanged: (val) {
                        correctFillBlanksKey = val;
                        onUpdate();
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: fillChoices[i],
                        decoration: InputDecoration(labelText: 'Choice ${i+1}'),
                        onChanged: (val) {
                        if (correctFillBlanksKey == choiceText) {
                          correctFillBlanksKey = val;
                        }
                        onUpdate();
                      },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        if (correctFillBlanksKey == choiceText) {
                          correctFillBlanksKey = null;
                        }
                        fillChoices.removeAt(i);
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
                  choices[(choices.length + 1).toString()] = TextEditingController();
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
        ),
      ),
    );
  }
}
