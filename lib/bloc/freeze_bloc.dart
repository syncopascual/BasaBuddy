import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FreezeEvent {}

class SetFreeze extends FreezeEvent {
  final int value;
  SetFreeze(this.value);
}

class ChangeFreeze extends FreezeEvent {
  final int delta;
  ChangeFreeze(this.delta);
}

class FreezeState {
  final int freezeCount;
  FreezeState(this.freezeCount);
}

class FreezeBloc extends Bloc<FreezeEvent, FreezeState> {
  FreezeBloc() : super(FreezeState(0)) {
    on<SetFreeze>((event, emit) {
      emit(FreezeState(event.value));
    });

    on<ChangeFreeze>((event, emit) {
      emit(FreezeState(state.freezeCount + event.delta));
    });
  }
}