import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../widgets/smart_3d_viewer.dart';
import '../widgets/glass_panel.dart';
// Import các panel
import '../widgets/panels/light_panel.dart';
import '../widgets/panels/fan_panel.dart';
import '../widgets/panels/ac_panel.dart';
import '../widgets/panels/simple_panel.dart';

import '../models/device_model.dart';
import '../services/mqtt_service.dart';

class DeviceType { 
  final String name; 
  final IconData icon; 
  final Color color; 
  DeviceType(this.name, this.icon, this.color); 
}

class SmartHome3DPage extends StatefulWidget {
  final bool isAddingMode; 
  final VoidCallback onAddComplete;
  const SmartHome3DPage({super.key, required this.isAddingMode, required this.onAddComplete});
  @override State<SmartHome3DPage> createState() => _SmartHome3DPageState();
}

class _SmartHome3DPageState extends State<SmartHome3DPage> {
  final List<DeviceType> availableTypes = [
    DeviceType("Đèn", Icons.lightbulb, Colors.amber),
    DeviceType("Quạt", Icons.cyclone, Colors.teal),
    DeviceType("Máy sưởi", Icons.thermostat, Colors.red), 
    DeviceType("Rèm cửa", Icons.view_headline, Colors.purpleAccent),
    DeviceType("Cửa Chính", Icons.meeting_room, Colors.brown), 
    DeviceType("Điều hòa", Icons.ac_unit, Colors.cyan),
  ];

  final List<String> rooms = ["Phòng Khách", "Phòng Ngủ", "Nhà Bếp", "Sân Vườn", "WC"];
  String selectedRoom = "Phòng Khách";

  // --- HÀM HIỂN THỊ BẢNG THÊM THIẾT BỊ (STYLE TRẮNG MỜ) ---
  void _handleModelTap(String position, String normal) {
    if (!widget.isAddingMode) return;
    
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // HIỆU ỨNG KÍNH MỜ MÀU TRẮNG (GIỐNG BẢNG ĐIỀU KHIỂN)
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  height: 480, 
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    // MÀU TRẮNG MỜ (White Opacity)
                    color: Colors.white.withOpacity(0.85), 
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      // Thanh gạch ngang (Màu xám vì nền trắng)
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),

