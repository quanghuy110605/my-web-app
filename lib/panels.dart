import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart';
import 'device_data.dart'; // <--- IMPORT BỘ NÃO

// ... (Giữ nguyên class BasePanel như cũ, không cần sửa) ...
// Copy lại BasePanel từ code cũ của bạn vào đây
class BasePanel extends StatelessWidget {
  final IconData icon; final Color color; final String title; final bool isOn; final Function(bool) onToggle; final VoidCallback? onInfoClick; final bool isChartMode; final Widget child;
  const BasePanel({super.key, required this.icon, required this.color, required this.title, required this.isOn, required this.onToggle, required this.child, this.onInfoClick, this.isChartMode = false});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 300, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isOn ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: isOn ? color : Colors.grey, size: 24)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))), IconButton(icon: Icon(isChartMode ? Icons.close : Icons.bar_chart_rounded), color: Colors.black54, onPressed: onInfoClick), Switch(value: isOn, activeColor: Colors.white, activeTrackColor: color, inactiveTrackColor: Colors.grey.shade300, onChanged: onToggle)]), const SizedBox(height: 12), AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child)]))));
  }
}

// =============================================================================
// BẢNG ĐIỀU KHIỂN ĐÈN (ĐỒNG BỘ DỮ LIỆU)
// =============================================================================

class SmartLightPanel extends StatefulWidget {
  final Function(bool) onToggle3D;
  final Function(Color) onChangeColor;
  
  const SmartLightPanel({super.key, required this.onToggle3D, required this.onChangeColor});
  
  @override State<SmartLightPanel> createState() => _SmartLightPanelState();
}

class _SmartLightPanelState extends State<SmartLightPanel> {
  // Không cần biến isOn, selectedColor cục bộ nữa
  double brightness = 80;
  bool isChartMode = false;
  DateTime selectedDate = DateTime.now();
  List<double> hourlyUsage = []; 

  final List<Color> colors = [Colors.amber, Colors.redAccent, Colors.lightBlueAccent, Colors.purpleAccent, Colors.grey];

  @override
  void initState() {
    super.initState();
    _generateFakeData(selectedDate);
  }

  void _generateFakeData(DateTime date) { /* ... Logic cũ giữ nguyên ... */ 
    final random = Random(date.year * 10000 + date.month * 100 + date.day);
    List<double> data = [];
    for (int i = 0; i < 24; i++) {
      if (i >= 18 && i <= 23) data.add(30 + random.nextDouble() * 30); else if (i >= 6 && i <= 8) data.add(10 + random.nextDouble() * 20); else data.add(random.nextDouble() * 5); 
    }
    setState(() { hourlyUsage = data; });
  }
  
  Future<void> _pickDate() async { /* ... Logic cũ giữ nguyên ... */ 
     final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now(), builder: (context, child) { return Theme(data: ThemeData.light().copyWith(primaryColor: Colors.amber, colorScheme: ColorScheme.light(primary: Colors.amber)), child: child!); });
    if (picked != null && picked != selectedDate) { setState(() { selectedDate = picked; }); _generateFakeData(picked); }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng ListenableBuilder để lắng nghe thay đổi từ DeviceManager
    return ListenableBuilder(
      listenable: deviceManager,
      builder: (context, _) {
        // Lấy dữ liệu thực tế của đèn 'light_1'
        final device = deviceManager.getDevice('light_1');

        return BasePanel(
          icon: device.icon,
          color: device.color,
          title: device.name,
          isOn: device.isOn,
          isChartMode: isChartMode,
          
          // Khi gạt nút -> Cập nhật vào Manager -> Manager báo lại 3D và Tab Thiết bị
          onToggle: (v) {
            deviceManager.toggleDevice('light_1', v);
            widget.onToggle3D(v); // Gửi lệnh JS xuống 3D
          },
          onInfoClick: () => setState(() => isChartMode = !isChartMode),
          
          child: isChartMode ? _buildChartUI(device.color) : _buildControlUI(device),
        );
      },
    );
  }

  Widget _buildControlUI(SmartDevice device) {
    if (!device.isOn) return const SizedBox(height: 0);

    return Column(
      key: const ValueKey('control'), 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.brightness_6, size: 16, color: Colors.grey),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: const RoundSliderOverlayShape(overlayRadius: 20), activeTrackColor: device.color, inactiveTrackColor: Colors.grey.shade300, thumbColor: Colors.white),
                child: Slider(value: brightness, min: 0, max: 100, onChanged: (v) => setState(() => brightness = v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text("Màu sắc", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: colors.map((c) => _buildColorDot(c, device)).toList(),
        ),
      ],
    );
  }

  // Sửa lại hàm Chart để nhận màu động
  Widget _buildChartUI(Color currentColor) {
    // ... Copy nội dung hàm _buildChartUI cũ vào đây ...
    // ... Chỉ cần thay thế biến 'selectedColor' cũ bằng 'currentColor' ...
    return Column(
      key: const ValueKey('chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickDate,
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: currentColor),
              const SizedBox(width: 5),
              Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const Icon(Icons.arrow_drop_down, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(height: 120, child: BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, maxY: 60, barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(tooltipBgColor: Colors.black87, tooltipPadding: const EdgeInsets.all(5), tooltipMargin: 8, getTooltipItem: (group, groupIndex, rod, rodIndex) { return BarTooltipItem('${rod.toY.toInt()}p', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)); })), titlesData: FlTitlesData(show: true, bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, getTitlesWidget: (value, meta) { int hour = value.toInt(); if (hour % 6 == 0) { return Text('$hour', style: const TextStyle(fontSize: 10, color: Colors.grey)); } return const SizedBox(); })), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))), borderData: FlBorderData(show: false), gridData: const FlGridData(show: false), barGroups: hourlyUsage.asMap().entries.map((entry) { return BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: entry.value, color: currentColor.withValues(alpha: 0.8), width: 6, borderRadius: BorderRadius.circular(2), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 60, color: Colors.grey.withValues(alpha: 0.1)))]); }).toList()))),
      ],
    );
  }

  Widget _buildColorDot(Color c, SmartDevice device) {
    bool isSelected = device.color == c;
    return GestureDetector(
      onTap: () {
        // Cập nhật vào Manager
        deviceManager.changeColor('light_1', c);
        widget.onChangeColor(c); // Gửi lệnh JS xuống 3D
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 36 : 30, height: isSelected ? 36 : 30,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.black54 : Colors.grey.shade300, width: isSelected ? 2 : 1), boxShadow: [if (isSelected) BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]),
      ),
    );
  }
}