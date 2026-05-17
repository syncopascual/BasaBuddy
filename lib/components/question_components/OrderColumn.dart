import 'package:flutter/material.dart';
import 'package:basabuddy/components/VoiceService.dart';

class OrderColumn extends StatelessWidget {
  final ValueNotifier<List<String>> orderKeysNotifier;
  final Map<String, String> englishData;
  final Map<String, String> tagalogData;
  final bool isEnglish;

  const OrderColumn({
    super.key,
    required this.orderKeysNotifier,
    required this.englishData,
    required this.tagalogData,
    required this.isEnglish,
  });

  String _getText(String key) {
    return isEnglish ? englishData[key]! : tagalogData[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: orderKeysNotifier,
      builder: (context, keys, _) {
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;

            final updated = List<String>.from(keys);
            final movedKey = updated.removeAt(oldIndex);
            updated.insert(newIndex, movedKey);

            orderKeysNotifier.value = updated;
          },
          children: [
            for (final entry in keys.asMap().entries)
              _OrderTile(
                key: ValueKey(entry.value),
                index: entry.key,
                text: _getText(entry.value),
                isEnglish: isEnglish,
              ),
          ],
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String text;
  final int index;
  final VoiceService _voice = VoiceService();
  final bool isEnglish;

  _OrderTile({
    super.key,
    required this.text,
    required this.index,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      key: key,
      index: index,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_handle),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  _voice.speak(text, isEnglish);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}