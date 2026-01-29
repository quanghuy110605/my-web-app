import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Đảm bảo đã pub get
import '../../models/device_model.dart';
import '../glass_panel.dart';
import '../../services/mqtt_service.dart';
import '../mini_chart.dart';

class LightPanel extends StatefulWidget {
  final String deviceId;
  final Function(bool) onToggle3D;
  final Function(Color) onChangeColor;

  const LightPanel({
    super.key, 
    required this.deviceId, 
    required this.onToggle3D, 
    required this.onChangeColor
  });

  @override State<LightPanel> createState() => _LightPanelState();
}

class _LightPanelState extends State<LightPanel> {
  bool showChart = false;
  final List<double> fakeHistory = List.generate(24, (index) => 30 + Random().nextDouble() * 70); 

  void _openColorPicker(BuildContext context, Color currentColor) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Chọn màu đèn", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                deviceManager.changeColor(widget.deviceId, color);
                widget.onChangeColor(color);
                String hex = '#${color.value.toRadixString(16).substring(2)}';
                mqttHandler.publishMessage("home/control", '{"id": "${widget.deviceId}", "color": "$hex"}');
              },
              colorPickerWidth: 250,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hueWheel,
              labelTypes: const [],
              pickerAreaBorderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
            ),
          ),
          actions: [TextButton(child: const Text("XONG", style: TextStyle(color: Colors.amber)), onPressed: () => Navigator.of(ctx).pop())],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deviceManager,
      builder: (context, _) {
        final device = deviceManager.getDevice(widget.deviceId);
        return BasePanel(
          icon: device.icon,
          color: device.color,
          title: device.name,
          room: device.room,
          isOn: device.isOn,
          onToggle: (v) {
            deviceManager.toggleDevice(widget.deviceId, v);
            widget.onToggle3D(v);
            mqttHandler.publishMessage("home/control", '{"id": "${widget.deviceId}", "status": ${v ? "ON" : "OFF"}}');
          },
          isChartMode: showChart,
          onChartClick: () => setState(() => showChart = !showChart),
          child: showChart 
            ? MiniChart(data: fakeHistory, color: device.color, unit: '%')
            : Column(
                key: const ValueKey("controls"),
                children: [
                   Row(children: [
                     const Icon(Icons.brightness_6, size: 16, color: Colors.grey), 
                     Expanded(child: SliderTheme(
                       data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: device.color,
                        inactiveTrackColor: Colors.grey.shade300,
                       ),
                       child: Slider(
                         value: device.brightness, 
                         min: 0, max: 100, 
                         onChanged: (v) => deviceManager.changeBrightness(widget.deviceId, v),
                         onChangeEnd: (v) => mqttHandler.publishMessage("home/control", '{"id": "${widget.deviceId}", "brightness": ${v.toInt()}}'),
                       ),
                     ))
                   ]),
                   Text("${device.brightness.toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                   const SizedBox(height: 5),
                   GestureDetector(
                     onTap: () => _openColorPicker(context, device.color), 
                     child: Container(
                       height: 40, 
                       decoration: BoxDecoration(color: device.color, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white)), 
                       child: const Center(child: Icon(Icons.color_lens, color: Colors.white))
                    )
                   )
                ],
              ),
        );
      }
    );
  }
}