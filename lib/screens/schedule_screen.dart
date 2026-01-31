import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Lịch trình"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time, 
              size: 80, 
              color: Colors.grey[800]
            ),
            const SizedBox(height: 20),
            const Text(
              "Tính năng đang phát triển...",
              style: TextStyle(
                color: Colors.white54, 
                fontSize: 16
              ),
            ),
          ],
        ),
      ),
    );
  }
}