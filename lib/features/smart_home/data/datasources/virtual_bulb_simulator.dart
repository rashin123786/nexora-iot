import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../../../../core/network/mqtt_service.dart';

class VirtualBulbSimulator {
  final MqttService mqtt;
  final String baseTopic;
  StreamSubscription? _subscription;
  Timer? _timer;
  final _random = Random();
  VirtualBulbSimulator({required this.mqtt, required this.baseTopic});
  Future<bool> start() async {
    if (!await mqtt.connect()) return false;
    _subscription = mqtt.messages.listen((event) {
      if (event.key == '$baseTopic/light/set' && (event.value == 'ON' || event.value == 'OFF')) {
        mqtt.publish('$baseTopic/light/state', event.value);
      }
    });
    mqtt.subscribe('$baseTopic/light/set');
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _sendSensor());
    return true;
  }
  void _sendSensor() {
    mqtt.publish('$baseTopic/sensors/environment', jsonEncode({
      'temperature': double.parse((24 + _random.nextDouble() * 8).toStringAsFixed(1)),
      'humidity': double.parse((40 + _random.nextDouble() * 30).toStringAsFixed(1)),
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  Future<void> dispose() async {
    _timer?.cancel();
    await _subscription?.cancel();
    await mqtt.dispose();
  }
}
