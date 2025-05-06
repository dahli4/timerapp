import 'package:flutter/material.dart';
import 'package:timerapp/utils/notification_helper.dart';
import 'app/main_tab_controller.dart'; // 경로 수정
import 'package:hive_flutter/hive_flutter.dart';
import 'data/study_timer_model.dart';
import 'data/study_record_model.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(StudyTimerModelAdapter());
  Hive.registerAdapter(StudyRecordModelAdapter());
  await Hive.openBox<StudyTimerModel>('timers');
  await Hive.openBox<StudyRecordModel>('records');
  await initializeNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Timer App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: MainTabController(), // ← 반드시 메인탭 컨트롤러로!
        );
      },
    );
  }
}
