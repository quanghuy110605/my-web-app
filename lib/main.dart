import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'smart_3d_viewer.dart';
import 'panels.dart';
import 'device_screens.dart';
import 'device_data.dart';
import 'mqtt_handler.dart'; // Import file xử lý MQTT

void main() {
  runApp(const MyApp());
  
  // KHỞI ĐỘNG KẾT NỐI MQTT NGAY KHI APP CHẠY
  _initMqtt();
}

// Hàm khởi tạo MQTT và thêm thiết bị mẫu (nếu cần)
void _initMqtt() async {
  // Thêm sẵn Gara vào danh sách nếu chưa có (để MQTT có cái mà điều khiển)
  // Bạn có thể xóa dòng này nếu muốn tự tay thêm Gara
  if (deviceManager.devices.where((d) => d.name == "Gara Ô tô").isEmpty) {
     deviceManager.addDevice("Gara Ô tô", Icons.directions_car, "0m 0m 0m", "0m 1m 0m");
  }

  final mqtt = MqttHandler();
  await mqtt.connect();
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
      home: const MainScreen()
    ); 
  }
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
          // Truyền callback để tắt chế độ thêm khi xong
          SmartHome3DPage(
            isAddingMode: _isAddingMode, 
            onAddComplete: () => setState(() => _isAddingMode = false)
          ),
          const DeviceListScreen(),
          const ScheduleScreen(),
      ]),
      
      // Nút Floating Action Button chỉ hiện ở trang chủ (index 0)
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        backgroundColor: _isAddingMode ? Colors.red : Colors.blueAccent, 
        onPressed: () { 
          setState(() { _isAddingMode = !_isAddingMode; }); 
          if (_isAddingMode) { 
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Chạm vào trần/tường để thêm thiết bị!"))
            ); 
          } 
        }, 
        child: Icon(_isAddingMode ? Icons.close : Icons.add, color: Colors.white)
      ) : null,
      
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

// Class định nghĩa loại thiết bị trong bảng chọn
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
  
  // --- DANH SÁCH CÁC LOẠI THIẾT BỊ CÓ THỂ THÊM ---
  final List<DeviceType> availableTypes = [
    DeviceType("Đèn", Icons.lightbulb, Colors.amber),
    DeviceType("Quạt", Icons.cyclone, Colors.teal),
    DeviceType("Máy sưởi", Icons.thermostat, Colors.deepOrange),
    DeviceType("Rèm cửa", Icons.view_headline, Colors.purpleAccent),
    
    // --- CỬA VÀ GARA ---
    DeviceType("Cửa Chính", Icons.meeting_room, Colors.brown), 
    DeviceType("Gara Ô tô", Icons.directions_car, Colors.blueGrey), 
    
    DeviceType("Điều hòa", Icons.ac_unit, Colors.cyan),
  ];

  // Hàm xử lý khi người dùng chạm vào mô hình 3D
  void _handleModelTap(String position, String normal) {
    if (!widget.isAddingMode) return;
    
    // Hiển thị bảng chọn thiết bị từ dưới lên
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.grey[900], 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20), 
          height: 350, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const Text("Chọn loại thiết bị", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: 15, 
                    mainAxisSpacing: 15, 
                    childAspectRatio: 1.0
                  ), 
                  itemCount: availableTypes.length, 
                  itemBuilder: (context, index) {
                    final type = availableTypes[index];
                    return InkWell(
                      onTap: () {
                        // Thêm thiết bị vào DeviceManager
                        deviceManager.addDevice(type.name, type.icon, position, normal);
                        
                        Navigator.pop(ctx); // Đóng bảng chọn
                        widget.onAddComplete(); // Tắt chế độ adding
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Đã thêm ${type.name} thành công!"))
                        );
                      }, 
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800], 
                          borderRadius: BorderRadius.circular(12), 
                          border: Border.all(color: Colors.white10)
                        ), 
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Icon(type.icon, color: type.color, size: 32), 
                            const SizedBox(height: 8), 
                            Text(type.name, style: const TextStyle(color: Colors.white70, fontSize: 12))
                          ]
                        )
                      )
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  // --- LOGIC CHUYỂN ĐỔI ICON (MỞ/ĐÓNG, CÓ XE/KHÔNG XE) ---
  String _getIconName(SmartDevice device) {
    // Cửa: Mở / Đóng
    if (device.icon.codePoint == Icons.meeting_room.codePoint) {
      return device.isOn ? SmartIcons.doorOpen : SmartIcons.doorClosed;
    }
    // Gara: Có xe / Trống
    if (device.icon.codePoint == Icons.directions_car.codePoint) {
      return device.isOn ? SmartIcons.car : SmartIcons.garageEmpty;
    }
    
    // Các thiết bị khác
    if (device.icon.codePoint == Icons.cyclone.codePoint) return SmartIcons.fan;
    if (device.icon.codePoint == Icons.thermostat.codePoint) return SmartIcons.heater;
    if (device.icon.codePoint == Icons.view_headline.codePoint) return SmartIcons.curtain;
    if (device.icon.codePoint == Icons.ac_unit.codePoint) return SmartIcons.ac;
    
    return SmartIcons.bulb; // Mặc định là bóng đèn
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deviceManager, 
      builder: (context, _) {
        // Chuyển danh sách SmartDevice thành danh sách Hotspot 3D
        final myHotspots = deviceManager.devices.map((device) {
          
          String iconName = _getIconName(device);
          
          return SmartHotspot(
            id: device.id, 
            position: device.position, 
            normal: device.normal, 
            color: device.color, 
            iconName: iconName,
            panelBuilder: (context, toggle3D, changeColor) => SmartLightPanel(
              deviceId: device.id, 
              onToggle3D: toggle3D, 
              onChangeColor: changeColor
            )
          );
        }).toList();

        return Stack(children: [
            // Màn hình 3D chính
            SmartHomeViewer(
              src: 'assets/Bambo_House.glb', 
              yOffset: -60.0, 
              hotspots: myHotspots, 
              onModelTap: _handleModelTap
            ),
            
            // Lớp phủ hiệu ứng khi đang ở chế độ thêm (Đã bỏ comment để test overlay)
            // Nếu Web bị lỗi không click được thì hãy comment dòng này lại
            if (widget.isAddingMode) const Positioned.fill(child: AddingModeOverlay()),
        ]);
      }
    );
  }
}

