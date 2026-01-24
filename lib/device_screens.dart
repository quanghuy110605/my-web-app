import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'device_data.dart'; // <--- IMPORT BỘ NÃO

class DeviceListScreen extends StatelessWidget { // Đổi thành StatelessWidget
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Tất cả thiết bị"), backgroundColor: Colors.black, elevation: 0, centerTitle: false),
      
      // Lắng nghe thay đổi từ DeviceManager
      body: ListenableBuilder(
        listenable: deviceManager,
        builder: (context, _) {
          final devices = deviceManager.devices; // Lấy danh sách thật

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: device.isOn ? device.color.withValues(alpha: 0.2) : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(device.icon, color: device.isOn ? device.color : Colors.grey),
                  ),
                  title: Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(device.isOn ? "Đang bật" : "Đang tắt", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  trailing: Switch(
                    value: device.isOn,
                    activeColor: Colors.white,
                    activeTrackColor: device.color,
                    inactiveTrackColor: Colors.grey[800],
                    onChanged: (val) {
                      // GỌI HÀM UPDATE CỦA MANAGER
                      // Điều này sẽ tự động cập nhật cả bên 3D
                      deviceManager.toggleDevice(device.id, val);
                    },
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceDetailScreen(deviceName: device.name, color: device.color)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ... (Giữ nguyên class DeviceDetailScreen và ScheduleScreen như bài trước) ...
// (Phần biểu đồ chi tiết bạn đã làm ở bước trước, không cần sửa logic)
// Copy lại phần DeviceDetailScreen và ScheduleScreen y hệt code trước vào đây
class DeviceDetailScreen extends StatefulWidget {
  final String deviceName;
  final Color color;
  const DeviceDetailScreen({super.key, required this.deviceName, required this.color});
  @override State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}
class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  DateTime selectedDate = DateTime.now();
  List<FlSpot> hourlySpots = [];
  @override void initState() { super.initState(); _generateData(selectedDate); }
  void _generateData(DateTime date) {
    final random = Random(date.year * 1000 + date.day);
    List<FlSpot> spots = [];
    for (int i = 0; i < 24; i++) { double value; if (i > 17 && i < 23) { value = 40 + random.nextDouble() * 20; } else { value = random.nextDouble() * 10; } spots.add(FlSpot(i.toDouble(), value)); }
    setState(() => hourlySpots = spots);
  }
  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now(), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: widget.color, onPrimary: Colors.white)), child: child!),);
    if (picked != null) { setState(() => selectedDate = picked); _generateData(picked); }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.deviceName), iconTheme: const IconThemeData(color: Colors.white)), body: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [InkWell(onTap: _pickDate, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month, color: widget.color, size: 20), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, color: Colors.white54)]))), const SizedBox(height: 30), const Text("Thống kê năng lượng (Watt)", style: TextStyle(color: Colors.white70)), const SizedBox(height: 20), SizedBox(height: 250, child: LineChart(LineChartData(minX: 0, maxX: 23, minY: 0, maxY: 70, gridData: const FlGridData(show: false), borderData: FlBorderData(show: false), titlesData: FlTitlesData(leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 4, getTitlesWidget: (value, meta) { int h = value.toInt(); return Padding(padding: const EdgeInsets.only(top: 10.0), child: Text('${h}h', style: const TextStyle(color: Colors.white38, fontSize: 12))); }))), lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(tooltipBgColor: Colors.grey[800]!, tooltipRoundedRadius: 8, getTooltipItems: (spots) { return spots.map((spot) => LineTooltipItem('${spot.y.toInt()} W', TextStyle(color: widget.color, fontWeight: FontWeight.bold))).toList(); }), handleBuiltInTouches: true), lineBarsData: [LineChartBarData(spots: hourlySpots, isCurved: true, curveSmoothness: 0.35, color: widget.color, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [widget.color.withValues(alpha: 0.3), widget.color.withValues(alpha: 0.0)])))]))), const SizedBox(height: 30), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.bolt, color: Colors.yellow, size: 30), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text("Tổng tiêu thụ", style: TextStyle(color: Colors.white70)), Text("4.5 kWh", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))])]))])));
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, appBar: AppBar(title: const Text("Lịch trình"), backgroundColor: Colors.black, elevation: 0, centerTitle: false), floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: Colors.blueAccent, child: const Icon(Icons.add, color: Colors.white)), body: ListView(padding: const EdgeInsets.all(16), children: [_buildScheduleItem("07:00 AM", "Bật Đèn Trần", true), _buildScheduleItem("08:30 AM", "Mở Rèm Cửa", true), _buildScheduleItem("06:00 PM", "Bật Tivi & Đèn", false), _buildScheduleItem("10:00 PM", "Tắt toàn bộ thiết bị", true)])); }
  Widget _buildScheduleItem(String time, String action, bool isActive) { return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: isActive ? Colors.blueAccent : Colors.grey, width: 4))), child: Row(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(action, style: const TextStyle(color: Colors.white70))]), const Spacer(), Switch(value: isActive, onChanged: (v){}, activeColor: Colors.white, activeTrackColor: Colors.blueAccent, inactiveTrackColor: Colors.grey[800])])); }
}