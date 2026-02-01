import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_class_bottom_sheet.dart';

import 'class_page.dart';
import '../../colors.dart';

class TeacherHome extends StatefulWidget {
  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {

  List<Map<String, String>> classes = []; // initially empty
  bool loading = true; // show loading indicator

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }
  
  /*final List<Map<String, String>> classes = const [
    {'name': '3- Ipil', 'year': 'AY 2024-2025', 'color': 'pink'},
    {'name': '3- Sampaguita', 'year': 'AY 2024-2025', 'color': 'green'},
    {'name': '3- Narra', 'year': 'AY 2024-2025', 'color': 'blue'},
    {'name': '3- Kamagong', 'year': 'AY 2024-2025', 'color': 'pink'},
    {'name': '3- Mahogany', 'year': 'AY 2024-2025', 'color': 'green'},
    {'name': '3- Mola', 'year': 'AY 2024-2025', 'color': 'blue'},
    {'name': '3- Naga', 'year': 'AY 2024-2025', 'color': 'green'},
    {'name': '3- Redwood', 'year': 'AY 2024-2025', 'color': 'blue'},
  ];*/

  Future<void> fetchClasses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Fetch assigned_classes array from teacher_classes table
    final res = await Supabase.instance.client
        .from('classes')
        .select('name, year, id')
        .eq('teacher_id', user.id);
    print(res);
    // Map array to your UI structure
    final colorOptions = ['pink', 'green', 'blue'];
    setState(() {
      classes = List<Map<String, String>>.generate(res.length, (index) {
        final c = res[index] as Map<String, dynamic>;
        return {
          'name': c['name'].toString(),
          'year': 'AY ${c['year']}',
          'color': colorOptions[index % colorOptions.length],
        };
      });
      loading = false;
    });
  }


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
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding (
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final added = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => AddClassBottomSheet(),
                  );
                  if (added == true){
                    setState(() => loading = true);
                  await fetchClasses();
                  }
                  
                },
                
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Add New Class',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              )
            ),
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