// ... Các phần import và helper classes giữ nguyên ...
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'device_data.dart'; // <--- IMPORT BỘ NÃO

// ... (Class SmartIcons và SmartHotspot giữ nguyên) ...
class SmartIcons {
  static const String bulb = '<svg viewBox="0 0 24 24" fill="currentColor" width="20px" height="20px"><path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z"/></svg>';
}
typedef SmartPanelBuilder = Widget Function(BuildContext context, Function(bool) toggle3D, Function(Color) changeColor);
class SmartHotspot {
  final String id; final String position; final String normal; final SmartPanelBuilder panelBuilder; final String svgIcon; final Color color;
  SmartHotspot({required this.id, required this.position, this.normal = '0m 1m 0m', required this.panelBuilder, this.svgIcon = SmartIcons.bulb, this.color = Colors.blueAccent});
}

class SmartHomeViewer extends StatefulWidget {
  final String src; final List<SmartHotspot> hotspots; final double yOffset;
  const SmartHomeViewer({super.key, required this.src, required this.hotspots, this.yOffset = 0.0});
  @override State<SmartHomeViewer> createState() => _SmartHomeViewerState();
}

class _SmartHomeViewerState extends State<SmartHomeViewer> {
  String? activeHotspotId;
  Offset panelPosition = Offset.zero;
  bool isPanelVisible = false;
  WebViewController? _webController;

  // HÀM LẮNG NGHE SỰ THAY ĐỔI
  void _onDeviceChanged() {
    if (_webController == null) return;
    
    // Duyệt qua tất cả các hotspot và cập nhật trạng thái xuống Web
    for (var hotspot in widget.hotspots) {
      final device = deviceManager.getDevice(hotspot.id); // Lấy data mới nhất
      
      // Gửi lệnh JS: Cập nhật bật/tắt
      _webController!.runJavaScript("setHotspotState('${hotspot.id}', ${device.isOn})");
      
      // Gửi lệnh JS: Cập nhật màu sắc
      String hex = '#${device.color.value.toRadixString(16).substring(2)}';
      _webController!.runJavaScript("setHotspotColor('${hotspot.id}', '$hex')");
    }
  }

  @override
  void initState() {
    super.initState();
    // Đăng ký lắng nghe
    deviceManager.addListener(_onDeviceChanged);
  }

  @override
  void dispose() {
    // Hủy đăng ký khi thoát
    deviceManager.removeListener(_onDeviceChanged);
    super.dispose();
  }

