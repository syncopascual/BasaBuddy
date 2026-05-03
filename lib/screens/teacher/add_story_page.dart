import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exercise_models.dart'; // ← shared models

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

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    for (final item in contentItems) {
      if (item is StoryPageInput) item.dispose();
      if (item is ExerciseInput) item.dispose();
    }
    super.dispose();
  }

  void addPage() => setState(() => contentItems.add(StoryPageInput()));

  void addExercise(String type) =>
      setState(() => contentItems.add(ExerciseInput(type: type)));

  void _onReorderContent(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      contentItems.insert(newIndex, contentItems.removeAt(oldIndex));
    });
  }

  Future<void> publishStory() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate page text and exercise fields before hitting Supabase
    int pageNumber = 0;
    for (final item in contentItems) {
      if (item is StoryPageInput) {
        pageNumber++;
        if (item.englishTextController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("English text is required on page $pageNumber")),
          );
          return;
        }
      }
      if (item is ExerciseInput) {
        String? error;
        if (item.type == 'mulcho' &&
            (item.englishQuestionController.text.trim().isEmpty ||
                item.choices.values.any((c) => c.text.trim().isEmpty))) {
          error = "Please fill in all fields for a multiple choice question.";
        } else if (item.type == 'ordering' &&
            item.choices.values.any((c) => c.text.trim().isEmpty)) {
          error = "Please fill in all ordering fields.";
        } else if (item.type == 'matching' &&
            item.pairs.any((p) =>
                p.left.text.trim().isEmpty || p.right.text.trim().isEmpty)) {
          error = "Please fill in all matching pairs.";
        } else if (item.type == 'fill_in_blanks' &&
            (item.statement1Controller.text.trim().isEmpty &&
                    item.statement2Controller.text.trim().isEmpty ||
                item.fillChoices.any((c) => c.text.trim().isEmpty))) {
          error = "Please fill in all fill-in-the-blank fields.";
        }
        if (error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
          return;
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
      int pageNum = 0;

      for (final item in contentItems) {
        if (item is StoryPageInput) {
          pageNum++;
          await supabase.from('story_page').insert({
            'story_id': storyId,
            'page_num': pageNum,
            'text': item.englishTextController.text,
            'tagalog_text': item.tagalogTextController.text,
          });
        }
        if (item is ExerciseInput) {
          final extra = item.extraData();
          switch (item.type) {
            case 'mulcho':
              await supabase.from('mulcho_exercise').insert({
                'story_id': storyId,
                'after_page': pageNum,
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
                'story_id': storyId,
                'after_page': pageNum,
                'skill': item.skill,
                'data': extra['data'],
                'tagalog_data': extra['tagalog_data'],
              });
              break;
            case 'matching':
              await supabase.from('matching_exercise').insert({
                'story_id': storyId,
                'after_page': pageNum,
                'skill': item.skill,
                'pairs': extra['pairs'],
              });
              break;
            case 'fill_in_blanks':
              await supabase.from('fill_in_blank').insert({
                'story_id': storyId,
                'after_page': pageNum,
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
          const SnackBar(content: Text("Story published successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Story")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Story Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 16),
              const Text("Reading Level",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(5, (i) {
                  final lvl = i + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text("Level $lvl"),
                      selected: level == lvl,
                      onSelected: (_) => setState(() => level = lvl),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const Text("Pages",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _onReorderContent,
                children: contentItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  // Compute page number inline — avoids the confusing outer counter
                  final pageNumber = contentItems
                      .take(index + 1)
                      .whereType<StoryPageInput>()
                      .length;

                  if (item is StoryPageInput) {
                    return item.buildPageWidget(
                      context,
                      key: ValueKey(item.id),
                      index: index,
                      pageNumber: pageNumber,
                      onDelete: () =>
                          setState(() => contentItems.removeAt(index)),
                    );
                  }
                  if (item is ExerciseInput) {
                    return item.buildExerciseWidget(
                      context,
                      key: ValueKey(item.id),
                      index: index,
                      onDelete: () =>
                          setState(() => contentItems.removeAt(index)),
                      onUpdate: () => setState(() {}),
                    );
                  }
                  return SizedBox(key: ValueKey('empty_$index'));
                }).toList(),
              ),
              ElevatedButton(
                  onPressed: addPage, child: const Text("+ Add Page")),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () => addExercise('mulcho'),
                    child: const Text("+ Multiple Choice"),
                  ),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPublishing ? null : publishStory,
                  child: isPublishing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
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

// =======================================================
// PAGE INPUT MODEL (story-specific, stays in this file)
// =======================================================
class StoryPageInput extends StoryContentItem {
  final TextEditingController englishTextController = TextEditingController();
  final TextEditingController tagalogTextController = TextEditingController();
  final ValueNotifier<bool> isEnglish = ValueNotifier(true);

  void dispose() {
    englishTextController.dispose();
    tagalogTextController.dispose();
    isEnglish.dispose();
  }

  Widget buildPageWidget(
    BuildContext context, {
    required Key key,
    required int index,
    required int pageNumber,
    required VoidCallback onDelete,
  }) {
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
                  children: [
                    Row(children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      const SizedBox(width: 8),
                      Text("Page $pageNumber",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    Row(children: [
                      ToggleButtons(
                        isSelected: [englishSelected, !englishSelected],
                        borderRadius: BorderRadius.circular(10),
                        onPressed: (i) => isEnglish.value = i == 0,
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text("English")),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text("Tagalog")),
                        ],
                      ),
                      IconButton(
                          icon: const Icon(Icons.delete), onPressed: onDelete),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey(
                      '${englishTextController.hashCode}_$englishSelected'),
                  controller: englishSelected
                      ? englishTextController
                      : tagalogTextController,
                  decoration: InputDecoration(
                    labelText: englishSelected
                        ? "Page Text (English)"
                        : "Kuwento (Tagalog)",
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (isEnglish.value &&
                        (value == null || value.trim().isEmpty)) {
                      return "English text is required";
                    }
                    return null;
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
