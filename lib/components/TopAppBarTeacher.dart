import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../colors.dart';

class TopAppBarTeacher extends StatelessWidget implements PreferredSizeWidget{
  const TopAppBarTeacher(this.screenWidth, {required this.teacherName, super.key});

  final double screenWidth;
  final String teacherName;

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
        elevation: 0,
        backgroundColor: teacherAppBar,
        //title: const Text('lvl info'),
        leadingWidth: screenWidth * 0.5, //TODO:: make more responsive
        leading: PopupMenuButton<String>(
          offset: const Offset(0, kToolbarHeight),
          onSelected: (value) {
            if (value == 'logout') {
              _logout(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value:'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Log out'),
                ],
              ),
            ),
          ],
          
          child: Row(children: [
          Container(
            margin: EdgeInsets.fromLTRB(screenWidth * 0.08, 0, screenWidth * 0.02, 0),
            child: ImageIcon(
              const AssetImage("assets/icons/profile.png"),
              color: profileIcon,
            ),
          ),

          Text(
            teacherName,
            style: TextStyle(color: topBarText)
          ),
        
          ],
          ),
        ),        
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);///irdk what this does cry emoji cry emoji
}