  // ... (Phần build và logic còn lại giữ nguyên như code trước) ...
  // Copy y hệt phần build của smart_3d_viewer.dart ở câu trả lời trước vào đây
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
        return Stack(children: [
            Listener(onPointerDown: (_) { if (isPanelVisible) setState(() => isPanelVisible = false); },
              child: ModelViewer(src: widget.src, alt: "Smart Home", backgroundColor: Colors.black, autoRotate: false, cameraControls: true, disableZoom: true,
                onWebViewCreated: (c) {
                   _webController = c;
                   // Đợi 1 chút cho web load xong rồi sync dữ liệu lần đầu
                   Future.delayed(const Duration(seconds: 1), _onDeviceChanged);
                },
                innerModelViewerHtml: _generateHtml(),
                javascriptChannels: {
                  JavascriptChannel('SmartLib', onMessageReceived: (message) { try { final data = jsonDecode(message.message); setState(() { activeHotspotId = data['id']; panelPosition = Offset(data['x'].toDouble(), data['y'].toDouble() + widget.yOffset); isPanelVisible = true; }); } catch (e) { debugPrint("JS Error: $e"); } }),
                },
              ),
            ),
            if (isPanelVisible && activeHotspotId != null) _buildOverlayPanel(constraints),
        ]);
    });
  }

  // Copy lại hàm _buildOverlayPanel, _generateHtml, và _ArrowPainter y hệt code trước
  Widget _buildOverlayPanel(BoxConstraints constraints) {
    final hotspot = widget.hotspots.firstWhere((h) => h.id == activeHotspotId, orElse: () => widget.hotspots[0]);
    const double panelWidth = 280;
    double panelLeft = panelPosition.dx - (panelWidth / 2); if (panelLeft < 10) panelLeft = 10; if (panelLeft + panelWidth > constraints.maxWidth - 10) panelLeft = constraints.maxWidth - panelWidth - 10;
    bool showBelow = panelPosition.dy < 200; double? posTop; double? posBottom; if (showBelow) { posTop = panelPosition.dy + 40; } else { posBottom = constraints.maxHeight - panelPosition.dy + 15; }
    double arrowLocalX = panelPosition.dx - panelLeft; if (arrowLocalX < 24) arrowLocalX = 24; if (arrowLocalX > panelWidth - 24) arrowLocalX = panelWidth - 24;
    return Positioned(top: posTop, bottom: posBottom, left: panelLeft, child: GestureDetector(onTap: () {}, child: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack, builder: (context, value, child) { return Transform.scale(scale: value, alignment: Alignment(((arrowLocalX / panelWidth) * 2) - 1, showBelow ? -1.0 : 1.0), child: child); }, child: Stack(clipBehavior: Clip.none, children: [hotspot.panelBuilder(context, (bool isOn) { _webController?.runJavaScript("setHotspotState('${hotspot.id}', $isOn)"); }, (Color c) { String hex = '#${c.value.toRadixString(16).substring(2)}'; _webController?.runJavaScript("setHotspotColor('${hotspot.id}', '$hex')"); }), Positioned(bottom: showBelow ? null : -9, top: showBelow ? -9 : null, left: arrowLocalX - 10, child: CustomPaint(size: const Size(20, 10), painter: _ArrowPainter(color: Colors.white.withOpacity(0.9), isPointingUp: showBelow)))]))));
  }
  
  String _generateHtml() {
    String buttonsHtml = "";
    for (var h in widget.hotspots) {
      // Lấy màu và trạng thái từ DeviceManager ngay khi khởi tạo HTML
      final device = deviceManager.getDevice(h.id);
      String hexColor = '#${device.color.value.toRadixString(16).substring(2)}';
      // Nếu đang tắt thì thêm class 'off' ngay từ đầu
      String initialClass = device.isOn ? "droplet" : "droplet off";
      
      buttonsHtml += """<button slot="hotspot-${h.id}" data-position="${h.position}" data-normal="${h.normal}" style="background: transparent; border: none; padding: 0; width: 0; height: 0; position: relative;" onclick="handleClick(event, '${h.id}', this)"><div class="droplet-container"><div id="droplet-${h.id}" class="$initialClass" data-original-color="$hexColor" style="background-color: rgba(255,255,255,0.95); box-shadow: 0 4px 15px ${hexColor}80;"><div class="icon-wrapper" style="color: $hexColor;">${h.svgIcon}</div></div><div id="pulse-${h.id}" class="pulse-ring" style="border-color: $hexColor"></div></div></button>""";
    }
    return """<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"><style>.droplet-container { position: absolute; bottom: 0; left: 50%; transform: translateX(-50%) translateY(-10px); width: 40px; height: 50px; display: flex; justify-content: center; cursor: pointer; } .droplet-container:active { transform: translateX(-50%) translateY(-10px) scale(0.9); } .droplet { width: 36px; height: 36px; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); display: flex; align-items: center; justify-content: center; border: 2px solid white; transition: background-color 0.3s, box-shadow 0.3s; } .icon-wrapper { transform: rotate(45deg); width: 20px; height: 20px; transition: color 0.3s; } .pulse-ring { position: absolute; bottom: -5px; left: 50%; transform: translateX(-50%); width: 10px; height: 4px; border-radius: 50%; border: 2px solid; opacity: 0.6; animation: pulse 2s infinite; } .droplet.off { background-color: #444 !important; box-shadow: none !important; border-color: #666; } .droplet.off .icon-wrapper { color: #888 !important; } .pulse-ring.off { display: none; } @keyframes pulse { 0% { transform: translateX(-50%) scale(0.5); opacity: 1; } 100% { transform: translateX(-50%) scale(2.5); opacity: 0; } }</style>$buttonsHtml<script> function handleClick(event, id, element) { event.stopPropagation(); var rect = element.getBoundingClientRect(); var targetX = rect.left + (rect.width / 2); var targetY = rect.top + (rect.height / 2); var data = { id: id, x: targetX, y: targetY }; SmartLib.postMessage(JSON.stringify(data)); } function setHotspotState(id, isOn) { var droplet = document.getElementById('droplet-' + id); var pulse = document.getElementById('pulse-' + id); var icon = droplet.querySelector('.icon-wrapper'); if (droplet) { if (isOn) { droplet.classList.remove('off'); if(pulse) pulse.classList.remove('off'); var originalColor = droplet.getAttribute('data-original-color'); if(icon) icon.style.color = originalColor; droplet.style.boxShadow = '0 4px 15px ' + originalColor + '80'; } else { droplet.classList.add('off'); if(pulse) pulse.classList.add('off'); if(icon) icon.style.color = ''; droplet.style.boxShadow = ''; } } } function setHotspotColor(id, colorHex) { var droplet = document.getElementById('droplet-' + id); var pulse = document.getElementById('pulse-' + id); var icon = droplet.querySelector('.icon-wrapper'); if (droplet) { droplet.setAttribute('data-original-color', colorHex); if (!droplet.classList.contains('off')) { if(icon) icon.style.color = colorHex; droplet.style.boxShadow = '0 4px 15px ' + colorHex + '80'; if(pulse) pulse.style.borderColor = colorHex; } } } </script>""";
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color; final bool isPointingUp;
  _ArrowPainter({required this.color, required this.isPointingUp});
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = color..style = PaintingStyle.fill; final path = Path(); if (isPointingUp) { path.moveTo(0, size.height); path.lineTo(size.width / 2, 0); path.lineTo(size.width, size.height); } else { path.moveTo(0, 0); path.lineTo(size.width / 2, size.height); path.lineTo(size.width, 0); } path.close(); canvas.drawPath(path, paint); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 