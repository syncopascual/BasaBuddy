import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


abstract class TranslationEvent {}

class ToggleTranslation extends TranslationEvent {

  ToggleTranslation();
}


class SetEnglish extends TranslationEvent {
  SetEnglish();
}

class TranslationState {
  final bool isEnglish;
  TranslationState(this.isEnglish);
}

//initial data not necessary
class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {


  TranslationBloc() : super(TranslationState(true)) {
    print('SETTING UP TranslationBloc');
    //subscription.resume();

    //TODO: improve type safety
    on<ToggleTranslation>((event, emit) async {
      print('ToggleTranslation EVENT CALLED');
      print("emitting isEnglish ${!state.isEnglish}");

      emit(TranslationState(!state.isEnglish));

    });
    on<SetEnglish>((event, emit) async {

      emit(TranslationState(true));
    });
  }
}