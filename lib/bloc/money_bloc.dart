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
      UserMoney? moneyObject = await DatabaseHelper.instance.queryFirst('user_money', UserMoney.fromJson);
      int? newMoney = moneyObject!.money + 50;

      await DatabaseHelper.instance.updateFirstNoWhere("user_money", {"money": newMoney});

      emit(MoneyState(newMoney));

    });
    on<SyncMoney>((event, emit) async {
      print('SYNCMONEY EVENT CALLED');
      final moneyJson = await Supabase.instance.client
          .from('user_money')
          .select();

      final money = moneyJson[0]["money"];

      emit(MoneyState(money));
    });
  }
}