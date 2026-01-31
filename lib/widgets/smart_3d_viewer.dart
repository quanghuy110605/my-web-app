import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/device_model.dart'; 

class SmartIcons {
  static const String bulb = 'lightbulb';
  static const String fan = 'cyclone'; 
  static const String heater = 'thermostat'; 
  static const String curtain = 'view_headline';
  static const String ac = 'ac_unit';
  static const String doorOpen = 'meeting_room';   
  static const String doorClosed = 'door_front';   
}

typedef SmartPanelBuilder = Widget Function(BuildContext context, Function(bool) toggle3D, Function(Color) changeColor);

class SmartHotspot {
  final String id;
  final String position;
  final String normal;
  final SmartPanelBuilder panelBuilder;
  final String iconName; 
  final Color color;
  final Widget? customWidget; 

  SmartHotspot({
    required this.id,
    required this.position,
    this.normal = '0m 1m 0m',
    required this.panelBuilder,
    this.iconName = 'lightbulb', 
    this.color = Colors.blueAccent,
    this.customWidget, 
  });
}

class SmartHomeViewer extends StatefulWidget {
  final String src;
  final List<SmartHotspot> hotspots;
  final double yOffset;
  final Function(String position, String normal)? onModelTap;
  final String? cameraOrbit;      
  final String? minCameraOrbit;   
  final String? maxCameraOrbit;   

  const SmartHomeViewer({
    super.key, 
    required this.src, 
    required this.hotspots,
    this.yOffset = 0.0, 
    this.onModelTap,
    this.cameraOrbit,
    this.minCameraOrbit,
    this.maxCameraOrbit,
  });

  @override State<SmartHomeViewer> createState() => _SmartHomeViewerState();
}

class _SmartHomeViewerState extends State<SmartHomeViewer> {
  String? activeHotspotId;
  Offset panelPosition = Offset.zero;
  bool isPanelVisible = false;
  WebViewController? _webController;

  void _onDeviceChanged() {
    if (_webController == null) return;
    
    // 1. Cập nhật các Hotspot
    for (var hotspot in widget.hotspots) {
      if (!hotspot.id.startsWith("map_point_") && !hotspot.id.startsWith("p_")) {
          try {
            final device = deviceManager.getDevice(hotspot.id);
            if (hotspot.customWidget == null) {
                _webController!.runJavaScript("setHotspotState('${hotspot.id}', ${device.isOn})");
                String hex = '#${device.color.value.toRadixString(16).substring(2)}';
                _webController!.runJavaScript("setHotspotColor('${hotspot.id}', '$hex')");
                _webController!.runJavaScript("setHotspotIcon('${hotspot.id}', '${hotspot.iconName}')");
            }
          } catch (e) {}
      }
    }

    // 2. XỬ LÝ GARA Ô TÔ (TÌM MỌI THIẾT BỊ CÓ CHỮ "Gara")
    try {
      // Tìm thiết bị đầu tiên có tên chứa "Gara"
      final garaDevice = deviceManager.devices.firstWhere(
        (d) => d.name.contains("Gara"), 
        orElse: () => SmartDevice(id: 'null', name: 'null', icon: Icons.error)
      );

      if (garaDevice.name != 'null') {
         // Nếu tìm thấy -> Điều khiển xe 3D
         _webController!.runJavaScript("forceSetObjectVisibility('Car_Main', ${garaDevice.isOn})");
         if (garaDevice.isOn) {
            String hex = '#${garaDevice.color.value.toRadixString(16).substring(2)}';
            _webController!.runJavaScript("setObjectColor('Car_Main', '$hex')");
         }
      } else {
         // Không có xe nào -> Ẩn
         _webController!.runJavaScript("forceSetObjectVisibility('Car_Main', false)");
      }
    } catch (e) {
      print("Lỗi render xe: $e");
    }
  }

