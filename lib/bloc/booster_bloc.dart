import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/database_helper.dart';

abstract class BoosterEvent {}

class LoadBooster extends BoosterEvent {}

class SetBooster extends BoosterEvent {
  final int value;
  SetBooster(this.value);
}

class BoosterState {
  final int storiesRemaining;
  bool get isActive => storiesRemaining > 0;
  BoosterState(this.storiesRemaining);
}

class BoosterBloc extends Bloc<BoosterEvent, BoosterState> {
  BoosterBloc() : super(BoosterState(0)) {

    on<LoadBooster>((LoadBooster event, Emitter<BoosterState> emit) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final db = await DatabaseHelper.instance.db;
      final row = await db.query('user_boosts',
          where: 'user_id = ?', whereArgs: [userId]);
      final count = row.isNotEmpty
          ? (row.first['stories_remaining'] as int? ?? 0)
          : 0;
      
      if (row.isEmpty) {
        final now = DateTime.now().toUtc().toIso8601String();
        await db.insert('user_boosts', {
          'user_id': userId,
          'stories_remaining': 0,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        await Supabase.instance.client.from('user_boosts').upsert({
          'user_id': userId,
          'stories_remaining': count,
          'updated_at': now,
        }, onConflict: 'user_id');
      } catch (_) {}
      emit(BoosterState(count));
    });

    on<SetBooster>((SetBooster event, Emitter<BoosterState> emit) {
      emit(BoosterState(event.value));
    });

    add(LoadBooster());
  }
}