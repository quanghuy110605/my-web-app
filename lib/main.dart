import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'services/mqtt_service.dart';
// Đã xóa import device_model vì không cần dùng ở đây nữa

void main() {
  runApp(const MyApp());
  _initMqtt();
}

void _initMqtt() async {
  // ĐÃ XÓA: Đoạn code kiểm tra và thêm "Gara Ô tô" tự động
  
  // Chỉ còn lại việc kết nối MQTT
  await mqttHandler.connect();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, 
        primaryColor: Colors.amber
      ), 
      home: const MainScreen(),
    ); 
  }
}
