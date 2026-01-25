import 'package:flutter/material.dart';
import 'smart_3d_viewer.dart';
import 'panels.dart';
import 'device_screens.dart';
import 'device_data.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) { return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black, primaryColor: Colors.amber), home: const MainScreen()); }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAddingMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _currentIndex, children: [
          SmartHome3DPage(isAddingMode: _isAddingMode, onAddComplete: () => setState(() => _isAddingMode = false)),
          const DeviceListScreen(),
          const ScheduleScreen(),
      ]),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(backgroundColor: _isAddingMode ? Colors.red : Colors.blueAccent, onPressed: () { setState(() { _isAddingMode = !_isAddingMode; }); if (_isAddingMode) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chạm vào trần/tường trên mô hình 3D để thêm thiết bị!"), duration: Duration(seconds: 3))); } }, child: Icon(_isAddingMode ? Icons.close : Icons.add, color: Colors.white)) : null,
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index), backgroundColor: Colors.grey[900], selectedItemColor: Colors.amber, unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed, items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chính'), BottomNavigationBarItem(icon: Icon(Icons.settings_remote), label: 'Thiết bị'), BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch trình')]),
    );
  }
}

class DeviceType {
  final String name; final IconData icon; final Color color;
  DeviceType(this.name, this.icon, this.color);
}

class SmartHome3DPage extends StatefulWidget {
  final bool isAddingMode; final VoidCallback onAddComplete;
  const SmartHome3DPage({super.key, required this.isAddingMode, required this.onAddComplete});
  @override State<SmartHome3DPage> createState() => _SmartHome3DPageState();
}

class _SmartHome3DPageState extends State<SmartHome3DPage> {

  // --- DANH SÁCH ICON CHUẨN ĐỒNG BỘ ---
  final List<DeviceType> availableTypes = [
    DeviceType("Đèn", Icons.lightbulb, Colors.amber),
    
    // SỬA: Dùng icon 'cyclone' (Hình xoáy). 
    // Bên Web cũng có icon tên là 'cyclone' -> Giống nhau 100%.
    DeviceType("Quạt", Icons.cyclone, Colors.teal), 
    
    DeviceType("Máy sưởi", Icons.thermostat, Colors.deepOrange), // Web: 'thermostat'
    DeviceType("Rèm cửa", Icons.view_headline, Colors.purpleAccent), // Web: 'view_headline'
    DeviceType("Cửa", Icons.meeting_room, Colors.brown), // Web: 'meeting_room'
    DeviceType("Điều hòa", Icons.ac_unit, Colors.cyan), // Web: 'ac_unit'
  ];

  void _handleModelTap(String position, String normal) {
    if (!widget.isAddingMode) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.grey[900], shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
        return Container(padding: const EdgeInsets.all(20), height: 350, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Chọn loại thiết bị", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.0), itemCount: availableTypes.length, itemBuilder: (context, index) {
                    final type = availableTypes[index];
                    return InkWell(onTap: () {
                        deviceManager.addDevice(type.name, type.icon, position, normal);
                        Navigator.pop(ctx); widget.onAddComplete();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm ${type.name} thành công!")));
                      }, child: Container(decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(type.icon, color: type.color, size: 32), const SizedBox(height: 8), Text(type.name, style: const TextStyle(color: Colors.white70, fontSize: 12))])));
                  }))]));
      });
  }

  // --- MAP TÊN ICON TRÙNG KHỚP HOÀN TOÀN ---
  String _getIconName(IconData icon) {
    if (icon.codePoint == Icons.cyclone.codePoint) return 'cyclone'; // Trả về đúng tên cyclone cho Web
    if (icon.codePoint == Icons.thermostat.codePoint) return 'thermostat';
    if (icon.codePoint == Icons.view_headline.codePoint) return 'view_headline';
    if (icon.codePoint == Icons.meeting_room.codePoint) return 'meeting_room';
    if (icon.codePoint == Icons.ac_unit.codePoint) return 'ac_unit';
    
    // Mặc định là đèn (lightbulb)
    return 'lightbulb'; 
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: deviceManager, builder: (context, _) {
        final myHotspots = deviceManager.devices.map((device) {
          
          String iconName = _getIconName(device.icon);
          
          return SmartHotspot(
            id: device.id, 
            position: device.position, 
            normal: device.normal, 
            color: device.color, 
            
            iconName: iconName, // Truyền tên icon chuẩn sang 3D Viewer
            
            panelBuilder: (context, toggle3D, changeColor) => SmartLightPanel(
              deviceId: device.id, 
              onToggle3D: toggle3D, 
              onChangeColor: changeColor
            )
          );
        }).toList();

        return Stack(children: [
            SmartHomeViewer(src: 'assets/Bambo_House.glb', yOffset: -60.0, hotspots: myHotspots, onModelTap: _handleModelTap), 
            if (widget.isAddingMode) Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 4)))))
        ]);
    });
  }
}