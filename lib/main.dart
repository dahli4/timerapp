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
          theme: ThemeData.light().copyWith(
            colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: Colors.blueAccent, // 버튼 등 주요 색상
              secondary: Colors.amber,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // 버튼 텍스트
                backgroundColor: Colors.blueAccent, // 버튼 배경
                disabledBackgroundColor: Colors.blueAccent.withOpacity(0.5),
                disabledForegroundColor: Colors.white70,
                shadowColor: Colors.blueAccent.withOpacity(0.4),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, // 텍스트버튼 색상
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.blueAccent, // 버튼 등 주요 색상
              secondary: Colors.amber, // 필요시 보조색
              onPrimary: Colors.white, // 버튼 위 텍스트
              onSurface: Colors.white, // 일반 텍스트
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // 버튼 텍스트
                backgroundColor: Colors.blueAccent, // 버튼 배경
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber, // 텍스트버튼 색상
              ),
            ),
            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.grey[900],
            ), // 다이얼로그 배경
          ),
          themeMode: mode,
          home: MainTabController(),
        );
      },
    );
  }
}
