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
import '../models/people_manager.dart'; 
import 'notification_screen.dart';

// --- MODEL ĐỂ LƯU HÌNH DÁNG PHÒNG ---
class RoomShape {
  final String name;
  final List<Offset> points; // Danh sách tọa độ X, Z
  RoomShape(this.name, this.points);
}
// -------------------------------------

class DeviceType {
  final String name;
  final IconData icon;
  final Color color;
  DeviceType(this.name, this.icon, this.color);
}

class SmartHome3DPage extends StatefulWidget {
  final bool isAddingMode;
  final VoidCallback onAddComplete;
  final Function(bool isMapMode) onMapModeChanged;

  const SmartHome3DPage({
    super.key,
    required this.isAddingMode,
    required this.onAddComplete,
    required this.onMapModeChanged,
  });

  @override State<SmartHome3DPage> createState() => _SmartHome3DPageState();
}

class _SmartHome3DPageState extends State<SmartHome3DPage> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // --- BIẾN CHO CHẾ ĐỘ MAP EDITOR ---
  bool isMapMode = false; 
  List<String> tempMapPoints = []; 
  
  // DANH SÁCH CÁC PHÒNG ĐÃ LƯU (Dùng để nhận diện vị trí)
  List<RoomShape> savedRooms = []; 
  // ----------------------------------

  final List<DeviceType> availableTypes = [
    DeviceType("Đèn", Icons.lightbulb, Colors.amber),
    DeviceType("Quạt", Icons.cyclone, Colors.teal),
    DeviceType("Máy sưởi", Icons.thermostat, Colors.red),
    DeviceType("Rèm cửa", Icons.view_headline, Colors.purpleAccent),
    DeviceType("Cửa Chính", Icons.meeting_room, Colors.brown),
    DeviceType("Điều hòa", Icons.ac_unit, Colors.cyan),
  ];

  // Danh sách tên phòng mặc định (dùng khi chưa vẽ map hoặc chọn thủ công)
  final List<String> defaultRooms = ["Phòng Khách", "Phòng Ngủ", "Nhà Bếp", "Sân Vườn", "WC"];
  String selectedRoom = "Phòng Khách";
  TextEditingController pinController = TextEditingController(text: "2");

  // Tọa độ AI (Tạm thời)
  final Map<String, String> roomCoordinates = {
    "Phòng Khách": "0.54m 1.5m -1.2m", 
    "Phòng Ngủ": "-2.1m 1.5m 3.5m",
    "Nhà Bếp": "2.5m 1.5m -2.0m",
    "Sân Vườn": "4.0m 1.0m 4.0m",
  };

  // --- THUẬT TOÁN: KIỂM TRA ĐIỂM CÓ NẰM TRONG ĐA GIÁC KHÔNG ---
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    int i, j = polygon.length - 1;
    bool oddNodes = false;
    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy < point.dy && polygon[j].dy >= point.dy ||
          polygon[j].dy < point.dy && polygon[i].dy >= point.dy) &&
          (polygon[i].dx <= point.dx || polygon[j].dx <= point.dx)) {
            if (polygon[i].dx + (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) * (polygon[j].dx - polygon[i].dx) < point.dx) {
              oddNodes = !oddNodes;
            }
      }
      j = i;
    }
    return oddNodes;
  }
  // -------------------------------------------------------------

  void _handleModelTap(String position, String normal) {
    // 1. LOGIC VẼ MAP
    if (isMapMode) {
      setState(() { tempMapPoints.add(position); });
      return;
    }

    // 2. LOGIC THÊM THIẾT BỊ (ĐÃ NÂNG CẤP AUTO DETECT ROOM)
    if (!widget.isAddingMode) return;
    
    // -- XỬ LÝ TỰ ĐỘNG NHẬN DIỆN PHÒNG --
    bool isAutoDetected = false;
    
    // Parse tọa độ điểm chạm: "0.5m 0m -1.2m" -> x=0.5, z=-1.2
    try {
      final parts = position.replaceAll('m', '').split(' ');
      double tapX = double.parse(parts[0]);
      double tapZ = double.parse(parts[2]); // Lấy Z (bỏ qua độ cao Y)
      Offset tapPoint = Offset(tapX, tapZ);

      // Duyệt qua tất cả các phòng đã vẽ
      for (var room in savedRooms) {
        if (_isPointInPolygon(tapPoint, room.points)) {
          selectedRoom = room.name; // Tự động chọn phòng này
          isAutoDetected = true;
          print("🔍 Đã phát hiện vị trí thuộc về: ${room.name}");
          break;
        }
      }
    } catch (e) { print("Lỗi parse tọa độ: $e"); }

    // Nếu không nhận diện được (chạm ra ngoài map), mặc định về Phòng Khách
    if (!isAutoDetected && !defaultRooms.contains(selectedRoom)) {
      selectedRoom = defaultRooms[0];
    }
    // ------------------------------------
    
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
                    // Nếu tự nhận diện phòng -> Bảng ngắn hơn vì không cần dropdown
                    height: isAutoDetected ? 450 : (isRoomListOpen ? 650 : 520), 
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Thêm thiết bị mới", style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.black54))
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- CỘT CHỌN PHÒNG (THÔNG MINH) ---
                            Expanded(
                              flex: 2,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text("Vị trí", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                
                                // NẾU TỰ ĐỘNG NHẬN DIỆN -> HIỆN TEXT TĨNH (KHÔNG CẦN CHỌN)
                                if (isAutoDetected)
                                  Container(
                                    height: 55, 
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.2), // Màu xanh báo hiệu auto
                                      borderRadius: BorderRadius.circular(16), 
                                      border: Border.all(color: Colors.greenAccent, width: 1)
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.gps_fixed, color: Colors.green, size: 20), 
                                        const SizedBox(width: 10), 
                                        Expanded(child: Text(selectedRoom, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16))),
                                        const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                      ]
                                    ),
                                  )
                                // NẾU KHÔNG NHẬN DIỆN ĐƯỢC -> HIỆN DROPDOWN CŨ
                                else 
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () { setModalState(() { isRoomListOpen = !isRoomListOpen; }); },
                                        child: Container(
                                          height: 55, padding: const EdgeInsets.symmetric(horizontal: 15),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: isRoomListOpen ? Colors.blueAccent : Colors.white, width: 2)),
                                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                            Row(children: [const Icon(Icons.meeting_room, color: Colors.blueAccent, size: 20), const SizedBox(width: 10), Text(selectedRoom, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))]),
                                            Icon(isRoomListOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black54),
                                          ]),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        height: isRoomListOpen ? (defaultRooms.length * 50.0 + 10) : 0,
                                        margin: const EdgeInsets.only(top: 8),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                                        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: SizedBox(height: defaultRooms.length * 50.0, child: Stack(children: [
                                          AnimatedPositioned(duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack, top: defaultRooms.indexOf(selectedRoom) * 50.0 + 5, left: 5, right: 5, height: 40, child: Container(decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withOpacity(0.5))))),
                                          Column(children: defaultRooms.map((room) { return GestureDetector(onTap: () { setModalState(() { selectedRoom = room; Future.delayed(const Duration(milliseconds: 300), () { if (context.mounted) setModalState(() => isRoomListOpen = false); }); }); }, child: Container(height: 50, color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 15), child: Row(children: [Icon(Icons.circle, size: 8, color: selectedRoom == room ? Colors.blueAccent : Colors.grey[300]), const SizedBox(width: 12), Text(room, style: TextStyle(color: selectedRoom == room ? Colors.blueAccent : Colors.black87, fontWeight: selectedRoom == room ? FontWeight.bold : FontWeight.w500))]))); }).toList())
                                        ]))))
                                      )
                                    ],
                                  )
                              ]),
                            ),
                            const SizedBox(width: 15),
                            // --- CỘT GPIO PIN (GIỮ NGUYÊN) ---
                            Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("GPIO Pin", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Container(height: 55, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2)), child: TextField(controller: pinController, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18), decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, hintText: "2", hintStyle: TextStyle(color: Colors.black26))))])),
                          ],
                        ),
                        SizedBox(height: isRoomListOpen ? 20 : 25),
                        const Text("Chọn thiết bị", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 15),
                        Expanded(child: IgnorePointer(ignoring: isRoomListOpen, child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: isRoomListOpen ? 0.3 : 1.0, child: GridView.builder(padding: EdgeInsets.zero, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.95), itemCount: availableTypes.length, itemBuilder: (context, index) { final type = availableTypes[index]; return InkWell(onTap: () { int pin = int.tryParse(pinController.text) ?? -1; deviceManager.addDevice(type.name, type.icon, position, normal, selectedRoom, pin); String hexColor = '#${type.color.value.toRadixString(16).substring(2)}'; Map<String, dynamic> cfg = { "action": "add", "name": type.name, "room": selectedRoom, "pin": pin, "type": "switch", "color": hexColor }; mqttHandler.publishMessage("home/config", jsonEncode(cfg)); Navigator.pop(ctx); widget.onAddComplete(); notificationManager.addNotification("Thiết bị mới", "Đã thêm ${type.name} vào $selectedRoom (Pin D$pin)", type: NotiType.success); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm ${type.name} vào Pin D$pin"))); }, child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: type.color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: type.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(type.icon, color: type.color, size: 28)), const SizedBox(height: 10), Text(type.name, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600))]))); }))))
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

  void _showMapConfirmationDialog() {
    final TextEditingController roomNameController = TextEditingController();
    
    // Convert 3D points to 2D
    List<Offset> points2D = tempMapPoints.map((pStr) {
       final parts = pStr.replaceAll('m', '').split(' ');
       double x = double.tryParse(parts[0]) ?? 0;
       double z = double.tryParse(parts[2]) ?? 0;
       return Offset(x, z);
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Xác nhận vùng phòng", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView( 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)),
                  child: CustomPaint(
                    painter: _RoomPreviewPainter(points: points2D),
                    size: const Size(250, 250),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: roomNameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "Tên phòng (Ví dụ: Phòng Khách)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.meeting_room)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Tiếp tục sửa", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                if (roomNameController.text.isNotEmpty) {
                  // --- LƯU PHÒNG VÀO BỘ NHỚ ---
                  final newRoom = RoomShape(roomNameController.text, points2D);
                  
                  // Kiểm tra xem phòng đã tồn tại chưa để cập nhật hoặc thêm mới
                  int index = savedRooms.indexWhere((r) => r.name == newRoom.name);
                  if (index != -1) {
                    savedRooms[index] = newRoom;
                  } else {
                    savedRooms.add(newRoom);
                  }
                  
                  // Thêm tên phòng vào danh sách mặc định nếu chưa có (để dùng cho list dropdown)
                  if (!defaultRooms.contains(newRoom.name)) {
                    defaultRooms.add(newRoom.name);
                  }
                  
                  print("✅ Đã lưu phòng: ${newRoom.name} với ${newRoom.points.length} điểm");
                  
                  // Reset trạng thái
                  setState(() {
                    tempMapPoints.clear(); 
                  });
                  
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã lưu phòng! Hãy vẽ tiếp hoặc thoát."), backgroundColor: Colors.green)
                  );
                }
              }, 
              child: const Text("LƯU PHÒNG", style: TextStyle(color: Colors.white))
            )
          ],
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
    super.build(context);

    return ListenableBuilder(
      listenable: Listenable.merge([deviceManager, peopleManager]),
      builder: (context, _) {
        final deviceHotspots = deviceManager.devices
            .where((d) => !d.name.contains("Gara"))
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

        final peopleHotspots = roomCoordinates.entries.map((entry) {
            final count = peopleManager.roomCounts[entry.key] ?? 0;
            if (count == 0) return null;
            return SmartHotspot(
               id: "p_${entry.key}", position: entry.value, normal: "0 1 0", color: Colors.transparent, iconName: "",
               customWidget: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent)),
                 child: Row(children: [const Icon(Icons.person, color: Colors.greenAccent, size: 14), const SizedBox(width: 4), Text("$count", style: const TextStyle(color: Colors.white))])
               ),
               panelBuilder: (_, __, ___) => Container()
            );
        }).whereType<SmartHotspot>().toList();

        final mapEditHotspots = tempMapPoints.asMap().entries.map((entry) {
           return SmartHotspot(
             id: "map_point_${entry.key}",
             position: entry.value,
             normal: "0 1 0",
             color: Colors.redAccent, 
             iconName: "",
             customWidget: Container(
               width: 15, height: 15,
               decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
               child: Center(child: Text("${entry.key + 1}", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
             ),
             panelBuilder: (_,__,___) => Container(),
           );
        }).toList();

        final allHotspots = isMapMode ? mapEditHotspots : [...deviceHotspots, ...peopleHotspots];

        return Stack(
          children: [
            SmartHomeViewer(
              src: 'assets/Bambo_House.glb',
              yOffset: -60.0,
              hotspots: allHotspots,
              onModelTap: _handleModelTap,
              
              cameraOrbit: isMapMode ? "0deg 0deg 50%" : null, 
              minCameraOrbit: isMapMode ? "-Infinity 0deg auto" : "auto auto auto",
              maxCameraOrbit: isMapMode ? "Infinity 0deg auto" : "auto auto auto",
            ),

            if (!isMapMode)
              Positioned(
                top: 40, right: 20,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                      child: IconButton(
                        icon: const Icon(Icons.map, color: Colors.orangeAccent),
                        onPressed: () {
                          setState(() { isMapMode = true; tempMapPoints.clear(); });
                          widget.onMapModeChanged(true); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vẽ Map: Chạm vào các góc phòng -> Ấn V để lưu.")));
                        }
                      ),
                    ),
                    const SizedBox(width: 10),
                    ListenableBuilder(listenable: notificationManager, builder: (context, _) { return Stack(clipBehavior: Clip.none, children: [Container(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)), child: IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())))), if (notificationManager.unreadCount > 0) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text("${notificationManager.unreadCount}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))]); }),
                    const SizedBox(width: 10),
                    Container(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)), child: IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => _showIpDialog(context))),
                  ],
                )
              ),

            if (isMapMode)
              Positioned(
                top: 40, right: 20,
                child: Container(
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(30)),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: "Thoát chế độ vẽ",
                    onPressed: () {
                      setState(() { isMapMode = false; tempMapPoints.clear(); });
                      widget.onMapModeChanged(false); 
                    }
                  ),
                ),
              ),

            if (isMapMode)
               Positioned(
                 bottom: 30, left: 20, right: 20,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                   decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orangeAccent)),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                           Text("Điểm: ${tempMapPoints.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                           const Text("Xoay, Zoom, Chấm góc", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ]),
                        
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tempMapPoints.length >= 3 ? Colors.green : Colors.grey[800],
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(15)
                          ),
                          onPressed: tempMapPoints.length >= 3 
                              ? () => _showMapConfirmationDialog() 
                              : null,
                          child: Icon(Icons.check, color: tempMapPoints.length >= 3 ? Colors.white : Colors.grey),
                        ),
                     ],
                   ),
                 ),
               ),

            if (widget.isAddingMode) const Positioned.fill(child: AddingModeOverlay()),
          ],
        );
      }
    );
  }

  void _showIpDialog(BuildContext context) { /* Code IP cũ */ final c = TextEditingController(text: mqttHandler.server); showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: const Text("Cài đặt MQTT Broker"), content: TextField(controller: c, decoration: const InputDecoration(labelText: "Địa chỉ IP", hintText: "192.168.1.xxx", border: OutlineInputBorder()), keyboardType: TextInputType.number), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () async { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 15), Text("Đang kết nối tới Broker...")]), duration: Duration(days: 1), backgroundColor: Colors.blueGrey)); bool isConnected = await mqttHandler.updateBrokerIP(c.text.trim()); ScaffoldMessenger.of(context).hideCurrentSnackBar(); if (isConnected) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Text("Đã kết nối thành công tới ${c.text}!")]), backgroundColor: Colors.green)); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [Icon(Icons.error, color: Colors.white), SizedBox(width: 10), Text("Kết nối thất bại! Kiểm tra lại IP.")]), backgroundColor: Colors.redAccent)); } }, child: const Text("LƯU & KẾT NỐI", style: TextStyle(color: Colors.white)))])); }
}

