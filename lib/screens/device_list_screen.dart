import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/mqtt_service.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen đồng bộ
      appBar: AppBar(
        title: const Text("Quản lý thiết bị", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Ẩn nút back mặc định
      ),
      body: ListenableBuilder(
        listenable: deviceManager,
        builder: (context, _) {
          // --- BỘ LỌC QUAN TRỌNG ---
          // Chỉ lấy các thiết bị KHÔNG phải là Gara
          final devices = deviceManager.devices
              .where((d) => !d.name.contains("Gara")) // <--- LỌC BỎ XE Ô TÔ
              .toList();

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 60, color: Colors.grey[800]),
                  const SizedBox(height: 10),
                  const Text("Chưa có thiết bị nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return _buildDeviceItem(device);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeviceItem(SmartDevice device) {
    // Xác định màu sắc dựa trên trạng thái
    final isActive = device.isOn;
    final activeColor = device.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.5) : Colors.transparent,
          width: 1
        ),
        boxShadow: isActive ? [
          BoxShadow(color: activeColor.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)
        ] : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.2) : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Icon(
            device.icon,
            color: isActive ? activeColor : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            decoration: isActive ? null : TextDecoration.none
          ),
        ),
        subtitle: Text(
          "${device.room} • Pin D${device.pin}",
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isActive,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[800],
            onChanged: (val) {
              // 1. Cập nhật UI
              deviceManager.toggleDevice(device.id, val);
              
              // 2. Gửi lệnh MQTT điều khiển thật
              // Format JSON: {"action":"control", "pin": 2, "state": 1}
              Map<String, dynamic> cmd = {
                "action": "control",
                "pin": device.pin,
                "state": val ? 1 : 0
              };
              mqttHandler.publishMessage("home/control", jsonEncode(cmd));
            },
          ),
        ),
      ),
    );
  }
}