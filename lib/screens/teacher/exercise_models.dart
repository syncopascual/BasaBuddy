import 'package:flutter/material.dart';

abstract class StoryContentItem {
  final String id;
  StoryContentItem() : id = UniqueKey().toString();
}


class MatchingPair {
  TextEditingController left;
  TextEditingController right;

  MatchingPair()
      : left = TextEditingController(),
        right = TextEditingController();

  
  void dispose() {
    left.dispose();
    right.dispose();
  }
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
      for (var i = 1; i <= 3; i++) {
        choices['$i'] = TextEditingController();
        tagalogChoices['$i'] = TextEditingController();
      }
      if (type == 'mulcho') {
        correctMulchoIndex = 0;
      }
    }
    if (type == 'fill_in_blanks') {
      fillChoices = List.generate(3, (_) => TextEditingController());
      fillTagalogChoices = List.generate(3, (_) => TextEditingController());
      correctFillBlanksIndex = 0;
    }
    if (type == 'matching'){
      pairs = List.generate(3, (_) => MatchingPair());
    }
  }

  void dispose() {
    englishQuestionController.dispose();
    tagalogQuestionController.dispose();
    statement1Controller.dispose();
    statement2Controller.dispose();
    statement1TagalogController.dispose();
    statement2TagalogController.dispose();
    isEnglish.dispose();
    for (final c in choices.values) c.dispose();
    for (final c in tagalogChoices.values) c.dispose();
    for (final c in fillChoices) c.dispose();
    for (final c in fillTagalogChoices) c.dispose();
    for (final p in pairs) p.dispose();
  }

  Map<String, dynamic> extraData() {
    final Map<String, dynamic> data = {};
    if(type == 'mulcho'){
      data['question'] = englishQuestionController.text;
      data['tagalog_question'] = tagalogQuestionController.text;
      data['choices'] = {for (var e in choices.entries) e.key: e.value.text};
      data['tagalog_choices'] = {for (var e in tagalogChoices.entries) e.key: e.value.text};
      data['answer'] = correctMulchoIndex != null ? correctMulchoIndex! + 1 : null;
    }
    if(type == 'ordering'){
      data['data'] = {for (var e in choices.entries) e.key: e.value.text};
      data['tagalog_data'] = {for (var e in tagalogChoices.entries) e.key: e.value.text};
    }
    if(type == 'matching'){
      data['pairs'] = {
        for (var p in pairs)
          if (p.left.text.trim().isNotEmpty && p.right.text.trim().isNotEmpty)
            p.left.text.trim(): p.right.text.trim()
      };
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

  int? renumberChoices(Map<String, TextEditingController> target, int? correctIndex) {
    final controllers = target.values.toList();
    target.clear();
    for (int i = 0; i < controllers.length; i++) {
      target[(i + 1).toString()] = controllers[i];
    }
    // If the correct index is now out of range, clear it
    if (correctIndex != null && correctIndex >= controllers.length) {
      return null;
    }
    return correctIndex;
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
                    onPressed: (i) => isEnglish.value = i == 0,
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
                  FormField<int>(
                    validator: (_) => correctMulchoIndex == null ? 'Please select the correct answer' : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...currentChoices.entries.map((entry) {
                          final k = entry.key;
                          return Row(children: [
                            Radio<int>(
                              value: int.parse(k) - 1,
                              groupValue: correctMulchoIndex,
                              onChanged: (val) {
                                correctMulchoIndex = val;
                                onUpdate();
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: englishSelected ? 'Choice $k' : 'Pagpipilian $k',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                final removedIndex = int.parse(k) - 1;
                                if (correctMulchoIndex == removedIndex) {
                                  correctMulchoIndex = null;
                                } else if (correctMulchoIndex != null && correctMulchoIndex! > removedIndex) {
                                  correctMulchoIndex = correctMulchoIndex! - 1;
                                }
                                choices.remove(k);
                                tagalogChoices.remove(k);
                                correctMulchoIndex = renumberChoices(choices, correctMulchoIndex);
                                renumberChoices(tagalogChoices, null);
                                onUpdate();
                              },
                            ),
                          ]);
                        }),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(state.errorText!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
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

                      final enValues = choices.values.toList();
                      final tlValues = tagalogChoices.values.toList();
                      enValues.insert(newIndex, enValues.removeAt(oldIndex));
                      tlValues.insert(newIndex, tlValues.removeAt(oldIndex));

                     choices
                        ..clear()
                        ..addEntries(List.generate(enValues.length,
                            (i) => MapEntry((i + 1).toString(), enValues[i])));

                      tagalogChoices
                        ..clear()
                        ..addEntries(List.generate(tlValues.length,
                            (i) => MapEntry((i + 1).toString(), tlValues[i])));

                      onUpdate();
                    },
                    children: currentChoices.entries.map((entry) {
                      final k = entry.key;
                      return Row(
                        key: ValueKey('ordering_${id}_$k'),
                        children: [
                          ReorderableDragStartListener(
                            index: int.parse(k) - 1,
                            child: const Icon(Icons.drag_handle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: englishSelected ? 'Event $k' : 'Pangyayari $k',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              choices.remove(k);
                              tagalogChoices.remove(k);
                              renumberChoices(choices, null);
                              renumberChoices(tagalogChoices, null);
                              onUpdate();
                            },
                          ),
                        ],
                      );
                    }).toList(),
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
                if (type == 'matching') ...[
                  ...pairs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final pair = entry.value;
                    return Row(children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: pair.left,
                          decoration: InputDecoration(labelText: 'Left ${i + 1}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: pair.right,
                          decoration: InputDecoration(labelText: 'Right ${i + 1}'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          pairs.removeAt(i).dispose();
                          onUpdate();
                        },
                      ),
                    ]);
                  }),
                  TextButton(
                    onPressed: () {
                      pairs.add(MatchingPair());
                      onUpdate();
                    },
                    child: const Text('+ Add Pair'),
                  ),
                ],
                if (type == 'fill_in_blanks') ...[
                  TextFormField(
                    controller: englishSelected ? statement1Controller : statement1TagalogController,
                    decoration: InputDecoration(
                      labelText: englishSelected
                          ? "Sentence (before blank)"
                          : "Pangungusap (bago blangko)",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: englishSelected ? statement2Controller : statement2TagalogController,
                    decoration: InputDecoration(
                      labelText: englishSelected
                          ? "Sentence (after blank)"
                          : "Pangungusap (pagkatapos ng blangko)",
                    ),
                  ),
                  FormField<int>(
                    validator: (_) => correctFillBlanksIndex == null
                        ? 'Please select the correct answer'
                        : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(currentFillChoices.length, (i) {
                          return Row(children: [
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
                                decoration: InputDecoration(labelText: 'Choice ${i + 1}'),
                                onChanged: (_) => onUpdate(),
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
                          ]);
                        }),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(state.errorText!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
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
                  decoration: const InputDecoration(
                    labelText: "Skill",
                    border: OutlineInputBorder(),
                  ),
                  items: skills
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
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