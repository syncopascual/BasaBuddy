import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/database_helper.dart';

abstract class FreezeEvent {}

class SetFreeze extends FreezeEvent {
  final int value;
  SetFreeze(this.value);
}

class ChangeFreeze extends FreezeEvent {
  final int delta;
  ChangeFreeze(this.delta);
}

class LoadFreeze extends FreezeEvent {}

class FreezeState {
  final int freezeCount;
  FreezeState(this.freezeCount);
}

class FreezeBloc extends Bloc<FreezeEvent, FreezeState> {
  FreezeBloc() : super(FreezeState(0)) {
    on<LoadFreeze>((LoadFreeze event, Emitter<FreezeState> emit) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final db = await DatabaseHelper.instance.db;
      final row = await db.query('user_streak', where: 'user_id = ?', whereArgs: [userId]);
      final count = row.isNotEmpty ? (row.first['freeze_count'] as int? ?? 0) : 0;
      emit(FreezeState(count));
    });

    on<SetFreeze>((SetFreeze event, Emitter<FreezeState> emit) {
      emit(FreezeState(event.value));
    });

    on<ChangeFreeze>((ChangeFreeze event, Emitter<FreezeState> emit) {
      emit(FreezeState(state.freezeCount + event.delta));
    });

    add(LoadFreeze());

  }
}