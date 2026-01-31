import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../widgets/smart_3d_viewer.dart';
import '../widgets/glass_panel.dart';
import '../widgets/panels/light_panel.dart';
import '../widgets/panels/fan_panel.dart';
import '../widgets/panels/ac_panel.dart';
import '../widgets/panels/simple_panel.dart';

import '../models/device_model.dart';
import '../services/mqtt_service.dart';
import '../models/notification_model.dart'; 
import 'notification_screen.dart'; 

class DeviceType { 
  final String name; 
  final IconData icon; 
  final Color color; 
  DeviceType(this.name, this.icon, this.color); 
}

class SmartHome3DPage extends StatefulWidget {
  final bool isAddingMode; 
  final VoidCallback onAddComplete;
  
  const SmartHome3DPage({
    super.key, 
    required this.isAddingMode, 
    required this.onAddComplete
  });
  
  @override State<SmartHome3DPage> createState() => _SmartHome3DPageState();
}

// 1. THÊM MIXIN ĐỂ GIỮ TRẠNG THÁI 3D
class _SmartHome3DPageState extends State<SmartHome3DPage> with AutomaticKeepAliveClientMixin {
  
  // 2. BẮT BUỘC: Đánh dấu là muốn giữ trạng thái
  @override
  bool get wantKeepAlive => true; 

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
  TextEditingController pinController = TextEditingController(text: "2");

