import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/smart_home_data.dart';
import '../../domain/usecases/smart_home_usecases.dart';

sealed class SmartHomeEvent extends Equatable {
  const SmartHomeEvent();
  @override
  List<Object?> get props => [];
}

class ConnectRequested extends SmartHomeEvent {}

class LightToggleRequested extends SmartHomeEvent {
  final bool on;
  const LightToggleRequested(this.on);
  @override
  List<Object?> get props => [on];
}

class _DataReceived extends SmartHomeEvent {
  final SmartHomeData data;
  const _DataReceived(this.data);
  @override
  List<Object?> get props => [data.lightOn, data.temperature, data.humidity];
}

class _CommandTimedOut extends SmartHomeEvent {}

class SmartHomeState extends Equatable {
  final bool connected;
  final bool loading;
  final bool waiting;
  final SmartHomeData data;
  final String status;
  const SmartHomeState({
    this.connected = false,
    this.loading = false,
    this.waiting = false,
    this.data = const SmartHomeData(),
    this.status = 'Not connected',
  });
  SmartHomeState copyWith({
    bool? connected,
    bool? loading,
    bool? waiting,
    SmartHomeData? data,
    String? status,
  }) => SmartHomeState(
    connected: connected ?? this.connected,
    loading: loading ?? this.loading,
    waiting: waiting ?? this.waiting,
    data: data ?? this.data,
    status: status ?? this.status,
  );
  @override
  List<Object?> get props => [
    connected,
    loading,
    waiting,
    data.lightOn,
    data.temperature,
    data.humidity,
    status,
  ];
}

class SmartHomeBloc extends Bloc<SmartHomeEvent, SmartHomeState> {
  final ConnectSmartHome connectSmartHome;
  final WatchSmartHome watchSmartHome;
  final SetLight setLight;
  StreamSubscription? _subscription;
  Timer? _commandTimer;
  bool? _pendingTarget;
  SmartHomeBloc({
    required this.connectSmartHome,
    required this.watchSmartHome,
    required this.setLight,
  }) : super(const SmartHomeState()) {
    on<ConnectRequested>(_connect);
    on<LightToggleRequested>(_toggle);
    on<_DataReceived>((event, emit) {
      // Sensor readings must not clear a pending light command.
      final confirmed =
          _pendingTarget != null && event.data.lightOn == _pendingTarget;
      if (confirmed) {
        _commandTimer?.cancel();
        _pendingTarget = null;
      }
      emit(
        state.copyWith(
          data: event.data,
          waiting: confirmed ? false : state.waiting,
          status: confirmed ? 'Device confirmed' : state.status,
        ),
      );
    });
    on<_CommandTimedOut>((event, emit) {
      _pendingTarget = null;
      emit(state.copyWith(waiting: false, status: 'Command timed out; retry'));
    });
  }
  Future<void> _connect(
    ConnectRequested event,
    Emitter<SmartHomeState> emit,
  ) async {
    emit(state.copyWith(loading: true, status: 'Connecting...'));
    try {
      final ready = await connectSmartHome();
      if (!ready) {
        emit(state.copyWith(loading: false, status: 'MQTT connection failed'));
        return;
      }
      _subscription = watchSmartHome().listen(
        (data) => add(_DataReceived(data)),
      );
      emit(
        state.copyWith(
          connected: true,
          loading: false,
          status: 'MQTT connected',
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, status: 'Connection error: $e'));
    }
  }

  void _toggle(LightToggleRequested event, Emitter<SmartHomeState> emit) {
    if (!state.connected || state.waiting) return;
    if (!setLight(event.on)) {
      emit(state.copyWith(status: 'Unable to send command'));
      return;
    }
    _pendingTarget = event.on;
    emit(state.copyWith(waiting: true, status: 'Sending command...'));
    _commandTimer?.cancel();
    _commandTimer = Timer(
      const Duration(seconds: 8),
      () => add(_CommandTimedOut()),
    );
  }

  @override
  Future<void> close() async {
    _commandTimer?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
