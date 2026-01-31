import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';

class MqttHandler {
  // --- CẤU HÌNH ---
  String server = '192.168.1.10'; 
  final int port = 1883;
  final String topicControl = 'home/camera_san';

  late MqttServerClient client;

  // --- LOAD IP TỪ BỘ NHỚ ---
  Future<void> loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    server = prefs.getString('mqtt_ip') ?? '192.168.1.10';
  }

  // --- CẬP NHẬT IP MỚI ---
  Future<void> updateBrokerIP(String newIP) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_ip', newIP);
    
    server = newIP;
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }
    connect(); 
  }

  // --- KẾT NỐI ---
  Future<void> connect() async {
    if (server == '192.168.1.10') {
      await loadSavedIP();
    }

    client = MqttServerClient(
      server, 
      'app_user_${DateTime.now().millisecondsSinceEpoch}'
    );
    
    client.logging(on: false);
    client.keepAlivePeriod = 20;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_app')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      print('MQTT: Đang kết nối tới $server...');
      await client.connect();
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ MQTT: KẾT NỐI THÀNH CÔNG TỚI $server');
        client.subscribe(topicControl, MqttQos.atMostOnce);
        client.updates!.listen(_onMessageReceived);
      }
    } catch (e) {
      print('❌ MQTT Lỗi: $e');
      client.disconnect();
    }
  }

  // --- GỬI LỆNH ---
  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(
        topic, 
        MqttQos.atMostOnce, 
        builder.payload!
      );
    }
  }

  // --- NHẬN LỆNH ---
  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage?>>? c) {
    final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
    final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    try {
      final Map<String, dynamic> data = jsonDecode(pt);

      if (data.containsKey('details')) {
        final int carCount = data['details']['car'] ?? 0;
        final bool hasCar = carCount > 0;

        try {
          SmartDevice? garaDevice;
          try {
            garaDevice = deviceManager.devices.firstWhere(
              (d) => d.name == "Gara Ô tô"
            );
          } catch (e) { 
            garaDevice = null; 
          }

          if (garaDevice != null) {
            if (garaDevice.isOn != hasCar) {
              deviceManager.toggleDevice(garaDevice.id, hasCar);
            }
          } else if (hasCar) {
            // Tự động tạo Gara nếu chưa có
            print("Chưa có Gara, tự động tạo để hiện xe!");
            
            deviceManager.addDevice(
              "Gara Ô tô", 
              Icons.directions_car, 
              "0m 0m 0m", 
              "0m 1m 0m", 
              "Sân Vườn", 
              -1 // <--- QUAN TRỌNG: Pin -1
            );
            
            final newGara = deviceManager.devices.firstWhere(
              (d) => d.name == "Gara Ô tô"
            );
            deviceManager.toggleDevice(newGara.id, true);
          }
        } catch (e) { 
          print("Lỗi Gara: $e"); 
        }
      }
    } catch (e) { 
      print("Lỗi JSON: $e"); 
    }
  }
}

final mqttHandler = MqttHandler();