                      // Tiêu đề (Màu đen)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Thêm thiết bị mới", style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.black54))
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      // --- MENU CHỌN PHÒNG ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white, // Nền trắng đặc
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedRoom,
                                dropdownColor: Colors.white, // Menu xổ xuống màu trắng
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                                items: rooms.map((String value) {
                                  return DropdownMenuItem<String>(value: value, child: Text(value));
                                }).toList(),
                                onChanged: (newValue) => setModalState(() => selectedRoom = newValue!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- LƯỚI THIẾT BỊ ---
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, 
                            crossAxisSpacing: 15, 
                            mainAxisSpacing: 15, 
                            childAspectRatio: 0.85
                          ), 
                          itemCount: availableTypes.length, 
                          itemBuilder: (context, index) {
                            final type = availableTypes[index];
                            return InkWell(
                              onTap: () {
                                deviceManager.addDevice(type.name, type.icon, position, normal, selectedRoom);
                                String hexColor = '#${type.color.value.toRadixString(16).substring(2)}';
                                Map<String, dynamic> cfg = { "action": "add", "name": type.name, "room": selectedRoom, "type": "switch", "color": hexColor }; 
                                mqttHandler.publishMessage("home/config", jsonEncode(cfg)); 
                                
                                Navigator.pop(ctx); 
                                widget.onAddComplete(); 
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm ${type.name}!")));
                              }, 
                              // Ô THIẾT BỊ (STYLE TRẮNG SẠCH)
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20), 
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                                ), 
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, 
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: type.color.withOpacity(0.1), // Nền icon màu nhạt
                                      ),
                                      child: Icon(type.icon, color: type.color, size: 32)
                                    ), 
                                    const SizedBox(height: 12), 
                                    Text(type.name, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)
                                  ]
                                )
                              )
                            );
                          }
                        )
                      )
                    ]
                  )
                ),
              ),
            );
          }
        );
      }
    );
  }

  String _getIconName(SmartDevice device) { 
    if (device.icon.codePoint == Icons.meeting_room.codePoint) return device.isOn ? SmartIcons.doorOpen : SmartIcons.doorClosed; 
    if (device.icon.codePoint == Icons.cyclone.codePoint) return SmartIcons.fan; 
    if (device.icon.codePoint == Icons.thermostat.codePoint) return SmartIcons.heater; 
    if (device.icon.codePoint == Icons.view_headline.codePoint) return SmartIcons.curtain; 
    if (device.icon.codePoint == Icons.ac_unit.codePoint) return SmartIcons.ac; 
    return SmartIcons.bulb; 
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: deviceManager, builder: (context, _) { 
      
      final hotspots = deviceManager.devices
          .where((d) => d.name != "Gara Ô tô") 
          .map((d) { 
            return SmartHotspot(
              id: d.id, position: d.position, normal: d.normal, color: d.color, iconName: _getIconName(d), 
              panelBuilder: (ctx, toggle, color) {
                if (d.name.contains("Quạt")) return FanPanel(deviceId: d.id, onToggle3D: toggle);
                if (d.name.contains("Điều hòa")) return ACPanel(deviceId: d.id, onToggle3D: toggle);
                if (d.name.contains("Cửa") || d.name.contains("Rèm")) return SimplePanel(deviceId: d.id, onToggle3D: toggle, labelOn: "Đang Mở", labelOff: "Đang Đóng");
                if (d.name.contains("Máy sưởi")) return SimplePanel(deviceId: d.id, onToggle3D: toggle, labelOn: "Đang Bật", labelOff: "Đang Tắt");
                return LightPanel(deviceId: d.id, onToggle3D: toggle, onChangeColor: color);
              }
            ); 
          }).toList(); 

      return Stack(children: [
        SmartHomeViewer(src: 'assets/Bambo_House.glb', yOffset: -60.0, hotspots: hotspots, onModelTap: _handleModelTap),
        if (widget.isAddingMode) const Positioned.fill(child: AddingModeOverlay()),
      ]); 
    }); 
  }
}

// ... Overlay ...
class AddingModeOverlay extends StatefulWidget { const AddingModeOverlay({super.key}); @override State<AddingModeOverlay> createState() => _AddingModeOverlayState(); }
class _AddingModeOverlayState extends State<AddingModeOverlay> with TickerProviderStateMixin { late AnimationController _r; late AnimationController _b; bool _fin = false; @override void initState() { super.initState(); _r = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); _b = AnimationController(vsync: this, duration: const Duration(seconds: 2)); _r.forward(); _r.addStatusListener((status) { if (status == AnimationStatus.completed) { setState(() => _fin = true); _b.repeat(); } }); } @override void dispose() { _r.dispose(); _b.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return IgnorePointer(child: AnimatedBuilder(animation: Listenable.merge([_r, _b]), builder: (context, child) { return CustomPaint(painter: _SequencePainter(rV: _r.value, bV: _b.value, fin: _fin), size: Size.infinite); },)); } }
class _SequencePainter extends CustomPainter { final double rV; final double bV; final bool fin; _SequencePainter({required this.rV, required this.bV, required this.fin}); @override void paint(Canvas canvas, Size size) { final center = Offset(size.width / 2, size.height / 2); final rect = Rect.fromLTWH(0, 0, size.width, size.height); if (fin) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 6.0..shader = SweepGradient(colors: const [Colors.red, Colors.blue, Colors.green, Colors.red], transform: GradientRotation(bV * 2 * math.pi)).createShader(rect); canvas.drawRect(rect, p); } if (!fin) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 25.0..color = Colors.cyanAccent.withOpacity((1.0 - rV).clamp(0.0, 1.0) * 0.3); canvas.drawCircle(center, math.max(size.width, size.height) * rV, p); } } @override bool shouldRepaint(covariant _SequencePainter old) => true; }