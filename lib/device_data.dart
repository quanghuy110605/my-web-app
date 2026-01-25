import 'package:flutter/material.dart';

class SmartDevice {
  final String id;
  String name;
  final IconData icon;
  bool isOn;
  Color color;
  String position;
  String normal;

  SmartDevice({
    required this.id,
    required this.name,
    required this.icon,
    this.isOn = false,
    this.color = Colors.amber,
    this.position = '0m 0m 0m',
    this.normal = '0m 1m 0m',
  });
}

class DeviceManager extends ChangeNotifier {
  static final DeviceManager _instance = DeviceManager._internal();
  factory DeviceManager() => _instance;
  DeviceManager._internal();

  // Dữ liệu mẫu
  final List<SmartDevice> devices = [
    SmartDevice(
      id: 'light_1',
      name: 'Đèn Trần',
      icon: Icons.lightbulb, // Icon chuẩn
      isOn: true,
      color: Colors.amber,
      position: '-2.7m 1.2m 1.1m',
    ),
  ];

  SmartDevice getDevice(String id) {
    return devices.firstWhere((d) => d.id == id, orElse: () => devices[0]);
  }

  void toggleDevice(String id, bool value) {
    getDevice(id).isOn = value;
    notifyListeners();
  }

  void changeColor(String id, Color newColor) {
    getDevice(id).color = newColor;
    notifyListeners();
  }

  void addDevice(String name, IconData icon, String position, String normal) {
    final newId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    final newDevice = SmartDevice(
      id: newId,
      name: name,
      icon: icon,
      isOn: false,
      color: Colors.blueAccent,
      position: position,
      normal: normal,
    );
    devices.add(newDevice);
    notifyListeners();
  }
}

final deviceManager = DeviceManager();