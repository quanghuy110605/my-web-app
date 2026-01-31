import 'package:flutter/material.dart';
import '../models/device_model.dart'; 

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Danh sách thiết bị"), backgroundColor: Colors.black, elevation: 0),
      
      body: ListenableBuilder(
        listenable: deviceManager, 
        builder: (context, _) {
          final devices = deviceManager.devices;
          if (devices.isEmpty) {
            return const Center(child: Text("Chưa có thiết bị nào", style: TextStyle(color: Colors.white54)));
          }

          // 1. GOM NHÓM THIẾT BỊ THEO PHÒNG
          Map<String, List<SmartDevice>> groupedDevices = {};
          for (var d in devices) {
             if (!groupedDevices.containsKey(d.room)) {
               groupedDevices[d.room] = [];
             }
             groupedDevices[d.room]!.add(d);
          }

          // 2. HIỂN THỊ DANH SÁCH THEO NHÓM
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedDevices.length,
            itemBuilder: (context, index) {
              String roomName = groupedDevices.keys.elementAt(index);
              List<SmartDevice> roomDevices = groupedDevices[roomName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề phòng
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.meeting_room, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text("${roomDevices.length} thiết bị", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),

                  // Danh sách thiết bị trong phòng đó
                  ...roomDevices.map((device) {
                    return Card(
                      color: Colors.grey[900], 
                      margin: const EdgeInsets.only(bottom: 12), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10), 
                          decoration: BoxDecoration(color: device.isOn ? device.color.withOpacity(0.2) : Colors.white10, shape: BoxShape.circle), 
                          child: Icon(device.icon, color: device.isOn ? device.color : Colors.grey)
                        ),
                        title: Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        // Hiển thị thêm thông tin PIN
                        subtitle: Text(
                          "Pin: D${device.pin != -1 ? device.pin : 'N/A'} • ${device.isOn ? "Đang bật" : "Đang tắt"}", 
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)
                        ),
                        trailing: Switch(
                          value: device.isOn, 
                          activeColor: Colors.white, 
                          activeTrackColor: device.color, 
                          inactiveTrackColor: Colors.grey[800], 
                          onChanged: (val) { deviceManager.toggleDevice(device.id, val); }
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10), // Khoảng cách giữa các phòng
                  Divider(color: Colors.grey[800]), // Đường kẻ ngăn cách
                ],
              );
            },
          );
        }
      ),
    );
  }
}