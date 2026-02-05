import 'package:flutter/material.dart';

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
    return isEnglish
        ? englishData[key]!
        : tagalogData[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: orderKeysNotifier,
      builder: (context, keys, _) {
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;

            final updated = List<String>.from(keys);
            final movedKey = updated.removeAt(oldIndex);
            updated.insert(newIndex, movedKey);

            orderKeysNotifier.value = updated;
          },
          children: [
            for (final key in keys)
              _OrderTile(
                key: ValueKey(key),
                text: _getText(key),
              ),
          ],
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String text;

  const _OrderTile({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
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
        ],
      ),
    );
  }
}
