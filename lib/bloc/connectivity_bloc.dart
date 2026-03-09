///You should not rely on the current connectivity status to decide
///whether you can reliably make a network request. Always guard
///your app code against timeouts and errors that might come from
///the network layer. Connection type availability does not guarantee
///that there is an Internet access. For example, the plugin might
///return Wi-Fi connection type, but it might be a connection with
///no Internet access due to network requirements (like on hotel
///Wi-Fi networks where user often needs to go through a captive
///portal to authorize first).


import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object> get props => [];
}

class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> results;

  ConnectivityChanged(this.results);
}

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object> get props => [];
}

// Initial state before any connectivity check
class ConnectivityInitial extends ConnectivityState {}

// State when connectivity check is successful
class ConnectivitySuccess extends ConnectivityState {
  final bool isConnected;

  const ConnectivitySuccess(this.isConnected);

  @override
  List<Object> get props => [isConnected];
}

// State when there is no connectivity
class ConnectivityFailure extends ConnectivityState {
  @override
  List<Object> get props => [];
}


class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    // Immediately check the current connection status when Bloc starts
    _checkInitialConnectivity();

    // Listen to connectivity changes properly
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Now you can directly use the list of results
      add(ConnectivityChanged(results));
    });

    // Handle events inside on<> to follow best practices
    on<ConnectivityChanged>((event, emit) {
      print("CONNECTIVITY BLOC--------- connectivity changed!!");
      print("event results ");
      print(event.results);
      final isConnected = event.results.any((result) => result != ConnectivityResult.none);
      print('isConnected');
      print(isConnected);
      emit(isConnected ? ConnectivitySuccess(isConnected) : ConnectivityFailure());
    });
  }

  // Check the current network status when initializing
  Future<void> _checkInitialConnectivity() async {
    print("CONNECTIVITY BLOC -------- checking initial connectivity");
    final result = await _connectivity.checkConnectivity();
    add(ConnectivityChanged(result));
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}