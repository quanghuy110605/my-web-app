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

  // FIX: Để danh sách rỗng ban đầu (Xóa bóng đèn mẫu)
  final List<SmartDevice> devices = [];

  // FIX: Sửa hàm getDevice để không bị lỗi khi danh sách rỗng
  SmartDevice getDevice(String id) {
    if (devices.isEmpty) {
      // Trả về thiết bị ảo để tránh crash app nếu lỡ gọi
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