import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class LocalNotificationService {
  // Khởi tạo plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- 1. HÀM KHỞI TẠO (GỌI Ở MAIN) ---
  static Future<void> initialize() async {
    // Cài đặt cho Android (Icon phải trùng tên với icon trong folder android/app/src/main/res/mipmap)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cài đặt cho iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào thông báo
        print("Đã bấm vào thông báo: ${response.payload}");
      },
    );
  }

  // --- 2. HÀM BẮN THÔNG BÁO ---
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Cấu hình chi tiết cho Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'smart_home_channel_id', // ID Kênh (Phải duy nhất)
      'Cảnh báo an ninh', // Tên kênh hiện trong Cài đặt
      channelDescription: 'Thông báo từ hệ thống Smart Home',
      importance: Importance.max, // Mức quan trọng cao nhất (Hiện popup)
      priority: Priority.high, // Ưu tiên cao
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // Cấu hình chi tiết cho iOS
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // --- 3. HÀM XIN QUYỀN (CHO ANDROID 13+) ---
  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }
}