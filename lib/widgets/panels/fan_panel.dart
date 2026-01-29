import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../glass_panel.dart';
import '../../services/mqtt_service.dart'; // Import để gửi MQTT
import '../mini_chart.dart';

class FanPanel extends StatefulWidget {
  final String deviceId;
  final Function(bool) onToggle3D;
  const FanPanel({super.key, required this.deviceId, required this.onToggle3D});
  @override State<FanPanel> createState() => _FanPanelState();
}

class _FanPanelState extends State<FanPanel> {
  double pwmValue = 0; // PWM từ 0 đến 100
  bool showChart = false;
  // Dữ liệu giả biểu đồ
  final List<double> fakeWindData = List.generate(15, (index) => Random().nextInt(100).toDouble());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: deviceManager, builder: (context, _) {
      final device = deviceManager.getDevice(widget.deviceId);
      
      // Màu mới cho thanh điều khiển (Cyan/Xanh lơ)
      final Color controlColor = Colors.cyanAccent;

      return BasePanel(
        icon: device.icon,
        color: device.color,
        title: device.name,
        room: device.room,
        isOn: device.isOn,
        onToggle: (v) {
          deviceManager.toggleDevice(widget.deviceId, v);
          widget.onToggle3D(v);
          // Gửi lệnh ON/OFF
          mqttHandler.publishMessage("home/control", '{"id": "${widget.deviceId}", "status": ${v ? "ON" : "OFF"}}');
        },
        isChartMode: showChart,
        onChartClick: () => setState(() => showChart = !showChart),
        
        child: showChart
            ? MiniChart(data: fakeWindData, color: controlColor, unit: '%')
            : Column(
                key: const ValueKey("controls"),
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  // Hiển thị % công suất
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Công suất gió (PWM)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("${pwmValue.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: controlColor, fontSize: 16)),
                    ],
                  ),
                  
                  // Thanh trượt PWM mượt (Không chia nấc)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: controlColor, // Màu thanh đã kéo
                      inactiveTrackColor: Colors.white24, // Màu nền thanh
                      thumbColor: Colors.white, // Màu cục tròn
                      trackHeight: 6.0,
                    ),
                    child: Slider(
                      value: pwmValue, 
                      min: 0, 
                      max: 100, 
                      // Kéo mượt, không dùng divisions
                      onChanged: (v) {
                        setState(() => pwmValue = v);
                      },
                      // Thả tay ra mới gửi MQTT (để đỡ spam server)
                      onChangeEnd: (v) {
                        print("Gửi PWM: ${v.toInt()}");
                        mqttHandler.publishMessage("home/control", '{"id": "${widget.deviceId}", "pwm": ${v.toInt()}}');
                      },
                    ),
                  ),
              ]),
      );
    });
  }
}