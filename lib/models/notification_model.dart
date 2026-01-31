import 'package:flutter/material.dart';
import '../services/local_notification_service.dart'; // <--- IMPORT SERVICE VỪA TẠO

enum NotiType { info, success, alert }

class SmartNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotiType type;
  bool isRead;

  SmartNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final List<SmartNotification> notifications = [];

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  // --- CẬP NHẬT HÀM NÀY ---
  void addNotification(String title, String body, {NotiType type = NotiType.info}) {
    // 1. Lưu vào danh sách trong App
    final newNoti = SmartNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      time: DateTime.now(),
      type: type,
    );
    notifications.insert(0, newNoti);
    notifyListeners();

    // 2. BẮN THÔNG BÁO HỆ THỐNG (SYSTEM TRAY)
    LocalNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID dạng int
      title: title, 
      body: body
    );
  }

  void markAllAsRead() {
    for (var n in notifications) n.isRead = true;
    notifyListeners();
  }

  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    notifications.clear();
    notifyListeners();
  }
}

final notificationManager = NotificationManager();