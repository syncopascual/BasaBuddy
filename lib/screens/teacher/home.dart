import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/classes.dart';
import 'add_class_bottom_sheet.dart';
import 'class_page.dart';
import 'package:go_router/go_router.dart';

class TeacherHome extends StatefulWidget {
  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  String? teacherName;
  Future<List<Classes>>? _classesFuture;
  List<Classes> _allClasses = [];
  List<Classes> _filteredClasses = [];
  final TextEditingController _searchController = TextEditingController();
 
  // --- Color palette cycling ---
  static const List<_CardTheme> _cardThemes = [
    _CardTheme(card: Color(0xFFFBEAF0), dot: Color(0xFFF4C0D1), text: Color(0xFF72243E), badge: Color(0xFFF4C0D1)),
    _CardTheme(card: Color(0xFFE1F5EE), dot: Color(0xFF9FE1CB), text: Color(0xFF085041), badge: Color(0xFF9FE1CB)),
    _CardTheme(card: Color(0xFFE6F1FB), dot: Color(0xFFB5D4F4), text: Color(0xFF0C447C), badge: Color(0xFFB5D4F4)),
    _CardTheme(card: Color(0xFFFAEEDA), dot: Color(0xFFFAC775), text: Color(0xFF633806), badge: Color(0xFFFAC775)),
    _CardTheme(card: Color(0xFFEEEDFE), dot: Color(0xFFCECBF6), text: Color(0xFF3C3489), badge: Color(0xFFCECBF6)),
  ];

  void _onSearchChanged(String query) {
    setState(() {
      _filteredClasses = query.isEmpty
          ? _allClasses
          : _allClasses
              .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }
  

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchTeacherName();
    _classesFuture = _fetchClasses();
  }

  Future<List<Classes>> _fetchClasses() async {
    print("teacher home.dart: fetchClasses called");
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final res = await Supabase.instance.client
      .from('classes')
      .select()
      .eq('teacher_id', user.id);

    return (res as List).map((json) => Classes.fromJson(json)).toList();
  }

  void _refresh() {
    _searchController.clear();
    setState(() {
      _allClasses = [];
      _filteredClasses = [];
      _classesFuture = _fetchClasses();
    });
  }

  Future<void> fetchTeacherName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      teacherName = profile?['name'] ?? 'Teacher';
    });
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea (
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20,16,20,8),
              child: Text(
                'ACTIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(child: _buildClassList()),
            _buildAddButton(),
          ]
        ),),
       );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good day, ${teacherName ?? ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              const Text(
                'My Classes',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async { 
              if(value=='logout'){
                await _logout(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value:'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: Colors.grey.shade700),
                    SizedBox(width: 8),
                    Text('Log out', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF9FE1CB),
              child: Text(
                teacherName != null && teacherName!.isNotEmpty
                  ? teacherName![0].toUpperCase()
                  : '?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF085041),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
        hintText: 'Search classes...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade300, width: 1),
        ),
      ),
      )
    );
  }

   Widget _buildClassList() {
    return FutureBuilder<List<Classes>>(
      future: _classesFuture ??= _fetchClasses(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
 
        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
                const SizedBox(height: 8),
                const Text('Failed to load classes.'),
                TextButton(onPressed: _refresh, child: const Text('Try again')),
              ],
            ),
          );
        }

        final incoming = snapshot.data ?? [];
        if(_allClasses.isEmpty && incoming.isNotEmpty){
          _allClasses = incoming;
          _filteredClasses = incoming;
        }
        // Empty state
        if (_filteredClasses.isEmpty) {
          return const Center(
            child: Text(
              'No classes found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
 
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filteredClasses.length,
          itemBuilder: (_, i) {
            final theme = _cardThemes[i % _cardThemes.length];
            return _ClassCard(
              cls: _filteredClasses[i],
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassPage(classId: _filteredClasses[i].id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Material(
        color: const Color(0xFF1D9E75),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final added = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => AddClassBottomSheet(),
            );
            if (added == true) _refresh();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Color(0xFFE1F5EE)),
                SizedBox(width: 8),
                Text(
                  'Add new class',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE1F5EE),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTheme {
  final Color card;
  final Color dot;
  final Color text;
  final Color badge;
  const _CardTheme({
    required this.card,
    required this.dot,
    required this.text,
    required this.badge,
  });
}

class _ClassCard extends StatelessWidget {
  final Classes cls;
  final _CardTheme theme;
  final VoidCallback onTap;
 
  const _ClassCard({
    required this.cls,
    required this.theme,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dot, width: 0.5),
        ),
        child: Row(
          children: [
            // Icon dot
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.dot,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_today_outlined, size: 18, color: theme.text),
            ),
            const SizedBox(width: 14),
            // Class name + year
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cls.year,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.text.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.badge,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Grade 3',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: theme.text.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}