import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/userMoney.dart';
import '../utils/database_helper.dart';



abstract class MoneyEvent {}

class ChangeMoney extends MoneyEvent {
  final int money;//amount to be added/ subtracted

  ChangeMoney(this.money);
}


class SyncMoney extends MoneyEvent {
  SyncMoney();
}

class SetMoney extends MoneyEvent {
  final int value;
  SetMoney(this.value);
}

class LoadMoney extends MoneyEvent {
  LoadMoney();
}

class MoneyState {
  final int money;
  MoneyState(this.money);
}

//initial data not necessary
class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {
  MoneyBloc() : super(MoneyState(0)) {
    print('SETTING UP MoneyBloc');

    //subscription.resume();
    on<LoadMoney>((LoadMoney event, Emitter<MoneyState> emit) async {
      print('LOADMONEY EVENT CALLED');
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Load from local DB first (fast)
      final moneyObject = await DatabaseHelper.instance.queryWhere(
        'user_money',
        UserMoney.fromJson,
        'user_id = ?',
        [userId],
      );
      final int localMoney = moneyObject.isNotEmpty ? moneyObject.first.money : 0;
      emit(MoneyState(localMoney));

      // 2. Optionally sync from remote (authoritative)
      try {
        final remote = await Supabase.instance.client
            .from('user_money')
            .select('money')
            .eq('user_id', userId)
            .single();
        final int remoteMoney = remote['money'] ?? localMoney;
        if (remoteMoney != localMoney) {
          // Update local to match remote
          await DatabaseHelper.instance.updateFirstNoWhere("user_money", {
            "money": remoteMoney,
            "updated_at": DateTime.now().toUtc().toIso8601String(),
          });
          emit(MoneyState(remoteMoney));
        }
      } catch (e) {
        print('Remote sync skipped: $e');
        // Keep local value — fine for offline use
      }
    });

    //TODO: improve type safety
    on<ChangeMoney>((ChangeMoney event, Emitter<MoneyState> emit) async {
      print('CHANGEMONEY EVENT CALLED: +${event.money}');
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final now = DateTime.now().toUtc().toIso8601String();

      final moneyObject = await DatabaseHelper.instance.queryWhere(
        'user_money',
        UserMoney.fromJson,
        'user_id = ?',
        [userId],
);
      final int current = moneyObject.isNotEmpty ? moneyObject.first.money : 0;
      final int newMoney = current + event.money;

      final db = await DatabaseHelper.instance.db;

      await db.update(
        "user_money",
        {
          "money": newMoney,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );


      try {
        await Supabase.instance.client.from('user_money').upsert({
          'user_id': userId,
          'money': newMoney,
          'updated_at': now,
        }, onConflict: 'user_id');
      } catch (e) {
        print('Remote money update skipped (offline): $e');
        // Local is saved, sync will push it later when online
      }

      emit(MoneyState(newMoney));

    });

    on<SetMoney>((SetMoney event, Emitter<MoneyState> emit) {
      emit(MoneyState(event.value));
    });
    on<SyncMoney>((SyncMoney event, Emitter<MoneyState> emit) async {
      print('SYNCMONEY EVENT CALLED - deprecated');
    });

    add(LoadMoney());
  }
}