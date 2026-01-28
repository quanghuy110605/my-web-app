import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart'; 
import 'device_data.dart'; 

class MqttHandler {
  // --- CẤU HÌNH CHO MÁY THẬT ---
  // Thay 10.0.2.2 bằng IP LAN máy tính của bạn
  final String server = '192.168.100.103'; 
  
  final int port = 1883;
  final String topic = 'home/camera_san';

  late MqttServerClient client;

  Future<void> connect() async {
    // Tạo client ID ngẫu nhiên để không bị trùng
    client = MqttServerClient(server, 'android_real_${DateTime.now().millisecondsSinceEpoch}');
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_real_device')
        .startClean() 
        .withWillQos(MqttQos.atLeastOnce);
    
    client.connectionMessage = connMessage;

    try {
      if (kDebugMode) print('MQTT: Đang kết nối đến $server...');
      await client.connect();
    } on NoConnectionException catch (e) {
      if (kDebugMode) print('MQTT: Lỗi kết nối - $e');
      client.disconnect();
    } on SocketException catch (e) {
      if (kDebugMode) print('MQTT: Lỗi Socket (Sai IP hoặc Firewall chặn) - $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      if (kDebugMode) print('MQTT: Đã kết nối thành công!');
      client.subscribe(topic, MqttQos.atMostOnce);
      client.updates!.listen(_onMessageReceived);
    } else {
      if (kDebugMode) print('MQTT: Kết nối thất bại - ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage?>>? c) {
    final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
    final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    if (kDebugMode) print('MQTT Nhận được: $pt');

    try {
      final Map<String, dynamic> data = jsonDecode(pt);
      if (data.containsKey('details')) {
        final int carCount = data['details']['car'] ?? 0;
        
        try {
          // Tìm thiết bị Gara để bật/tắt
          final garaDevice = deviceManager.devices.firstWhere(
            (d) => d.name == "Gara Ô tô" || d.name == "Gara", 
            orElse: () => throw Exception("Không tìm thấy thiết bị Gara"),
          );

          bool shouldBeOn = carCount > 0;
          if (garaDevice.isOn != shouldBeOn) {
            print("MQTT: Phát hiện xe ($carCount) -> Gara ${shouldBeOn ? 'ON' : 'OFF'}");
            deviceManager.toggleDevice(garaDevice.id, shouldBeOn);
          }
        } catch (e) {
          print("Lỗi logic cập nhật Gara: $e");
        }
      }
    } catch (e) {
      print("Lỗi parse JSON MQTT: $e");
    }
  }

  void onDisconnected() {
    if (kDebugMode) print('MQTT: Đã ngắt kết nối');
  }
}