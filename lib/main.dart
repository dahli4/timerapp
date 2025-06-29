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
import 'data/timer_group_model.dart';
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
  Hive.registerAdapter(TimerGroupModelAdapter());
  await Hive.openBox<StudyTimerModel>('timers');
  await Hive.openBox<StudyRecordModel>('records');
  await Hive.openBox<DailyGoalModel>('daily_goals');
  await Hive.openBox<TimerGroupModel>('groups');

  // 타이머 데이터 마이그레이션 (무제한 타이머 호환성 수정)
  await _migrateTimerData();

  await initializeNotifications();

  // WorkManager 초기화 (Android만)
  if (Platform.isAndroid) {
    await initializeWorkManager();
  }

  runApp(const MyApp());
}

// 타이머 데이터 마이그레이션 함수 (무제한 타이머 호환성 수정)
Future<void> _migrateTimerData() async {
  try {
    // 타이머 마이그레이션
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final timers = timerBox.values.toList();

    bool timerNeedsMigration = false;
    final migratedTimers = <StudyTimerModel>[];

    for (final timer in timers) {
      // 무제한 타이머로 생성되었지만 durationMinutes가 0이 아닌 경우 수정
      // 또는 일반 타이머로 생성되었지만 무제한 타이머 속성이 잘못된 경우 수정

      // 무제한 타이머의 경우 durationMinutes를 0으로 설정
      if (timer.isInfinite && timer.durationMinutes != 0) {
        final migratedTimer = timer.copyWith(durationMinutes: 0);
        migratedTimers.add(migratedTimer);
        timerNeedsMigration = true;
      }
      // 일반 타이머인데 durationMinutes가 0인 경우 (잘못된 데이터)
      else if (!timer.isInfinite && timer.durationMinutes == 0) {
        // 이런 경우는 무제한 타이머로 변경하거나 기본값(25분) 설정
        // 제목에 "무제한"이 포함되어 있으면 무제한 타이머로 변경
        if (timer.title.contains('무제한') ||
            timer.title.contains('unlimited') ||
            timer.title.contains('infinite')) {
          final migratedTimer = timer.copyWith(
            isInfinite: true,
            durationMinutes: 0,
          );
          migratedTimers.add(migratedTimer);
          timerNeedsMigration = true;
        } else {
          // 그렇지 않으면 기본값 25분으로 설정
          final migratedTimer = timer.copyWith(durationMinutes: 25);
          migratedTimers.add(migratedTimer);
          timerNeedsMigration = true;
        }
      } else {
        migratedTimers.add(timer);
      }
    }

    // 타이머 마이그레이션이 필요한 경우 데이터 업데이트
    if (timerNeedsMigration) {
      await timerBox.clear();
      for (final timer in migratedTimers) {
        await timerBox.add(timer);
      }
      debugPrint('타이머 데이터 마이그레이션 완료: ${migratedTimers.length}개 타이머 처리');
    }

    // 그룹 order 마이그레이션
    final groupBox = Hive.box<TimerGroupModel>('groups');
    final groups = groupBox.values.toList();

    bool groupNeedsMigration = false;
    final migratedGroups = <TimerGroupModel>[];

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      // order가 null인 경우 인덱스를 order로 설정
      if (group.order == null) {
        final migratedGroup = TimerGroupModel(
          id: group.id,
          name: group.name,
          colorHex: group.colorHex,
          createdAt: group.createdAt,
          modifiedAt: group.modifiedAt,
          order: i,
        );
        migratedGroups.add(migratedGroup);
        groupNeedsMigration = true;
      } else {
        migratedGroups.add(group);
      }
    }

    // 그룹 마이그레이션이 필요한 경우 데이터 업데이트
    if (groupNeedsMigration) {
      await groupBox.clear();
      for (final group in migratedGroups) {
        await groupBox.add(group);
      }
      debugPrint('그룹 order 마이그레이션 완료: ${migratedGroups.length}개 그룹 처리');
    }
  } catch (e) {
    debugPrint('데이터 마이그레이션 오류: $e');
  }
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
