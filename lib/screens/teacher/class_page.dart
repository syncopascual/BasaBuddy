import 'package:flutter/material.dart';

class ClassPage extends StatelessWidget {
  final String className;
  final String year;
  final String classCode;

  // Sample data; you could pass real data instead
  final List<String> students;
  final int storiesRead;
  final double errorRate;
  final Map<String, int> focusAreas; // e.g., {'Verbs': 28, 'Ordering Events': 19}

  const ClassPage({
    super.key,
    required this.classCode,
    required this.className,
    required this.year,
    required this.students,
    required this.storiesRead,
    required this.errorRate,
    required this.focusAreas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(className),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Code: $classCode',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Stories read this month: $storiesRead',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Text('Error rate: ${errorRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: focusAreas.entries
                          .map((e) => Chip(
                                label: Text('${e.key} (${e.value}%)'),
                                backgroundColor: e.key == 'Verbs'
                                    ? Colors.pink.shade100
                                    : Colors.green.shade100,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Student list
            const Text(
              'Student List',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(students[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
