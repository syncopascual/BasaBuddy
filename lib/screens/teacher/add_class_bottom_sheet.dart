import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class AddClassBottomSheet extends StatefulWidget {
  const AddClassBottomSheet({super.key});

  @override
  State<AddClassBottomSheet> createState() => _AddClassBottomSheet();
}



class _AddClassBottomSheet extends State<AddClassBottomSheet> {
  final _classNameController = TextEditingController();
  final _yearController = TextEditingController();
  bool _loading = false;
  String generateClassCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();

    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }
  Future<String> createUniqueClassCode() async {
    while (true) {
      final code = generateClassCode();

      final existing = await Supabase.instance.client
          .from('classes')
          .select('id')
          .eq('class_code', code)
          .maybeSingle();

      if (existing == null) return code;
    }
  }
  Future<void> _addClass() async {
    final className = _classNameController.text.trim();
    final year = _yearController.text.trim();

    if (className.isEmpty || year.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
       );
       return;
    }

    setState(() => _loading = true);
    try {
      final code = await createUniqueClassCode();
      await Supabase.instance.client
        .from('classes')
        .insert({
          'name': className,
          'year': year,
          'teacher_id': Supabase.instance.client.auth.currentUser!.id,
          'class_code': code,
        });
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class "$className" added!')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  @override
  void dispose() {
    _classNameController.dispose();
    _yearController.dispose();
    super.dispose();
  }
  @override 
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Add New Class',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _addClass,
                child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Create Class'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}