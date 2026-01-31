import 'package:flutter/material.dart';

class PeopleManager extends ChangeNotifier {
  static final PeopleManager _instance = PeopleManager._internal();
  factory PeopleManager() => _instance;
  PeopleManager._internal();

  // Lưu trữ số lượng người tại các phòng
  final Map<String, int> roomCounts = {
    "Phòng Khách": 0,
    "Phòng Ngủ": 0,
    "Nhà Bếp": 0,
    "Sân Vườn": 0,
    "WC": 0,
  };

  // Hàm cập nhật số người
  void updateCount(String room, int count) {
    if (roomCounts.containsKey(room)) {
      roomCounts[room] = count;
      notifyListeners(); // Báo cho màn hình 3D vẽ lại
    }
  }
}

final peopleManager = PeopleManager();