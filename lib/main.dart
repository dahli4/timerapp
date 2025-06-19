import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timerapp/utils/notification_helper.dart';
import 'utils/background_notification_helper.dart';
import 'utils/background_sync_helper.dart';
import 'app/main_tab_controller.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/study_timer_model.dart';
import 'data/study_record_model.dart';
import 'data/daily_goal_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  await Hive.initFlutter();
  Hive.registerAdapter(StudyTimerModelAdapter());
  Hive.registerAdapter(StudyRecordModelAdapter());
  Hive.registerAdapter(DailyGoalModelAdapter());
  await Hive.openBox<StudyTimerModel>('timers');
  await Hive.openBox<StudyRecordModel>('records');
  await Hive.openBox<DailyGoalModel>('daily_goals');

  // 🎬 아이패드 스크린샷용 더미 데이터 생성
  // await DummyDataHelper.generateDummyData();

  await initializeNotifications();

  // WorkManager 초기화 (Android만)
  if (Platform.isAndroid) {
    await initializeWorkManager();
  }

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
          title: '모딧',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'), // 한국어
            Locale('en', 'US'), // 영어
          ],
          locale: const Locale('ko', 'KR'), // 기본 로케일을 한국어로 설정
          theme: ThemeData.light().copyWith(
            textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'IM_Hyemin',
            ),
            colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: const Color(0xFF5A9FD4), // 라이트블루
              secondary: const Color(0xFF87CEEB), // 연한 라이트블루
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2C3E50), // 다크 블루그레이
              surface: const Color(0xFFF5F3F0), // 연한 베이지
            ),
            scaffoldBackgroundColor: const Color(0xFFF9F7F4), // 베이지 배경
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF9F7F4), // 베이지 배경
              foregroundColor: Color(0xFF2C3E50), // 다크 블루그레이
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontFamily: 'IM_Hyemin',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF5A9FD4), // 라이트블루
                disabledBackgroundColor: const Color(0xFFBDC3C7),
                disabledForegroundColor: Colors.white70,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A9FD4), // 라이트블루
              ),
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Color(0xFFF9F7F4), // 베이지 배경
              surfaceTintColor: Colors.transparent,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF5A9FD4); // 라이트블루
                }
                return const Color(0xFFBDC3C7);
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF87CEEB); // 연한 라이트블루
                }
                return const Color(0xFFECF0F1);
              }),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'IM_Hyemin',
              bodyColor: const Color(0xFFF5F3F0), // 연한 베이지
              displayColor: const Color(0xFFF5F3F0), // 연한 베이지
            ),
            colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: const Color(0xFF87CEEB), // 스카이블루 (다크모드용)
              secondary: const Color(0xFF5A9FD4), // 라이트블루
              onPrimary: const Color(0xFF2C3E50), // 다크 블루그레이
              onSurface: const Color(0xFFF5F3F0), // 연한 베이지 (텍스트용)
              surface: const Color(0xFF3E3B36), // 다크 베이지
            ),
            scaffoldBackgroundColor: const Color(0xFF2F2D28), // 더 진한 다크 베이지
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2F2D28), // 더 진한 다크 베이지
              foregroundColor: Color(0xFFF5F3F0), // 연한 베이지 (텍스트)
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontFamily: 'IM_Hyemin',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF5F3F0),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF5A9FD4), // 라이트블루 유지
                disabledBackgroundColor: const Color(0xFF6B6B6B),
                disabledForegroundColor: const Color(0xFFBDBDBD),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF87CEEB), // 스카이블루
              ),
            ),
            cardTheme: const CardTheme(
              color: Color(0xFF3E3B36), // 다크 베이지
              elevation: 2,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Color(0xFF3E3B36), // 다크 베이지
              surfaceTintColor: Colors.transparent,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF87CEEB); // 스카이블루
                }
                return const Color(0xFF6B6B6B);
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF5A9FD4); // 라이트블루
                }
                return const Color(0xFF4A4A4A);
              }),
            ),
          ),
          themeMode: mode,
          home: const AppWrapper(),
        );
      },
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final onboardingCompleted = snapshot.data ?? false;
        if (onboardingCompleted) {
          return const StudyTimerApp();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}

class StudyTimerApp extends StatefulWidget {
  const StudyTimerApp({super.key});

  @override
  State<StudyTimerApp> createState() => _StudyTimerAppState();
}

class _StudyTimerAppState extends State<StudyTimerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 앱 시작 시 백그라운드 기록 동기화
    _syncBackgroundRecords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때 백그라운드 기록 동기화
      _syncBackgroundRecords();
    }
  }

  Future<void> _syncBackgroundRecords() async {
    await BackgroundSyncHelper.syncBackgroundRecords();
  }

  @override
  Widget build(BuildContext context) {
    return const MainTabController();
  }
}
