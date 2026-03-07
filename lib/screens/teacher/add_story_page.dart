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
        item.englishTextController.dispose();
        item.tagalogTextController.dispose();
      }
      if (item is ExerciseInput) {
        item.englishQuestionController.dispose();
        item.tagalogQuestionController.dispose();
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
    int pageNumber = 0;
    for (var item in contentItems) {
      if (item is StoryPageInput) {
        pageNumber++;
        if (item.englishTextController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("English text is required on page $pageNumber"),
            ),
          );
          return;
        }
      }
      if (item is ExerciseInput) {
        if (item.type == 'mulcho'){
          if (item.englishQuestionController.text.trim().isEmpty || (item.choices.values.any((c) => c.text.trim().isEmpty))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please fill in all English fields."),
              ),
            );
            return;
          } 
        }
        if (item.type == 'ordering'){
          if ((item.choices.values.any((c) => c.text.trim().isEmpty))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please fill in all English fields."),
              ),
            );
            return;
          } 
        }
        if (item.type == 'matching'){
          if (item.pairs.any((p) => p.left.text.trim().isEmpty || p.right.text.trim().isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please fill in all English fields."),
              ),
            );
            return;
          } 
        }
        if (item.type == 'fill_in_blanks'){
          if ((item.statement1Controller.text.trim().isEmpty && item.statement2Controller.text.trim().isEmpty) ||(item.fillChoices.any((c) => c.text.trim().isEmpty))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please fill in all English fields."),
              ),
            );
            return;
          } 
        }
      }
    }

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
            'text': item.englishTextController.text,
            'tagalog_text': item.tagalogTextController.text,
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
            'tagalog_question': extra['tagalog_question'],
            'choices': extra['choices'], 
            'tagalog_choices': extra['tagalog_choices'], 
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
            'tagalog_data': extra['tagalog_data'] 
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
            'tagalog_statement_1': extra['tagalog_statement_1'], 
            'tagalog_statement_2': extra['tagalog_statement_2'],  
            'choices': extra['choices'],
            'tagalog_choices': extra['tagalog_choices'],
            'answer': extra['answer'],
            'tagalog_answer': extra['tagalog_answer'],
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
  final TextEditingController englishTextController = TextEditingController();
  final TextEditingController tagalogTextController = TextEditingController();
  final ValueNotifier<bool> isEnglish = ValueNotifier(true);

  Widget buildPageWidget(BuildContext context, {required Key key, required int index, required int pageNumber, required VoidCallback onDelete,}) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ValueListenableBuilder(
          valueListenable: isEnglish, 
          builder: (context, englishSelected, _) {
            return Column(
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
                    ],
                    ),
                    Row(
                      children: [
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                            onPressed: onDelete,
                          ),
                      ]
                    )
                    
                ],),
                
                const SizedBox(width: 12),
                TextFormField(
                  key: ValueKey(englishSelected),
                  controller: englishSelected ? englishTextController : tagalogTextController,
                  decoration: InputDecoration(labelText: englishSelected ? "Page Text (English)" : "Kuwento (Tagalog)"),
                  maxLines: 4,
                  validator: (value) {
                    if (isEnglish.value && (value == null || value.trim().isEmpty)) {
                      return "English text is required";
                    }
                    return null;
                  },
                ),
              ],
            );
          }
        )
        
        
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
  int _choiceCounter = 3;

  int? correctMulchoIndex;
  int? correctFillBlanksIndex;
  String selectedSkill = 'synonyms and antonyms';
  final List<String> skills = ['synonyms and antonyms', 'story details'];

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
      data['answer'] = correctMulchoIndex != null ? englishJsonChoices[(correctMulchoIndex! + 1).toString()] : null;
      data['tagalog_answer'] = correctMulchoIndex != null ? tagalogJsonChoices[(correctMulchoIndex! + 1).toString()] : null;
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
                    key: ValueKey(englishSelected),
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
