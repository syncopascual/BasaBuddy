import 'package:flutter/material.dart';

class StudentDataDialogBox extends StatelessWidget {
  final String name;
  final String storiesRead;
  final String accuracyRate;
  final String averageRetryRate;
  final List<Map<String, double>> strengths;
  final List<Map<String, double>> needsReview;

  const StudentDataDialogBox({
    super.key,
    required this.name,
    required this.storiesRead,
    required this.accuracyRate,
    required this.averageRetryRate,
    required this.strengths,
    required this.needsReview,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Name ───────────────────────────────────────────────
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ─── Stats ──────────────────────────────────────────────
            _statRow(
              label: 'Stories read this month:',
              value: storiesRead,
              valueColor: Colors.black,
            ),
            const SizedBox(height: 6),
            _statRow(
              label: 'Accuracy Rate(%):',
              value: accuracyRate,
              valueColor: Colors.green,
            ),

            const SizedBox(height: 6),
            _statRow(
              label: 'Average Retry Rate(%):',
              value: averageRetryRate,
              valueColor: Colors.red,
            ),

            const SizedBox(height: 20),

            // ─── Strengths ──────────────────────────────────────────
            const Text(
              'Strengths',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _skillWrap(
              skills: strengths,
              defaultColor: Colors.green.shade100,
            ),

            const SizedBox(height: 20),

            // ─── Needs Review ───────────────────────────────────────
            const Text(
              'Needs Review',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            _skillWrap(
              skills: needsReview,
              defaultColor: Colors.pink.shade100,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  Widget _statRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _skillWrap({
    required List<Map<String, double>> skills,
    required Color defaultColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skillMap) {
        final entry = skillMap.entries.first;

        return Chip(
          label: Text(
            '${entry.key} (${entry.value.toStringAsFixed(0)}%)',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: _chipColor(entry.key, defaultColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }).toList(),
    );
  }

  Color _chipColor(String skill, Color fallback) {
    if (skill == 'Verbs') {
      return Colors.pink.shade100;
    }
    if (skill == 'Possessive Pronouns') {
      return Colors.blue.shade100;
    }
    if (skill == 'Synonym-antonym') {
      return Colors.yellow.shade200;
    }
    if (skill == 'Story Elements') {
      return Colors.deepPurple.shade100;
    }
    if (skill == 'Ordering events') {
      return Colors.green.shade100;
    }
    return fallback;
  }
}