  void _handleModelTap(String position, String normal) {
    if (!widget.isAddingMode) return;
    
    bool isRoomListOpen = false;

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    height: isRoomListOpen ? 650 : 520, 
                    padding: const EdgeInsets.fromLTRB(25, 15, 25, 25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85), 
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Thêm thiết bị mới", 
                              style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx), 
                              icon: const Icon(Icons.close, color: Colors.black54)
                            )
                          ],
                        ),
                        const SizedBox(height: 15),

                        // --- INPUT AREA ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CUSTOM DROPDOWN (SLIDING)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  const Text("Vị trí", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() { isRoomListOpen = !isRoomListOpen; });
                                    },
                                    child: Container(
                                      height: 55,
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isRoomListOpen ? Colors.blueAccent : Colors.white, width: 2)
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [
                                            const Icon(Icons.meeting_room, color: Colors.blueAccent, size: 20),
                                            const SizedBox(width: 10),
                                            Text(selectedRoom, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                          ]),
                                          Icon(isRoomListOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black54),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // LIST ROOMS (SLIDING EFFECT)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: isRoomListOpen ? (rooms.length * 50.0 + 10) : 0,
                                    margin: const EdgeInsets.only(top: 8),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SingleChildScrollView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        child: SizedBox(
                                          height: rooms.length * 50.0,
                                          child: Stack(
                                            children: [
                                              // SLIDING INDICATOR
                                              AnimatedPositioned(
                                                duration: const Duration(milliseconds: 250),
                                                curve: Curves.easeOutBack,
                                                top: rooms.indexOf(selectedRoom) * 50.0 + 5,
                                                left: 5, right: 5, height: 40,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.blueAccent.withOpacity(0.5))
                                                  ),
                                                ),
                                              ),
                                              // ROOM TEXT ITEMS
                                              Column(
                                                children: rooms.map((room) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      setModalState(() {
                                                        selectedRoom = room;
                                                        Future.delayed(const Duration(milliseconds: 300), () {
                                                          if (context.mounted) setModalState(() => isRoomListOpen = false);
                                                        });
                                                      });
                                                    },
                                                    child: Container(
                                                      height: 50, color: Colors.transparent,
                                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                                      child: Row(children: [
                                                          Icon(Icons.circle, size: 8, color: selectedRoom == room ? Colors.blueAccent : Colors.grey[300]),
                                                          const SizedBox(width: 12),
                                                          Text(room, style: TextStyle(
                                                            color: selectedRoom == room ? Colors.blueAccent : Colors.black87,
                                                            fontWeight: selectedRoom == room ? FontWeight.bold : FontWeight.w500
                                                          )),
                                                      ]),
                                                    ),
                                                  );
                                                }).toList(),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            
                            // GPIO INPUT
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  const Text("GPIO Pin", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 55, alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6), 
                                      borderRadius: BorderRadius.circular(16), 
                                      border: Border.all(color: Colors.white, width: 2)
                                    ),
                                    child: TextField(
                                      controller: pinController, 
                                      keyboardType: TextInputType.number, 
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, hintText: "2", hintStyle: TextStyle(color: Colors.black26)),
                                    ),
                                  ),
                                ]
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: isRoomListOpen ? 20 : 25),
                        const Text("Chọn thiết bị", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 15),

                        // --- DEVICE GRID ---
                        Expanded(
                          child: IgnorePointer(
                            ignoring: isRoomListOpen,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isRoomListOpen ? 0.3 : 1.0,
                              child: GridView.builder(
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, 
                                  crossAxisSpacing: 15, 
                                  mainAxisSpacing: 15, 
                                  childAspectRatio: 0.95
                                ), 
                                itemCount: availableTypes.length, 
                                itemBuilder: (context, index) {
                                  final type = availableTypes[index];
                                  return InkWell(
                                    onTap: () {
                                      int pin = int.tryParse(pinController.text) ?? -1;
                                      deviceManager.addDevice(type.name, type.icon, position, normal, selectedRoom, pin);
                                      
                                      String hexColor = '#${type.color.value.toRadixString(16).substring(2)}';
                                      Map<String, dynamic> cfg = { 
                                        "action": "add", 
                                        "name": type.name, 
                                        "room": selectedRoom, 
                                        "pin": pin, 
                                        "type": "switch", 
                                        "color": hexColor 
                                      }; 
                                      mqttHandler.publishMessage("home/config", jsonEncode(cfg)); 
                                      
                                      Navigator.pop(ctx); 
                                      widget.onAddComplete(); 
                                      
                                      notificationManager.addNotification(
                                        "Thiết bị mới", 
                                        "Đã thêm ${type.name} vào $selectedRoom (Pin D$pin)", 
                                        type: NotiType.success
                                      );
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Đã thêm ${type.name} vào Pin D$pin"))
                                      );
                                    }, 
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5), 
                                        borderRadius: BorderRadius.circular(20), 
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: type.color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
                                      ), 
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center, 
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12), 
                                            decoration: BoxDecoration(color: type.color.withOpacity(0.1), shape: BoxShape.circle),
                                            child: Icon(type.icon, color: type.color, size: 28)
                                          ),
                                          const SizedBox(height: 10), 
                                          Text(type.name, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600))
                                        ]
                                      )
                                    )
                                  );
                                }
                              ),
                            ),
                          )
                        )
                      ]
                    )
                  ),
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
    // 3. QUAN TRỌNG: Gọi super.build để kích hoạt KeepAlive
    super.build(context);

    return ListenableBuilder(
      listenable: deviceManager, 
      builder: (context, _) { 
        final hotspots = deviceManager.devices.where((d) => d.name != "Gara Ô tô").map((d) { 
          return SmartHotspot(
            id: d.id, 
            position: d.position, 
            normal: d.normal, 
            color: d.color, 
            iconName: _getIconName(d), 
            panelBuilder: (ctx, toggle, color) {
              if (d.name.contains("Quạt")) return FanPanel(deviceId: d.id, onToggle3D: toggle);
              if (d.name.contains("Điều hòa")) return ACPanel(deviceId: d.id, onToggle3D: toggle);
              if (d.name.contains("Cửa") || d.name.contains("Rèm")) return SimplePanel(deviceId: d.id, onToggle3D: toggle, labelOn: "Đang Mở", labelOff: "Đang Đóng");
              if (d.name.contains("Máy sưởi")) return SimplePanel(deviceId: d.id, onToggle3D: toggle, labelOn: "Đang Bật", labelOff: "Đang Tắt");
              return LightPanel(deviceId: d.id, onToggle3D: toggle, onChangeColor: color);
            }
          ); 
        }).toList(); 

        return Stack(
          children: [
            SmartHomeViewer(src: 'assets/Bambo_House.glb', yOffset: -60.0, hotspots: hotspots, onModelTap: _handleModelTap),
            
            // --- NÚT GÓC TRÊN PHẢI (BELL + SETTINGS) ---
            Positioned(
              top: 40, right: 20, 
              child: Row(
                children: [
                  // Nút Thông Báo
                  ListenableBuilder(
                    listenable: notificationManager,
                    builder: (context, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                            child: IconButton(
                              icon: const Icon(Icons.notifications, color: Colors.white), 
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))
                            ),
                          ),
                          if (notificationManager.unreadCount > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5), 
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text("${notificationManager.unreadCount}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            )
                        ],
                      );
                    }
                  ),
                  const SizedBox(width: 10),
                  // Nút Cài đặt IP
                  Container(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)), 
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white), 
                      onPressed: () => _showIpDialog(context)
                    )
                  ),
                ],
              )
            ),
            
            if (widget.isAddingMode) const Positioned.fill(child: AddingModeOverlay()),
          ]
        ); 
      }
    ); 
  }

  // --- HÀM HIỂN THỊ CÀI ĐẶT IP ---
  void _showIpDialog(BuildContext context) {
     final c = TextEditingController(text: mqttHandler.server);
     showDialog(
       context: context, 
       barrierDismissible: false,
       builder: (ctx) => AlertDialog(
         title: const Text("Cài đặt MQTT Broker"),
         content: TextField(
           controller: c,
           decoration: const InputDecoration(labelText: "Địa chỉ IP", hintText: "192.168.1.xxx", border: OutlineInputBorder()),
           keyboardType: TextInputType.number,
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
             onPressed: () async {
               Navigator.pop(ctx); 
               
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 15), Text("Đang kết nối tới Broker...")]),
                   duration: Duration(days: 1), backgroundColor: Colors.blueGrey,
                 )
               );

               bool isConnected = await mqttHandler.updateBrokerIP(c.text.trim());
               ScaffoldMessenger.of(context).hideCurrentSnackBar();

               if (isConnected) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Text("Đã kết nối thành công tới ${c.text}!")]), backgroundColor: Colors.green));
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [Icon(Icons.error, color: Colors.white), SizedBox(width: 10), Text("Kết nối thất bại! Kiểm tra lại IP.")]), backgroundColor: Colors.redAccent));
               }
             }, 
             child: const Text("LƯU & KẾT NỐI", style: TextStyle(color: Colors.white))
           )
         ]
       )
     );
  }
}

