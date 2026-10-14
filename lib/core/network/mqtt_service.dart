import 'dart:async';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final clientId = 'nexora_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
  late final MqttServerClient client;
  final _messages = StreamController<MapEntry<String, String>>.broadcast();
  Stream<MapEntry<String, String>> get messages => _messages.stream;
  StreamSubscription? _subscription;
  MqttService() {
    client = MqttServerClient.withPort('broker.hivemq.com', clientId, 1883);
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 10000;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
  }
  bool get isConnected => client.connectionStatus?.state == MqttConnectionState.connected;
  Future<bool> connect() async {
    try {
      client.connectionMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean();
      await client.connect();
      if (!isConnected) return false;
      await _subscription?.cancel();
      _subscription = client.updates?.listen((updates) {
        for (final item in updates) {
          final payload = item.payload as MqttPublishMessage;
          if (!_messages.isClosed) {
            _messages.add(MapEntry(item.topic, MqttPublishPayload.bytesToStringAsString(payload.payload.message)));
          }
        }
      });
      return true;
    } catch (_) {
      client.disconnect();
      return false;
    }
  }
  void subscribe(String topic) {
    if (isConnected) client.subscribe(topic, MqttQos.atLeastOnce);
  }
  bool publish(String topic, String message) {
    if (!isConnected) return false;
    final builder = MqttClientPayloadBuilder()..addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    return true;
  }
  Future<void> dispose() async {
    await _subscription?.cancel();
    client.disconnect();
    await _messages.close();
  }
}
