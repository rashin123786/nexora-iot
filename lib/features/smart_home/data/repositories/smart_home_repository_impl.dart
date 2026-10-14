import 'dart:async';
import 'dart:convert';
import '../../../../core/network/mqtt_service.dart';
import '../../domain/entities/smart_home_data.dart';
import '../../domain/repositories/smart_home_repository.dart';
import '../datasources/virtual_bulb_simulator.dart';

class SmartHomeRepositoryImpl implements SmartHomeRepository {
  final MqttService controller;
  final VirtualBulbSimulator simulator;
  final String baseTopic;
  final _data = StreamController<SmartHomeData>.broadcast();
  StreamSubscription? _messages;
  SmartHomeData _current = const SmartHomeData();
  SmartHomeRepositoryImpl({required this.controller, required this.simulator, required this.baseTopic});
  @override
  Future<bool> connect() async {
    if (!await simulator.start()) return false;
    if (!await controller.connect()) return false;
    _messages = controller.messages.listen((event) {
      if (event.key == '$baseTopic/light/state' && (event.value == 'ON' || event.value == 'OFF')) {
        _current = _current.copyWith(lightOn: event.value == 'ON');
        _data.add(_current);
      } else if (event.key == '$baseTopic/sensors/environment') {
        try {
          final json = jsonDecode(event.value) as Map<String, dynamic>;
          _current = _current.copyWith(
            temperature: (json['temperature'] as num).toDouble(),
            humidity: (json['humidity'] as num).toDouble(),
          );
          _data.add(_current);
        } catch (_) { /* Ignore invalid external MQTT payloads. */ }
      }
    });
    controller.subscribe('$baseTopic/light/state');
    controller.subscribe('$baseTopic/sensors/environment');
    return true;
  }
  @override
  Stream<SmartHomeData> watchData() => _data.stream;
  @override
  bool setLight(bool on) => controller.publish('$baseTopic/light/set', on ? 'ON' : 'OFF');
  @override
  Future<void> dispose() async {
    await _messages?.cancel();
    await _data.close();
    await controller.dispose();
    await simulator.dispose();
  }
}