// --- OVERLAY EFFECT ---
class AddingModeOverlay extends StatefulWidget { 
  const AddingModeOverlay({super.key}); 
  @override State<AddingModeOverlay> createState() => _AddingModeOverlayState(); 
}

class _AddingModeOverlayState extends State<AddingModeOverlay> with TickerProviderStateMixin { 
  late AnimationController _r; 
  late AnimationController _b; 
  bool _fin = false; 

  @override void initState() { 
    super.initState(); 
    _r = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); 
    _b = AnimationController(vsync: this, duration: const Duration(seconds: 2)); 
    _r.forward(); 
    _r.addStatusListener((status) { 
      if (status == AnimationStatus.completed) { 
        setState(() => _fin = true); 
        _b.repeat(); 
      } 
    }); 
  } 

  @override void dispose() { 
    _r.dispose(); 
    _b.dispose(); 
    super.dispose(); 
  } 

  @override Widget build(BuildContext context) { 
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_r, _b]), 
        builder: (context, child) { 
          return CustomPaint(
            painter: _SequencePainter(rV: _r.value, bV: _b.value, fin: _fin), 
            size: Size.infinite
          ); 
        },
      )
    ); 
  } 
}

class _SequencePainter extends CustomPainter { 
  final double rV; 
  final double bV; 
  final bool fin; 
  _SequencePainter({required this.rV, required this.bV, required this.fin}); 

  @override void paint(Canvas canvas, Size size) { 
    final center = Offset(size.width / 2, size.height / 2); 
    final rect = Rect.fromLTWH(0, 0, size.width, size.height); 
    if (fin) { 
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..shader = SweepGradient(
          colors: const [Colors.red, Colors.blue, Colors.green, Colors.red], 
          transform: GradientRotation(bV * 2 * math.pi)
        ).createShader(rect); 
      canvas.drawRect(rect, p); 
    } 
    if (!fin) { 
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25.0
        ..color = Colors.cyanAccent.withOpacity((1.0 - rV).clamp(0.0, 1.0) * 0.3); 
      canvas.drawCircle(center, math.max(size.width, size.height) * rV, p); 
    } 
  } 

  @override bool shouldRepaint(covariant _SequencePainter old) => true; 
}