import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'class_page.dart';
import '../../colors.dart';

class TeacherHome extends StatefulWidget {
  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final List<Map<String, String>> classes = const [
    {'name': '3- Ipil', 'year': 'AY 2024-2025', 'color': 'pink'},
    {'name': '3- Sampaguita', 'year': 'AY 2024-2025', 'color': 'green'},
    {'name': '3- Narra', 'year': 'AY 2024-2025', 'color': 'blue'},
    {'name': '3- Kamagong', 'year': 'AY 2024-2025', 'color': 'pink'},
    {'name': '3- Mahogany', 'year': 'AY 2024-2025', 'color': 'green'},
    {'name': '3- Mola', 'year': 'AY 2024-2025', 'color': 'blue'},
    {'name': '3- Naga', 'year': 'AY 2024-2025', 'color': 'green'},
    {'name': '3- Redwood', 'year': 'AY 2024-2025', 'color': 'blue'},
  ];

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'pink':
        return Colors.pink.shade100;
      case 'green':
        return Colors.green.shade100;
      case 'blue':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding (
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Class List
            ...classes.map((c) {
              return GestureDetector(
                onTap: () {
                  // Sample data for demonstration
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassPage(
                        className: c['name']!,
                        year: c['year']!,
                        students: ['Sam Teng', 'Nina Valdez', 'Juan De La Cruz', 'Juan Cruz', 'Lorem Ipsum'],
                        storiesRead: 90,
                        errorRate: 24,
                        focusAreas: {'Verbs': 28, 'Ordering Events': 19},
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getColor(c['color']!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['year']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],))
       );
  }
}