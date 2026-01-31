import 'package:flutter/material.dart';
import 'home_3d_screen.dart';
import 'device_list_screen.dart';
import 'schedule_screen.dart';
import '../services/mqtt_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isAddingMode = false;
  
  // BIẾN QUAN TRỌNG: Kiểm soát việc ẩn hiện nút (+) khi đang vẽ Map
  bool _hideFab = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Tự động kết nối lại MQTT khi quay lại app (có delay để tránh đơ máy)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 1500), () {
         mqttHandler.connect();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      body: IndexedStack(
        index: _currentIndex, 
        children: [
          // Tab 1: Nhà 3D
          SmartHome3DPage(
            isAddingMode: _isAddingMode, 
            onAddComplete: () => setState(() => _isAddingMode = false),
            
            // --- KẾT NỐI VỚI CHẾ ĐỘ VẼ MAP ---
            // Khi bên kia báo true (đang vẽ) -> Ẩn nút FAB
            // Khi bên kia báo false (thoát) -> Hiện nút FAB
            onMapModeChanged: (isMapMode) {
              setState(() {
                _hideFab = isMapMode; 
                // Nếu đang bật chế độ thêm thiết bị mà chuyển sang vẽ Map thì tắt luôn
                if (isMapMode) _isAddingMode = false; 
              });
            },
          ),
          
          // Tab 2: Danh sách thiết bị
          const DeviceListScreen(),
          
          // Tab 3: Lịch trình
          const ScheduleScreen(),
        ]
      ),
      
      // LOGIC ẨN HIỆN NÚT (+):
      // Chỉ hiện khi: (Đang ở Tab Home) VÀ (Không đang vẽ Map)
      floatingActionButton: (_currentIndex == 0 && !_hideFab) 
          ? FloatingActionButton(
              heroTag: "btn_main", 
              backgroundColor: _isAddingMode ? Colors.red : Colors.blueAccent, 
              onPressed: () { 
                setState(() => _isAddingMode = !_isAddingMode); 
                if (_isAddingMode) { 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chạm vào tường để thêm thiết bị!"))); 
                } 
              }, 
              child: Icon(_isAddingMode ? Icons.close : Icons.add, color: Colors.white)
            ) 
          : null, // Trả về null để ẩn nút đi
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, 
        onTap: (index) => setState(() => _currentIndex = index), 
        backgroundColor: Colors.grey[900], 
        selectedItemColor: Colors.amber, 
        unselectedItemColor: Colors.grey, 
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chính'), 
          BottomNavigationBarItem(icon: Icon(Icons.settings_remote), label: 'Thiết bị'), 
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch trình')
        ]
      ),
    );
  }
}