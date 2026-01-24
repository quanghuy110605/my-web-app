import 'package:flutter/material.dart';
import 'smart_3d_viewer.dart'; // Import bộ xử lý 3D
import 'panels.dart';         // Import giao diện bảng điều khiển
import 'device_screens.dart'; // Import các màn hình thiết bị & lịch trình
import 'device_data.dart';    // Import dữ liệu thiết bị

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Home 3D',
      // Dùng theme tối cho toàn bộ App
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
      ),
      home: const MainScreen(),
    );
  }
}

// =============================================================================
// MÀN HÌNH CHÍNH (CHỨA THANH ĐIỀU HƯỚNG)
// =============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Tab hiện tại

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // IndexedStack giúp giữ trạng thái của trang 3D khi chuyển tab
      // (Không bị load lại mô hình gây giật lag)
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // TAB 0: TRANG CHÍNH (3D)
          SmartHome3DPage(),
          
          // TAB 1: THIẾT BỊ
          DeviceListScreen(),
          
          // TAB 2: LỊCH TRÌNH
          ScheduleScreen(),
        ],
      ),

      // THANH ĐIỀU HƯỚNG DƯỚI CÙNG
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.grey[900], // Màu nền hơi xám nhẹ để tách biệt
        selectedItemColor: Colors.amber,   // Màu khi chọn
        unselectedItemColor: Colors.grey,  // Màu khi không chọn
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chính',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_other_rounded),
            label: 'Thiết bị',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch trình',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TRANG 3D (ĐƯỢC TÁCH RA CHO GỌN)
// =============================================================================

class SmartHome3DPage extends StatelessWidget {
  const SmartHome3DPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin đèn từ bộ não để hiển thị màu ban đầu đúng
    final lightDevice = deviceManager.getDevice('light_1');

    return SmartHomeViewer(
      src: 'assets/Bambo_House.glb', 
      
      // Điều chỉnh độ cao bảng (-60.0 để mũi tên chỉ vào ĐỈNH giọt nước)
      yOffset: -60.0, 
      
      hotspots: [
        // --- HOTSPOT 1: ĐÈN TRẦN ---
        SmartHotspot(
          id: 'light_1', // ID này phải trùng với ID trong device_data.dart
          position: '-2.7m 1.2m 1.1m',
          color: lightDevice.color, // Lấy màu hiện tại
          svgIcon: SmartIcons.bulb, 
          
          // Gọi Widget bảng điều khiển từ panels.dart
          panelBuilder: (context, toggle3D, changeColor) => SmartLightPanel(
            onToggle3D: toggle3D,
            onChangeColor: changeColor,
          ),
        ),
        
        // Bạn có thể thêm các Hotspot khác (Tivi, Xe...) ở đây
        // Nhớ thêm ID tương ứng vào device_data.dart
      ],
    );
  }
}