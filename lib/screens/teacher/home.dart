import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/classes.dart';
import '../../models/student.dart';
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

  Future<List<Classes>> fetchClasses() async {
    print("teacher home.dart: fetchClasses called");
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try{
      // Fetch assigned_classes array from teacher_classes table
      final res = await Supabase.instance.client
          .from('classes')
          .select()
          .eq('teacher_id', user.id);

      List<Classes> classes = (res as List)
          .map((json) => Classes.fromJson(json))
          .toList();

      print("classes fetched, returning classes:");
      print(classes);
      return classes;
    } catch(e){
      print(e);

    }
    return [];



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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container (
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Classes>>(
          future: fetchClasses(),
          builder: (context, snapshot) {
            if(!snapshot.hasData){
              return Text("no data yet");
            } else {
              return Column(
                children: [
                  /// Add new class button
                  Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child:
                      InkWell(
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
                  Container(
                    height: 400,
                    child: ListView.builder(
                        itemCount: snapshot.data?.length,
                        itemBuilder: (_, i){
                          return GestureDetector(
                            onTap: () {
                              // Sample data for demonstration
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClassPage(
                                    classId: snapshot.data![i].id,
                                  ),
                                ),
                              );


                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getColor('pink'),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot.data![i].name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    snapshot.data![i].year,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                    }),
                  )
                ],);
            }
          },
        ))
       );
  }
}