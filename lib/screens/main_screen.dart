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

  // --- HÀM QUAN TRỌNG: CHỐNG TREO APP ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("📱 App đã quay trở lại -> Đợi 1.5s để ổn định đồ họa...");
      
      // Delay 1.5 giây để điện thoại vẽ xong nhà 3D rồi mới nối mạng
      // Giúp tránh việc CPU bị quá tải gây đơ máy
      Future.delayed(const Duration(milliseconds: 1500), () {
        print("🚀 Đã ổn định -> Bắt đầu kết nối lại MQTT");
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
            onAddComplete: () {
              setState(() {
                _isAddingMode = false;
              });
            }
          ),
          
          // Tab 2: Danh sách thiết bị
          const DeviceListScreen(),
          
          // Tab 3: Lịch trình
          const ScheduleScreen(),
        ]
      ),
      
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              heroTag: "btn_main", 
              backgroundColor: _isAddingMode ? Colors.red : Colors.blueAccent, 
              
              onPressed: () { 
                setState(() { 
                  _isAddingMode = !_isAddingMode; 
                }); 
                
                if (_isAddingMode) { 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Chạm vào tường/trần để thêm thiết bị!"),
                      duration: Duration(seconds: 2),
                    )
                  ); 
                } 
              }, 
              
              child: Icon(
                _isAddingMode ? Icons.close : Icons.add, 
                color: Colors.white
              )
            ) 
          : null,
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, 
        onTap: (index) => setState(() => _currentIndex = index), 
        
        backgroundColor: Colors.grey[900], 
        selectedItemColor: Colors.amber, 
        unselectedItemColor: Colors.grey, 
        type: BottomNavigationBarType.fixed, 
        
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Trang chính'
          ), 
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote), 
            label: 'Thiết bị'
          ), 
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), 
            label: 'Lịch trình'
          )
        ]
      ),
    );
  }
}