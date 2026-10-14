import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/websocket_service.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final service = sl<WebSocketService>();
  final events = <String>[];
  StreamSubscription? subscription;

  bool connected = false;

  // Replace with your laptop's Wi-Fi IPv4 address.
  static const serverUrl = 'ws://127.0.0.1:8080/ws';
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    subscription = service.events.listen((message) {
      if (!mounted) return;

      setState(() {
        events.insert(0, '${TimeOfDay.now().format(context)}  $message');
      });
    });

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);

      try {
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:8080/ws'),
        );

        final response = await request.close();

        debugPrint('ANDROID HTTP STATUS: ${response.statusCode}');
      } catch (e) {
        debugPrint('ANDROID HTTP ERROR: $e');
      } finally {
        client.close(force: true);
      }
      await service.connect(serverUrl);

      if (!mounted) return;

      setState(() => connected = true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        events.insert(0, 'Connection failed: $e');
      });
    }
  }

  void sendTestEvent() {
    if (!connected) return;

    service.send('NEXORA Test Event');
  }

  @override
  void dispose() {
    subscription?.cancel();
    unawaited(service.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101827),
      appBar: AppBar(
        title: const Text('Live Activity'),
        backgroundColor: const Color(0xFF101827),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: connected ? sendTestEvent : null,
        icon: const Icon(Icons.send),
        label: const Text('Send Test'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.circle,
              color: connected ? Colors.green : Colors.red,
              size: 14,
            ),
            title: Text(
              connected ? 'WebSocket Connected' : 'WebSocket Disconnected',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Colors.cyanAccent),
                    title: Text(
                      events[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