// --- HIỆU ỨNG VIỀN MÀU KHI Ở CHẾ ĐỘ THÊM THIẾT BỊ ---
class AddingModeOverlay extends StatefulWidget {
  const AddingModeOverlay({super.key});
  @override State<AddingModeOverlay> createState() => _AddingModeOverlayState();
}

class _AddingModeOverlayState extends State<AddingModeOverlay> with TickerProviderStateMixin {
  late AnimationController _rippleController; 
  late AnimationController _borderController; 
  bool _rippleFinished = false;
  
  @override 
  void initState() { 
    super.initState(); 
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); 
    _borderController = AnimationController(vsync: this, duration: const Duration(seconds: 2)); 
    _rippleController.forward(); 
    _rippleController.addStatusListener((status) { 
      if (status == AnimationStatus.completed) { 
        setState(() => _rippleFinished = true); 
        _borderController.repeat(); 
      } 
    }); 
  }
  
  @override 
  void dispose() { 
    _rippleController.dispose(); 
    _borderController.dispose(); 
    super.dispose(); 
  }
  
  @override 
  Widget build(BuildContext context) { 
    return IgnorePointer( // Cho phép click xuyên qua lớp phủ
      child: AnimatedBuilder(
        animation: Listenable.merge([_rippleController, _borderController]), 
        builder: (context, child) { 
          return CustomPaint(
            painter: _SequencePainter(
              rippleValue: _rippleController.value, 
              borderValue: _borderController.value, 
              isRippleFinished: _rippleFinished
            ), 
            size: Size.infinite
          ); 
        },
      )
    ); 
  }
}

class _SequencePainter extends CustomPainter {
  final double rippleValue; 
  final double borderValue; 
  final bool isRippleFinished;
  
  _SequencePainter({required this.rippleValue, required this.borderValue, required this.isRippleFinished});
  
  @override 
  void paint(Canvas canvas, Size size) { 
    final center = Offset(size.width / 2, size.height / 2); 
    final rect = Rect.fromLTWH(0, 0, size.width, size.height); 
    
    // Vẽ viền RGB chạy vòng quanh màn hình
    if (isRippleFinished) { 
      final Paint borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..shader = SweepGradient(
          colors: const [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red], 
          transform: GradientRotation(borderValue * 2 * math.pi)
        ).createShader(rect); 
      canvas.drawRect(rect, borderPaint); 
    } 
    
    // Vẽ vòng tròn Ripple lan ra từ giữa (lúc mới bật chế độ thêm)
    if (!isRippleFinished) { 
      double maxRadius = math.max(size.width, size.height); 
      double currentRadius = maxRadius * rippleValue; 
      double opacity = (1.0 - rippleValue).clamp(0.0, 1.0); 
      
      final Paint ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = Colors.cyanAccent.withValues(alpha: opacity * 0.3); 
      canvas.drawCircle(center, currentRadius, ripplePaint); 
      
      final Paint corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..color = Colors.white.withValues(alpha: opacity * 0.2); 
      canvas.drawCircle(center, currentRadius, corePaint); 
    } 
  }
  
  @override 
  bool shouldRepaint(covariant _SequencePainter oldDelegate) => true;
}