import 'package:flutter/material.dart';

class SmartDevice {
  final String id;
  String name;
  final IconData icon;
  bool isOn;
  Color color;
  double brightness;
  String position;
  String normal;
  final String room; // Lưu tên phòng
  final int pin;     // <--- THÊM BIẾN LƯU CHÂN GPIO

  SmartDevice({
    required this.id,
    required this.name,
    required this.icon,
    this.isOn = false,
    this.color = Colors.amber,
    this.brightness = 100.0,
    this.position = '0m 0m 0m',
    this.normal = '0m 1m 0m',
    this.room = 'Chưa rõ',
    this.pin = -1, // Mặc định -1 là chưa gán chân
  });
}

class DeviceManager extends ChangeNotifier {
  static final DeviceManager _instance = DeviceManager._internal();
  factory DeviceManager() => _instance;
  DeviceManager._internal();

  final List<SmartDevice> devices = [];

  SmartDevice getDevice(String id) {
    if (devices.isEmpty) {
      return SmartDevice(id: 'dummy', name: 'None', icon: Icons.error);
    }
    return devices.firstWhere((d) => d.id == id, orElse: () => devices[0]);
  }

  void toggleDevice(String id, bool value) {
    if (devices.isEmpty) return;
    getDevice(id).isOn = value;
    notifyListeners();
  }

  void changeColor(String id, Color newColor) {
    if (devices.isEmpty) return;
    getDevice(id).color = newColor;
    notifyListeners();
  }

  void changeBrightness(String id, double value) {
    if (devices.isEmpty) return;
    getDevice(id).brightness = value;
    notifyListeners();
  }

  // CẬP NHẬT HÀM ADD: Thêm tham số PIN
  void addDevice(String name, IconData icon, String position, String normal, String room, int pin) {
    final newId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    final newDevice = SmartDevice(
      id: newId,
      name: name,
      icon: icon,
      isOn: false,
      color: Colors.blueAccent, // Mặc định màu xanh, sau này sẽ chỉnh theo loại
      position: position,
      normal: normal,
      room: room,
      pin: pin, // Lưu chân GPIO vào thiết bị
    );
    devices.add(newDevice);
    notifyListeners();
  }
}

final deviceManager = DeviceManager();