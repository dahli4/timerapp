import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// 백그라운드 작업에서 실행될 콜백 함수
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'timerNotification':
          await _showTimerCompletedNotification(inputData);
          break;
        default:
          break;
      }
      return Future.value(true);
    } catch (e) {
      // 프로덕션에서는 로깅 시스템 사용
      return Future.value(false);
    }
  });
}

// 백그라운드에서 알림을 표시하는 함수
Future<void> _showTimerCompletedNotification(
  Map<String, dynamic>? inputData,
) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Android 초기화
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // SharedPreferences에서 설정 읽기 (백그라운드에서는 직접 접근)
  final prefs = await SharedPreferences.getInstance();
  final useAlarm = prefs.getBool('alarm') ?? true;
  final useVibration = prefs.getBool('vibration') ?? false;

  // 알림이 비활성화되어 있으면 알림 표시하지 않음
  if (!useAlarm) {
    return; // 알림 설정이 꺼져있으면 종료
  }

  final timerTitle = inputData?['timerTitle'] ?? '타이머';
  final timerId = inputData?['timerId'] ?? '';
  final minutes = inputData?['minutes'] ?? 0;
  final seconds = inputData?['seconds'] ?? 0;

  // 백그라운드에서 완료된 타이머 데이터 저장 (SharedPreferences 사용)
  await _saveBackgroundTimerRecord(prefs, timerId, minutes, seconds);

  await flutterLocalNotificationsPlugin.show(
    0,
    '$timerTitle 완료!',
    '설정한 시간이 모두 지났어요!',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_channel',
        '타이머 알림',
        channelDescription: '타이머 종료 시 알림을 표시합니다.',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: useVibration,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        autoCancel: false,
        ongoing: false,
        visibility: NotificationVisibility.public,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        ticker: '$timerTitle 타이머가 종료되었습니다!',
      ),
    ),
  );
}

// 백그라운드에서 완료된 타이머 기록 저장
Future<void> _saveBackgroundTimerRecord(
  SharedPreferences prefs,
  String timerId,
  int minutes,
  int seconds,
) async {
  // 기존 백그라운드 기록들 가져오기
  final existingRecords = prefs.getStringList('background_timer_records') ?? [];

  // 새 기록 추가 (JSON 형태로 저장)
  final newRecord =
      '${DateTime.now().millisecondsSinceEpoch}|$timerId|$minutes|$seconds';
  existingRecords.add(newRecord);

  // SharedPreferences에 저장
  await prefs.setStringList('background_timer_records', existingRecords);
}

// WorkManager를 초기화하는 함수 (Android만)
Future<void> initializeWorkManager() async {
  if (!Platform.isAndroid) return;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // 디버그 모드에서 로그 출력
  );
}

// 백그라운드 타이머 알림을 예약하는 함수 (Android만)
Future<void> scheduleBackgroundTimerNotification(
  String timerTitle,
  String timerId,
  int minutes,
  int totalSeconds,
) async {
  if (!Platform.isAndroid) return;

  await Workmanager().registerOneOffTask(
    'timer_${DateTime.now().millisecondsSinceEpoch}', // 고유한 태스크 ID
    'timerNotification',
    initialDelay: Duration(seconds: totalSeconds), // delay -> initialDelay로 변경
    inputData: {
      'timerTitle': timerTitle,
      'timerId': timerId,
      'minutes': minutes,
      'seconds': 0, // 완료된 타이머이므로 초는 0
    },
  );
  // 백그라운드 타이머 알림 예약 완료
}

// 백그라운드 작업 취소 (Android만)
Future<void> cancelBackgroundTimerNotification() async {
  if (!Platform.isAndroid) return;

  await Workmanager().cancelAll();
  // 모든 백그라운드 타이머 알림 취소 완료
}
