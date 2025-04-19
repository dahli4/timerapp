import 'package:flutter/material.dart';
import 'app/main_tab_controller.dart'; // 경로 수정

void main() {
  runApp(const StudyTimerApp());
}

class StudyTimerApp extends StatelessWidget {
  const StudyTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공시생 타이머',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.indigo,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MainTabController(),
    );
  }
}
