import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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

      final moneyJson = await Supabase.instance.client
          .from('user_money')
          .select();

      moneyJson[0]["money"] += event.money;

      await Supabase.instance.client
          .from('user_money')
          .update(moneyJson[0]);

      emit(MoneyState(moneyJson[0]["money"]));

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