import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BasePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String room; // <--- THÊM BIẾN NÀY
  final bool isOn;
  final Function(bool) onToggle;
  final Widget child;
  final bool isChartMode;
  final VoidCallback? onChartClick;

  const BasePanel({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.room, // <--- THÊM VÀO CONSTRUCTOR
    required this.isOn,
    required this.onToggle,
    required this.child,
    this.isChartMode = false,
    this.onChartClick,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isOn ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: isOn ? color : Colors.grey, size: 24)
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column( // Sửa thành Column để hiện 2 dòng
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis),
                        // HIỆN TÊN PHÒNG Ở ĐÂY
                        Text(room, style: TextStyle(fontSize: 12, color: Colors.grey[600])), 
                      ],
                    )
                  ),
                  
                  if (onChartClick != null)
                    IconButton(icon: Icon(isChartMode ? Icons.close : Icons.bar_chart, color: Colors.grey), onPressed: onChartClick, constraints: const BoxConstraints(), padding: EdgeInsets.zero),

                  Switch(value: isOn, activeColor: Colors.white, activeTrackColor: color, inactiveTrackColor: Colors.grey.shade300, onChanged: onToggle),
                ],
              ),
              
              if (isOn) ...[const SizedBox(height: 12), AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child)]
            ],
          ),
        ),
      ),
    );
  }
}