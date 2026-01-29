import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniChart extends StatelessWidget {
  final List<double> data; // Dữ liệu đầu vào
  final Color color;       // Màu biểu đồ
  final String unit;       // Đơn vị (%, °C, ...)

  const MiniChart({
    super.key, 
    required this.data, 
    required this.color, 
    this.unit = ''
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Lịch sử hoạt động (24h)", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100, // Chiều cao biểu đồ
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false), // Ẩn lưới
              titlesData: const FlTitlesData(show: false), // Ẩn chữ trục X/Y
              borderData: FlBorderData(show: false), // Ẩn khung viền
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()}$unit',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value);
                  }).toList(),
                  isCurved: true, // Đường cong mềm mại
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), // Ẩn dấu chấm
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.2), // Màu nền mờ bên dưới
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}