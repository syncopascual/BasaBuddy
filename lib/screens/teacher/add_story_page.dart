import 'package:basabuddy/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStoryPage extends StatefulWidget {
  const AddStoryPage({super.key});

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

              Row(
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

class ExerciseInput extends StoryContentItem {
  final String type;
  int afterPage = 1;
  String skill = '';

  String? correctMulchoKey;
  String selectedSkill = 'synonyms and antonyms';
  final List<String> skills = ['synonyms and antonyms', 'story details'];

  final TextEditingController questionController = TextEditingController();

  Map<String, TextEditingController> choices = {};

  ExerciseInput({required this.type}) {
    if (type == 'mulcho' || type =='ordering'){
      choices['1'] = TextEditingController();
      choices['2'] = TextEditingController();
      choices['3'] = TextEditingController();
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
    return data;
  }

  void renumberChoices() {
    final oldControllers = choices.values.toList();
    choices.clear();
    for (int i = 0; i < oldControllers.length; i++) {
      choices[(i + 1).toString()] = oldControllers[i];
    }
    if (correctMulchoKey != null && !choices.containsKey(correctMulchoKey)) {
      correctMulchoKey = null;
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
                        renumberChoices();
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
                      renumberChoices();
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
