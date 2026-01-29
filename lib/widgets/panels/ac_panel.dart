import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../glass_panel.dart';
import '../mini_chart.dart';

class ACPanel extends StatefulWidget {
  final String deviceId;
  final Function(bool) onToggle3D;
  const ACPanel({super.key, required this.deviceId, required this.onToggle3D});
  @override State<ACPanel> createState() => _ACPanelState();
}

class _ACPanelState extends State<ACPanel> {
  int temp = 24;
  bool showChart = false;
  final List<double> fakeTempData = List.generate(10, (index) => 20 + Random().nextDouble() * 8);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: deviceManager, builder: (context, _) {
      final device = deviceManager.getDevice(widget.deviceId);
      return BasePanel(
        icon: device.icon,
        color: device.color,
        title: device.name,
        room: device.room, // <--- Truyền tên phòng
        isOn: device.isOn,
        onToggle: (v) { deviceManager.toggleDevice(widget.deviceId, v); widget.onToggle3D(v); },
        isChartMode: showChart,
        onChartClick: () => setState(() => showChart = !showChart),
        child: showChart
            ? MiniChart(data: fakeTempData, color: Colors.cyan, unit: '°C')
            : Row(
                key: const ValueKey("controls"),
                mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: () => setState(() => temp--), icon: const Icon(Icons.remove_circle_outline)),
                Text("$temp°C", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                IconButton(onPressed: () => setState(() => temp++), icon: const Icon(Icons.add_circle_outline)),
              ]),
      );
    });
  }
}