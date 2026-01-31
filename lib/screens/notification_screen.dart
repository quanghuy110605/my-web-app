import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Nếu báo đỏ dòng này, chạy lệnh: flutter pub add intl
import '../models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blueAccent),
            tooltip: "Đã đọc tất cả",
            onPressed: () => notificationManager.markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: "Xóa tất cả",
            onPressed: () => notificationManager.clearAll(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: notificationManager,
        builder: (context, _) {
          if (notificationManager.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 20),
                  const Text("Không có thông báo nào", style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificationManager.notifications.length,
            itemBuilder: (context, index) {
              final noti = notificationManager.notifications[index];
              return Dismissible(
                key: Key(noti.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  notificationManager.removeNotification(noti.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: noti.isRead ? Colors.grey[900] : Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: noti.isRead 
                        ? null 
                        : Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getIconColor(noti.type).withOpacity(0.2),
                      ),
                      child: Icon(_getIcon(noti.type), color: _getIconColor(noti.type)),
                    ),
                    title: Text(
                      noti.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(noti.body, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('HH:mm - dd/MM').format(noti.time),
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                    onTap: () {
                      noti.isRead = true;
                      notificationManager.notifyListeners();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(NotiType type) {
    switch (type) {
      case NotiType.alert: return Icons.warning_amber_rounded;
      case NotiType.success: return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  Color _getIconColor(NotiType type) {
    switch (type) {
      case NotiType.alert: return Colors.redAccent;
      case NotiType.success: return Colors.greenAccent;
      default: return Colors.blueAccent;
    }
  }
}