class _RoomPreviewPainter extends CustomPainter {
  final List<Offset> points;
  _RoomPreviewPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    final Paint linePaint = Paint()..color = Colors.blueAccent..strokeWidth = 3..style = PaintingStyle.stroke;
    final Paint dotPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    final Paint fillPaint = Paint()..color = Colors.blueAccent.withOpacity(0.2)..style = PaintingStyle.fill;

    double minX = points.map((p) => p.dx).reduce(math.min);
    double maxX = points.map((p) => p.dx).reduce(math.max);
    double minZ = points.map((p) => p.dy).reduce(math.min);
    double maxZ = points.map((p) => p.dy).reduce(math.max);
    
    double width = maxX - minX;
    double height = maxZ - minZ;
    if (width == 0) width = 1; if (height == 0) height = 1;

    double scaleX = (size.width - 40) / width;
    double scaleY = (size.height - 40) / height;
    double scale = math.min(scaleX, scaleY);

    Offset toCanvas(Offset p) {
      double cx = (p.dx - minX) * scale + 20;
      double cy = (p.dy - minZ) * scale + 20;
      return Offset(cx, cy);
    }

    final path = Path();
    Offset p0 = toCanvas(points[0]);
    path.moveTo(p0.dx, p0.dy);
    for (int i = 1; i < points.length; i++) {
      Offset p = toCanvas(points[i]);
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var p in points) {
      canvas.drawCircle(toCanvas(p), 5, dotPaint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AddingModeOverlay extends StatefulWidget { const AddingModeOverlay({super.key}); @override State<AddingModeOverlay> createState() => _AddingModeOverlayState(); }
class _AddingModeOverlayState extends State<AddingModeOverlay> with TickerProviderStateMixin { late AnimationController _r; late AnimationController _b; bool _fin = false; @override void initState() { super.initState(); _r = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); _b = AnimationController(vsync: this, duration: const Duration(seconds: 2)); _r.forward(); _r.addStatusListener((status) { if (status == AnimationStatus.completed) { setState(() => _fin = true); _b.repeat(); } }); } @override void dispose() { _r.dispose(); _b.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return IgnorePointer(child: AnimatedBuilder(animation: Listenable.merge([_r, _b]), builder: (context, child) { return CustomPaint(painter: _SequencePainter(rV: _r.value, bV: _b.value, fin: _fin), size: Size.infinite); },)); } }
class _SequencePainter extends CustomPainter { final double rV; final double bV; final bool fin; _SequencePainter({required this.rV, required this.bV, required this.fin}); @override void paint(Canvas canvas, Size size) { final center = Offset(size.width / 2, size.height / 2); final rect = Rect.fromLTWH(0, 0, size.width, size.height); if (fin) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 6.0..shader = SweepGradient(colors: const [Colors.red, Colors.blue, Colors.green, Colors.red], transform: GradientRotation(bV * 2 * math.pi)).createShader(rect); canvas.drawRect(rect, p); } if (!fin) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 25.0..color = Colors.cyanAccent.withOpacity((1.0 - rV).clamp(0.0, 1.0) * 0.3); canvas.drawCircle(center, math.max(size.width, size.height) * rV, p); } } @override bool shouldRepaint(covariant _SequencePainter old) => true; }