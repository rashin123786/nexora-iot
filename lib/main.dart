import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/network/websocket_service.dart';
import 'features/smart_home/presentation/bloc/smart_home_bloc.dart';
import 'features/smart_home/presentation/pages/smart_home_page.dart';

// Development only: requires `adb reverse tcp:8080 tcp:8080`.
const websocketUrl = 'ws://127.0.0.1:8080/ws';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  // Don't delay MQTT startup if the local WebSocket server is unavailable.
  unawaited(sl<WebSocketService>().connect(websocketUrl));
  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<SmartHomeBloc>()..add(ConnectRequested()),
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SmartHomePage(),
    ),
  );
}
