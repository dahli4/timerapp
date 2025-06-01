import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  // Android 13+ 알림 권한 요청
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // 안드로이드 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'timer_channel', // id
    '타이머 알림', // name
    description: '타이머 종료 시 알림을 표시합니다.', // description
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  // 안드로이드용 채널 생성
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  // 알림 클릭 시 앱 열기 핸들러
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint('Notification clicked: ${response.payload}');
      // 필요하면 여기서 추가 처리
    },
  );

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // 한국 시간대로 설정

  // 권한 상태 확인 및 로그
  final notificationStatus = await Permission.notification.status;
  debugPrint('알림 권한 상태: $notificationStatus');
}

Future<void> scheduleTimerNotification(int seconds) async {
  final prefs = await SharedPreferences.getInstance();
  final useAlarm = prefs.getBool('alarm') ?? true;
  final useVibration = prefs.getBool('vibration') ?? false;

  if (!useAlarm) {
    return; // 알림 사용하지 않음으로 설정했으면 종료
  }

  final scheduledTime = tz.TZDateTime.now(
    tz.local,
  ).add(Duration(seconds: seconds));

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    '타이머 종료',
    '설정한 시간이 모두 지났어요!',
    scheduledTime,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_channel',
        '타이머 알림',
        channelDescription: '타이머 종료 시 알림을 표시합니다.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: useVibration,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true, // 화면이 꺼져 있어도 표시
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    // Android 12 이상에서는 정확한 알림을 위해 설정
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );

  debugPrint('알림 예약됨: ${scheduledTime.toString()}');
}

Future<void> cancelTimerNotification() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}

// 알림 권한 확인
Future<bool> hasNotificationPermission() async {
  final status = await Permission.notification.status;
  return status.isGranted;
}

// 테스트 알림 (디버깅용)
Future<void> showTestNotification() async {
  if (!await hasNotificationPermission()) {
    debugPrint('알림 권한이 없습니다.');
    return;
  }

  await flutterLocalNotificationsPlugin.show(
    999, // 테스트용 ID
    '테스트 알림',
    '알림이 정상적으로 작동합니다!',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_channel',
        '타이머 알림',
        channelDescription: '타이머 종료 시 알림을 표시합니다.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
  debugPrint('테스트 알림 전송됨');
}
