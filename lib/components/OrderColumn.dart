import 'package:flutter/material.dart';

class OrderColumn extends StatelessWidget {
  final ValueNotifier<List<String>> orderNotifier;

  const OrderColumn({
    super.key,
    required this.orderNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: orderNotifier,
      builder: (context, items, _) {
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;

            final updated = List<String>.from(items);
            final item = updated.removeAt(oldIndex);
            updated.insert(newIndex, item);

            orderNotifier.value = updated;
          },
          children: [
            for (final item in items)
              _OrderTile(
                key: ValueKey(item),
                text: item,
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
