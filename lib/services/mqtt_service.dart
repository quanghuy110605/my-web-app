import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart'; 
import '../models/device_model.dart'; 

class MqttHandler {
  final String server = '100.95.72.109'; 
  final int port = 1883;
  final String topicControl = 'home/camera_san'; 

  late MqttServerClient client;

  Future<void> connect() async {
    client = MqttServerClient(server, 'app_check_${DateTime.now().millisecondsSinceEpoch}');
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_app')
        .startClean() 
        .withWillQos(MqttQos.atLeastOnce);
    
    client.connectionMessage = connMessage;

    try {
      print('MQTT: Đang kết nối tới $server...'); // <--- THÊM DÒNG NÀY
      await client.connect();
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ MQTT: ĐÃ KẾT NỐI THÀNH CÔNG!'); // <--- THÊM DÒNG NÀY
        client.subscribe(topicControl, MqttQos.atMostOnce);
        client.updates!.listen(_onMessageReceived);
      }
    } catch (e) {
      print('❌ MQTT Lỗi: $e'); // <--- THÊM DÒNG NÀY
      client.disconnect();
    }
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
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
          } catch (e) {
            garaDevice = null;
          }

          if (garaDevice != null) {
            if (garaDevice.isOn != hasCar) {
               deviceManager.toggleDevice(garaDevice.id, hasCar);
            }
          } else if (hasCar) {
            // --- SỬA LỖI Ở DÒNG DƯỚI ĐÂY (Thêm tham số "Gara") ---
            print("Chưa có Gara, tự động tạo để hiện xe!");
            deviceManager.addDevice(
              "Gara Ô tô", 
              Icons.directions_car, 
              "0m 0m 0m", 
              "0m 1m 0m",
              "Sân Vườn" // <--- ĐÃ THÊM TÊN PHÒNG VÀO ĐÂY ĐỂ SỬA LỖI
            );
            
            final newGara = deviceManager.devices.firstWhere((d) => d.name == "Gara Ô tô");
            deviceManager.toggleDevice(newGara.id, true);
          }
        } catch (e) {
          print("Lỗi logic Gara: $e");
        }
      }
    } catch (e) {
      print("Lỗi JSON: $e");
    }
  }
}

final mqttHandler = MqttHandler();