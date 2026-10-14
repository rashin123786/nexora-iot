import 'package:flutter/material.dart';

import '../../../../core/platform/battery_service.dart';

class BatteryCard extends StatefulWidget {
  const BatteryCard({super.key});

  @override
  State<BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends State<BatteryCard> {
  final BatteryService _batteryService = BatteryService();

  int? batteryLevel;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadBattery();
  }

  Future<void> _loadBattery() async {
    try {
      final level = await _batteryService.getBatteryLevel();

      if (!mounted) return;

      setState(() {
        batteryLevel = level;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Battery unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.battery_charging_full,
              color: Colors.greenAccent,
              size: 36,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error ??
                      (batteryLevel == null ? 'Loading...' : '$batteryLevel%'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Android Device Battery',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadBattery,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
