import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_iot/features/smart_home/presentation/pages/activity_page.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/websocket_service.dart';
import '../bloc/smart_home_bloc.dart';
import '../widgets/battery_card.dart';

class SmartHomePage extends StatelessWidget {
  const SmartHomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF101827),
    appBar: AppBar(
      title: const Text('NEXORA IoT'),
      backgroundColor: const Color(0xFF101827),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActivityPage()),
            );
          },
        ),
      ],
    ),
    body: BlocListener<SmartHomeBloc, SmartHomeState>(
      listenWhen: (previous, current) {
        return previous.connected != current.connected ||
            previous.data.lightOn != current.data.lightOn ||
            previous.data.temperature != current.data.temperature ||
            previous.data.humidity != current.data.humidity;
      },
      listener: (context, state) {
        final ws = sl<WebSocketService>();

        if (state.connected) {
          ws.send(
            'Temperature: '
            '${state.data.temperature?.toStringAsFixed(1) ?? '--'}°C | '
            'Humidity: '
            '${state.data.humidity?.toStringAsFixed(1) ?? '--'}%',
          );
        }
      },
      child: BlocBuilder<SmartHomeBloc, SmartHomeState>(
        builder: (context, state) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.data.lightOn
                      ? Icons.lightbulb
                      : Icons.lightbulb_outline,
                  size: 90,
                  color: state.data.lightOn ? Colors.amber : Colors.white54,
                ),
                const SizedBox(height: 20),
                Text(
                  state.status,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (state.loading) const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Switch(
                  value: state.data.lightOn,
                  onChanged: state.connected && !state.waiting
                      ? (value) => context.read<SmartHomeBloc>().add(
                          LightToggleRequested(value),
                        )
                      : null,
                ),
                Text(
                  state.data.lightOn ? 'LIGHT ON' : 'LIGHT OFF',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'Temperature',
                        value: state.data.temperature == null
                            ? '--'
                            : '${state.data.temperature!.toStringAsFixed(1)}°C',
                        icon: Icons.thermostat,
                      ),
                    ),
                    Expanded(
                      child: _SensorCard(
                        label: 'Humidity',
                        value: state.data.humidity == null
                            ? '--'
                            : '${state.data.humidity!.toStringAsFixed(1)}%',
                        icon: Icons.water_drop,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const BatteryCard(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SensorCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E293B),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: Colors.lightBlueAccent),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 23),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}
