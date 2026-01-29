import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../glass_panel.dart';

class SimplePanel extends StatelessWidget {
  final String deviceId;
  final Function(bool) onToggle3D;
  final String labelOn;
  final String labelOff;

  const SimplePanel({
    super.key, 
    required this.deviceId, 
    required this.onToggle3D,
    this.labelOn = "Đang Bật",
    this.labelOff = "Đang Tắt",
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deviceManager,
      builder: (context, _) {
        final device = deviceManager.getDevice(deviceId);
        return BasePanel(
          icon: device.icon,
          color: device.color,
          title: device.name,
          room: device.room, // <--- Truyền tên phòng
          isOn: device.isOn,
          onToggle: (v) {
            deviceManager.toggleDevice(deviceId, v);
            onToggle3D(v);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: device.isOn ? device.color.withOpacity(0.1) : Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24)
            ),
            child: Text(
              device.isOn ? labelOn : labelOff,
              style: TextStyle(
                color: device.isOn ? device.color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    );
  }
}