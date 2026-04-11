import 'package:flutter_bloc/flutter_bloc.dart';

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

class MoneyState {
  final int money;
  MoneyState(this.money);
}

//initial data not necessary
class MoneyBloc extends Bloc<MoneyEvent, MoneyState> {


  MoneyBloc() : super(MoneyState(0)) {
    print('SETTING UP MoneyBloc');
    //subscription.resume();

    //TODO: improve type safety
    on<ChangeMoney>((event, emit) async {
      print('CHANGEMONEY EVENT CALLED: +${event.money}');
      UserMoney? moneyObject = await DatabaseHelper.instance.queryFirst('user_money', UserMoney.fromJson);
      final int current = moneyObject?.money ?? 0;
      final int newMoney = current + event.money;

      await DatabaseHelper.instance.updateFirstNoWhere("user_money", {
        "money": newMoney,
        "updated_at": DateTime.now().toUtc().toIso8601String(),
      });

      emit(MoneyState(newMoney));

    });
    on<SyncMoney>((event, emit) async {
      print('SYNCMONEY EVENT CALLED - deprecated');
    });
  }
}