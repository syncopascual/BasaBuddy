import 'package:flutter_bloc/flutter_bloc.dart';


abstract class ThemeEvent {}

class SetVocab extends ThemeEvent {
  SetVocab();
}

class SetNarrative extends ThemeEvent {
  SetNarrative();
}

class SetInformation extends ThemeEvent {
  SetInformation();
}



class ThemeState {
  final String theme;
  ThemeState(this.theme);
}

//initial data not necessary
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {


  ThemeBloc() : super(ThemeState("narrative")) {
    print('SETTING UP TranslationBloc');
    //subscription.resume();

    on<SetNarrative>((event, emit) async {

      emit(ThemeState("narrative"));

    });
    on<SetVocab>((event, emit) async {

      emit(ThemeState("vocab"));
    });

    on<SetInformation>((event, emit) async {

      emit(ThemeState("information"));
    });
  }
}