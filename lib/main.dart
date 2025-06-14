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
  await Hive.openBox<StudyTimerModel>('timers');
  await Hive.openBox<StudyRecordModel>('records');
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
          title: 'Timer App',
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
            colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: Colors.grey.shade700,
              secondary: Colors.grey.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey.shade700,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white70,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.grey.shade700;
                }
                return Colors.grey.shade400;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.grey.shade300;
                }
                return Colors.grey.shade200;
              }),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.grey.shade300,
              secondary: Colors.grey.shade400,
              onPrimary: Colors.black87,
              onSurface: Colors.white,
              surface: Colors.grey.shade900,
            ),
            scaffoldBackgroundColor: Colors.grey.shade900,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.grey.shade300,
                disabledBackgroundColor: Colors.grey.shade600,
                disabledForegroundColor: Colors.grey.shade400,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade300,
              ),
            ),
            cardTheme: CardTheme(color: Colors.grey.shade800, elevation: 2),
            dialogTheme: DialogTheme(
              backgroundColor: Colors.grey.shade800,
              surfaceTintColor: Colors.transparent,
            ),
            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.grey.shade300;
                }
                return Colors.grey.shade600;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.grey.shade800; // 다크모드에서 더 어둡게
                }
                return Colors.grey.shade700;
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
