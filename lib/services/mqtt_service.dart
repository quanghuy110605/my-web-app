import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';
import '../models/notification_model.dart'; 

class MqttHandler {
  String server = '192.168.1.10'; 
  final int port = 1883;
  final String topicControl = 'home/camera_san';

  // Dùng dấu ? để tránh lỗi Crash "LateInitializationError"
  MqttServerClient? client;

  // Khởi tạo là thử kết nối luôn
  MqttHandler() {
    connect();
  }

  Future<void> loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    server = prefs.getString('mqtt_ip') ?? '192.168.1.10';
  }

  Future<bool> updateBrokerIP(String newIP) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_ip', newIP);
    server = newIP;
    
    // Ngắt an toàn
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      client?.disconnect();
    }
    return await connect(); 
  }

  Future<bool> connect() async {
    if (server == '192.168.1.10') await loadSavedIP();

    // Nếu đã kết nối rồi thì thôi
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      return true;
    }

    client = MqttServerClient(server, 'app_user_${DateTime.now().millisecondsSinceEpoch}');
    
    // --- CẤU HÌNH GIỮ KẾT NỐI LIÊN TỤC ---
    client!.logging(on: false);
    client!.keepAlivePeriod = 60; // Tăng lên 60s để đỡ phải ping nhiều
    client!.connectTimeoutPeriod = 5000;
    
    // QUAN TRỌNG: Tự động kết nối lại khi bị ngắt
    client!.autoReconnect = true;
    client!.resubscribeOnAutoReconnect = true; 

    // Callback lắng nghe
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;
    client!.onAutoReconnect = _onAutoReconnect;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_app')
        .startClean() // False để giữ session nếu được
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      print('MQTT: Đang kết nối tới $server...');
      await client!.connect();
      
      if (client!.connectionStatus!.state == MqttConnectionState.connected) {
        // Đăng ký topic ngay khi nối thành công
        _subscribeTopic();
        return true; 
      } else {
        return false; 
      }
    } catch (e) {
      print('❌ MQTT Lỗi: $e');
      client?.disconnect(); 
      return false; 
    }
  }

  void _subscribeTopic() {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print("📡 Đang đăng ký topic: $topicControl");
      client!.subscribe(topicControl, MqttQos.atMostOnce);
      client!.updates!.listen(_onMessageReceived);
    }
  }

  // --- CÁC HÀM CALLBACK TRẠNG THÁI ---
  void _onConnected() {
    print('✅ MQTT: Đã kết nối!');
  }

  void _onDisconnected() {
    print('⚠️ MQTT: Mất kết nối! Đang chờ tự động nối lại...');
  }

  void _onAutoReconnect() {
    print('🔄 MQTT: Đang tự động kết nối lại...');
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      client?.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    } else {
      print("Chưa kết nối, bỏ qua lệnh: $message");
    }
  }

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
            garaDevice = deviceManager.devices.firstWhere((d) => d.name == "Gara Ô tô");
          } catch (e) { garaDevice = null; }

          if (garaDevice != null) {
            if (garaDevice.isOn != hasCar) {
               deviceManager.toggleDevice(garaDevice.id, hasCar);
               if (hasCar) {
                 notificationManager.addNotification("Nhà xe", "Phát hiện 1 xe ô tô trong nhà để xe", type: NotiType.alert);
               } else {
                 notificationManager.addNotification("Nhà xe", "Xe đã rời khỏi nhà để xe", type: NotiType.info);
               }
            }
          } else if (hasCar) {
            print("Auto-create Gara");
            deviceManager.addDevice("Gara Ô tô", Icons.directions_car, "0m 0m 0m", "0m 1m 0m", "Sân Vườn", -1);
            final newGara = deviceManager.devices.firstWhere((d) => d.name == "Gara Ô tô");
            deviceManager.toggleDevice(newGara.id, true);
            notificationManager.addNotification("Nhà xe", "Phát hiện 1 xe ô tô trong nhà để xe", type: NotiType.alert);
          }
        } catch (e) { print("Lỗi Gara: $e"); }
      }
    } catch (e) { print("Lỗi JSON: $e"); }
  }
}

final mqttHandler = MqttHandler();