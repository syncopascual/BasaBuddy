import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/userMoney.dart';
import '../utils/database_helper.dart';



abstract class MoneyEvent {}

class ChangeMoney extends MoneyEvent {
  final money;//amount to be added/ subtracted

  ChangeMoney(this.money);
}


class SyncMoney extends MoneyEvent {
  SyncMoney();
}

class MoneyState {
  final money;
  MoneyState(this.money);
}

//initial data not necessary
class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {


  MoneyBloc() : super(MoneyState([])) {
    print('SETTING UP MoneyBloc');
    //subscription.resume();

    //TODO: improve type safety
    on<ChangeMoney>((event, emit) async {
      print('CHANGEMONEY EVENT CALLED');
      final db = await DatabaseHelper.instance.db;

      ///The user has to be logged in
      final userId = Supabase.instance.client.auth.currentUser?.id;
      List<UserMoney> moneyList = await DatabaseHelper.instance
          .queryWhere(
        'user_money',
        UserMoney.fromJson,
        'user_id = ?',
        [userId]);
      UserMoney? moneyObject = moneyList[0];
      int? newMoney = moneyObject.money + 50;




      await db.update(
          "user_money",
          {
            "money": newMoney,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'user_id = ?',
          whereArgs: [userId],
      );

      emit(MoneyState(newMoney));

    });
    on<SyncMoney>((event, emit) async {
      print('SYNCMONEY EVENT CALLED - deprecated');
    });
  }
}