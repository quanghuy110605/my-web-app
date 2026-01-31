import 'package:flutter/material.dart';
import 'home_3d_screen.dart'; // File này phải OK thì mới hết lỗi
import 'device_list_screen.dart';
import 'schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAddingMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      body: IndexedStack(
        index: _currentIndex, 
        children: [
          // TAB 1: NHÀ 3D
          SmartHome3DPage(
            isAddingMode: _isAddingMode, 
            onAddComplete: () {
              setState(() {
                _isAddingMode = false;
              });
            }
          ),
          
          // TAB 2: THIẾT BỊ
          const DeviceListScreen(),
          
          // TAB 3: LỊCH TRÌNH
          const ScheduleScreen(),
        ]
      ),
      
      // NÚT THÊM
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
                      content: Text("Chạm vào tường để thêm!")
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
      
      // NAVIGATION BAR
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