import 'package:flutter/material.dart';

// Model cho một thiết bị
class SmartDevice {
  final String id;
  final String name;
  final IconData icon;
  bool isOn;
  Color color;

  SmartDevice({
    required this.id,
    required this.name,
    required this.icon,
    this.isOn = false,
    this.color = Colors.amber,
  });
}

// Bộ quản lý dữ liệu (ChangeNotifier)
class DeviceManager extends ChangeNotifier {
  // Singleton (để truy cập từ mọi nơi dễ dàng)
  static final DeviceManager _instance = DeviceManager._internal();
  factory DeviceManager() => _instance;
  DeviceManager._internal();

  // DANH SÁCH THIẾT BỊ DUY NHẤT CỦA APP
  final List<SmartDevice> devices = [
    SmartDevice(id: 'light_1', name: 'Đèn Trần', icon: Icons.lightbulb, isOn: true, color: Colors.amber),
    // Bạn có thể thêm thiết bị khác vào đây nếu muốn, ví dụ:
    // SmartDevice(id: 'tv_1', name: 'Tivi', icon: Icons.tv, isOn: false, color: Colors.blue),
  ];

  // Lấy thiết bị theo ID
  SmartDevice getDevice(String id) {
    return devices.firstWhere((d) => d.id == id, orElse: () => devices[0]);
  }

  // Hàm cập nhật trạng thái Bật/Tắt
  void toggleDevice(String id, bool value) {
    final device = getDevice(id);
    device.isOn = value;
    notifyListeners(); // Báo cho toàn bộ App cập nhật giao diện
  }

  // Hàm cập nhật Màu sắc
  void changeColor(String id, Color newColor) {
    final device = getDevice(id);
    device.color = newColor;
    notifyListeners(); // Báo cho toàn bộ App cập nhật giao diện
  }
}

// Biến toàn cục để dùng nhanh
final deviceManager = DeviceManager();