import 'package:basabuddy/models/mulcho.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/story.dart';

class Module extends StatefulWidget {

  final String moduleType;
  const Module(this.moduleType, {super.key});

  @override
  State<Module> createState() => _ModuleState();
}

class _ModuleState extends State<Module> {
  late Future<List<Story>> stories;

  ///Fetch Stories from supabase
  Future<List<Story>> _fetchStories() async {
    print("MODULE.dart :: _fetchStories() called");
    //print(Supabase.instance.client.auth.currentUser);
    final response = await Supabase.instance.client
        .from('list_stories')
        .select();
    print("After Supabase query");
    print(response);

    final stories = (response as List)
        .map((json) => Story.fromJson(json))
        .toList();
    print("Stories");
    print(stories);

    return stories;
  }

  @override
  void initState() {
    super.initState();
    stories = _fetchStories(); // Start the async operation in initState
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg_images/${widget.moduleType}.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 400,
            child: FutureBuilder(
                future: stories,
                builder: (context, snapshot){
                  if(snapshot.hasData){
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                        itemBuilder: (_, i){
                      print("i: $i");
                      return ElevatedButton(
                          onPressed: (){
                            context.go('/story/${snapshot.data?[i].storyId}');
                          },
                          child: Text(snapshot.data![i].title));
                    });
                  } else {
                    return const Center(child: CircularProgressIndicator());

                  }
                }),
          ),
          Container(height:200),
          ElevatedButton(onPressed: (){


            context.go('/story');
          }, child: Text("Sample Story"))

        ],
      ),
    );
  }
}