  @override void initState() { super.initState(); deviceManager.addListener(_onDeviceChanged); }
  @override void dispose() { deviceManager.removeListener(_onDeviceChanged); super.dispose(); }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        Listener(
          onPointerDown: (_) { if (isPanelVisible) setState(() => isPanelVisible = false); },
          child: ModelViewer(
            key: ValueKey("${widget.hotspots.length}_${widget.cameraOrbit}"), 
            src: widget.src,
            alt: "Smart Home",
            backgroundColor: Colors.black,
            autoRotate: false, 
            cameraControls: true, 
            disableZoom: false, 
            disablePan: false,
            cameraOrbit: widget.cameraOrbit,
            minCameraOrbit: widget.minCameraOrbit,
            maxCameraOrbit: widget.maxCameraOrbit,
            onWebViewCreated: (c) { 
              _webController = c; 
              Future.delayed(const Duration(seconds: 1), _onDeviceChanged); 
            },
            innerModelViewerHtml: _generateHtml(),
            javascriptChannels: { 
              JavascriptChannel('SmartLib', onMessageReceived: (message) { 
                try { 
                  final data = jsonDecode(message.message); 
                  if (data['type'] == 'hotspot') { 
                    setState(() { 
                      activeHotspotId = data['id']; 
                      panelPosition = Offset(data['x'].toDouble(), data['y'].toDouble() + widget.yOffset); 
                      final clickedHotspot = widget.hotspots.firstWhere((h) => h.id == activeHotspotId);
                      if (clickedHotspot.customWidget == null) {
                          isPanelVisible = true; 
                      }
                    }); 
                  } else if (data['type'] == 'model') { 
                    if (widget.onModelTap != null) widget.onModelTap!(data['position'], data['normal']); 
                  } 
                } catch (e) {} 
              }) 
            },
          ),
        ),
        if (isPanelVisible && activeHotspotId != null) _buildOverlayPanel(constraints),
      ]);
    });
  }

  Widget _buildOverlayPanel(BoxConstraints constraints) {
    final hotspot = widget.hotspots.firstWhere((h) => h.id == activeHotspotId, orElse: () => widget.hotspots[0]);
    if (hotspot.customWidget != null) return const SizedBox(); 

    const double panelWidth = 280; 
    double panelLeft = panelPosition.dx - (panelWidth / 2); 
    if (panelLeft < 10) panelLeft = 10; 
    if (panelLeft + panelWidth > constraints.maxWidth - 10) panelLeft = constraints.maxWidth - panelWidth - 10; 
    
    bool showBelow = panelPosition.dy < 200; 
    double? posTop;
    double? posBottom;

    if (showBelow) { posTop = panelPosition.dy - 5; } else { posBottom = constraints.maxHeight - panelPosition.dy - 5 ; }

    double arrowLocalX = panelPosition.dx - panelLeft; 
    if (arrowLocalX < 24) arrowLocalX = 24; 
    if (arrowLocalX > panelWidth - 24) arrowLocalX = panelWidth - 24;
    
    return Positioned(
      top: posTop, bottom: posBottom, left: panelLeft, 
      child: GestureDetector(
        onTap: () {}, 
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0), 
          duration: const Duration(milliseconds: 250), 
          curve: Curves.easeOutBack, 
          builder: (context, value, child) => Transform.scale(
            scale: value, 
            alignment: Alignment(((arrowLocalX / panelWidth) * 2) - 1, showBelow ? -1.0 : 1.0), 
            child: child
          ), 
          child: Stack(
            clipBehavior: Clip.none, 
            children: [
              hotspot.panelBuilder(
                context, 
                (bool isOn) { _webController?.runJavaScript("setHotspotState('${hotspot.id}', $isOn)"); }, 
                (Color c) { 
                  String hex = '#${c.value.toRadixString(16).substring(2)}'; 
                  _webController?.runJavaScript("setHotspotColor('${hotspot.id}', '$hex')"); 
                }
              ), 
              Positioned(
                bottom: showBelow ? null : -9, top: showBelow ? -9 : null, left: arrowLocalX - 10, 
                child: CustomPaint(size: const Size(20, 10), painter: _ArrowPainter(color: Colors.white.withOpacity(0.9), isPointingUp: showBelow))
              )
            ]
          )
        )
      )
    );
  }

  String _generateHtml() {
    String slotsHtml = "";
    for (var h in widget.hotspots) {
      if (h.id.startsWith("map_point_")) {
          slotsHtml += """<button slot="hotspot-${h.id}" data-position="${h.position}" data-normal="${h.normal}" style="background: transparent; border: none; padding: 0;" onclick="handleClick(event, '${h.id}', this)"><div style="width: 20px; height: 20px; background: red; border: 2px solid white; border-radius: 50%; box-shadow: 0 0 5px black;"></div></button>""";
      } else if (h.id.startsWith("p_")) {
          slotsHtml += """<button slot="hotspot-${h.id}" data-position="${h.position}" data-normal="${h.normal}" style="background: transparent; border: none; padding: 0;"><div style="background: rgba(0,0,0,0.7); border: 1px solid #00ff00; border-radius: 12px; padding: 4px 8px; display: flex; align-items: center;"><span class="material-icons" style="color: #00ff00; font-size: 16px; margin-right: 4px;">person</span><span style="color: white; font-weight: bold; font-size: 12px;">AI</span></div></button>""";
      } else {
          final device = deviceManager.getDevice(h.id);
          String hexColor = '#${device.color.value.toRadixString(16).substring(2)}';
          String initialClass = device.isOn ? "droplet" : "droplet off";
          slotsHtml += """<button slot="hotspot-${h.id}" data-position="${h.position}" data-normal="${h.normal}" style="background: transparent; border: none; padding: 0; width: 0; height: 0; position: relative;" onclick="handleClick(event, '${h.id}', this)"><div class="droplet-container"><div id="droplet-${h.id}" class="$initialClass" data-original-color="$hexColor" style="background-color: rgba(255,255,255,0.95); box-shadow: 0 4px 15px ${hexColor}80;"><span class="material-icons icon-wrapper" style="color: $hexColor; font-size: 20px;">${h.iconName}</span></div><div id="pulse-${h.id}" class="pulse-ring" style="border-color: $hexColor"></div></div></button>""";
      }
    }

    return """
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
      <style> 
        model-viewer { cursor: crosshair; } 
        .droplet-container { position: absolute; bottom: 0; left: 50%; transform: translateX(-50%) translateY(5px); width: 40px; height: 50px; display: flex; justify-content: center; cursor: pointer; pointer-events: auto; } 
        .droplet-container:active { transform: translateX(-50%) translateY(5px) scale(0.9); } 
        .droplet { width: 36px; height: 36px; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); display: flex; align-items: center; justify-content: center; border: 2px solid white; transition: background-color 0.3s, box-shadow 0.3s; } 
        .icon-wrapper { transform: rotate(45deg); transition: color 0.3s; line-height: 1; display: block; } 
        .pulse-ring { position: absolute; bottom: -5px; left: 50%; transform: translateX(-50%); width: 10px; height: 4px; border-radius: 50%; border: 2px solid; opacity: 0.6; animation: pulse 2s infinite; } 
        .droplet.off { background-color: #444 !important; box-shadow: none !important; border-color: #666; } 
        .droplet.off .icon-wrapper { color: #888 !important; } 
        .pulse-ring.off { display: none; } 
        @keyframes pulse { 0% { transform: translateX(-50%) scale(0.5); opacity: 1; } 100% { transform: translateX(-50%) scale(2.5); opacity: 0; } } 
      </style>
      $slotsHtml
      <script>
        const modelViewer = document.querySelector('model-viewer');
        let startX = 0, startY = 0, startTime = 0;
        modelViewer.addEventListener('mousedown', (event) => { startX = event.clientX; startY = event.clientY; startTime = Date.now(); }, true);
        modelViewer.addEventListener('mouseup', (event) => { const diffX = Math.abs(event.clientX - startX); const diffY = Math.abs(event.clientY - startY); const timeDiff = Date.now() - startTime; if (diffX < 5 && diffY < 5 && timeDiff < 500) { let hit = modelViewer.positionAndNormalFromPoint(event.clientX, event.clientY); if (hit != null) { var data = { type: 'model', position: hit.position.toString(), normal: hit.normal.toString() }; try { SmartLib.postMessage(JSON.stringify(data)); } catch (e) {} } } }, true);
        function handleClick(event, id, element) { event.stopPropagation(); var rect = element.getBoundingClientRect(); var targetX = rect.left + (rect.width / 2); var targetY = rect.top + (rect.height / 2); var data = { type: 'hotspot', id: id, x: targetX, y: targetY }; try { SmartLib.postMessage(JSON.stringify(data)); } catch(e){} }
        function setHotspotState(id, isOn) { var droplet = document.getElementById('droplet-' + id); var pulse = document.getElementById('pulse-' + id); var icon = droplet ? droplet.querySelector('.icon-wrapper') : null; if (droplet) { if (isOn) { droplet.classList.remove('off'); if(pulse) pulse.classList.remove('off'); var originalColor = droplet.getAttribute('data-original-color'); if(icon) icon.style.color = originalColor; droplet.style.boxShadow = '0 4px 15px ' + originalColor + '80'; } else { droplet.classList.add('off'); if(pulse) pulse.classList.add('off'); if(icon) icon.style.color = ''; droplet.style.boxShadow = ''; } } }
        function setHotspotColor(id, colorHex) { var droplet = document.getElementById('droplet-' + id); var pulse = document.getElementById('pulse-' + id); var icon = droplet ? droplet.querySelector('.icon-wrapper') : null; if (droplet) { droplet.setAttribute('data-original-color', colorHex); if (!droplet.classList.contains('off')) { if(icon) icon.style.color = colorHex; droplet.style.boxShadow = '0 4px 15px ' + colorHex + '80'; if(pulse) pulse.style.borderColor = colorHex; } } }
        function setHotspotIcon(id, iconName) { var droplet = document.getElementById('droplet-' + id); if (droplet) { var iconSpan = droplet.querySelector('.material-icons'); if (iconSpan) iconSpan.textContent = iconName; } }
        function forceSetObjectVisibility(materialName, isVisible) { let attempts = 0; const interval = setInterval(() => { attempts++; const model = modelViewer.model; if (model) { const foundMaterial = model.materials.find(m => m.name === materialName); if (foundMaterial) { const currentColor = foundMaterial.pbrMetallicRoughness.baseColorFactor; currentColor[3] = isVisible ? 1.0 : 0.0; foundMaterial.pbrMetallicRoughness.setBaseColorFactor(currentColor); foundMaterial.setAlphaMode(isVisible ? 'OPAQUE' : 'BLEND'); if (attempts > 5) clearInterval(interval); return; } } if (attempts > 20) clearInterval(interval); }, 200); }
        function setObjectColor(materialName, hexColor) { const model = modelViewer.model; if (!model) return; const foundMaterial = model.materials.find(m => m.name === materialName); if (foundMaterial) { const r = parseInt(hexColor.substr(1, 2), 16) / 255; const g = parseInt(hexColor.substr(3, 2), 16) / 255; const b = parseInt(hexColor.substr(5, 2), 16) / 255; const currentAlpha = foundMaterial.pbrMetallicRoughness.baseColorFactor[3]; foundMaterial.pbrMetallicRoughness.setBaseColorFactor([r, g, b, currentAlpha]); } }
        forceSetObjectVisibility('Car_Main', false);
        modelViewer.addEventListener('load', () => { forceSetObjectVisibility('Car_Main', false); });
      </script>
    """;
  }
}

class _ArrowPainter extends CustomPainter { 
  final Color color; final bool isPointingUp; 
  _ArrowPainter({required this.color, required this.isPointingUp}); 
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = color..style = PaintingStyle.fill; final path = Path(); if (isPointingUp) { path.moveTo(0, size.height); path.lineTo(size.width / 2, 0); path.lineTo(size.width, size.height); } else { path.moveTo(0, 0); path.lineTo(size.width / 2, size.height); path.lineTo(size.width, 0); } path.close(); canvas.drawPath(path, paint); } 
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; 
}