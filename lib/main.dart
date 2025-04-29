import 'package:flutter/material.dart';
import 'app/main_tab_controller.dart'; // 경로 수정
import 'package:hive_flutter/hive_flutter.dart';
import 'data/study_timer_model.dart';
import 'data/study_record_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(StudyTimerModelAdapter());
  Hive.registerAdapter(StudyRecordModelAdapter());
  await Hive.openBox<StudyTimerModel>('timers');
  await Hive.openBox<StudyRecordModel>('records');
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
        colorScheme: ColorScheme.dark(
          primary: Colors.indigo,
          surface: Colors.grey[900]!,
        ),
        useMaterial3: true,
      ),
      home: const MainTabController(),
    );
  }
}
