import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  // Android 13+ 알림 권한 요청 (Android만)
  if (Platform.isAndroid && await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // 정확한 알림 권한 요청 (Android 12+만)
  if (Platform.isAndroid) {
    await requestExactAlarmPermission();
  }

  // 안드로이드 채널 생성
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'timer_channel', // id
    '타이머 알림', // name
    description: '타이머 종료 시 알림을 표시합니다.', // description
    importance: Importance.max, // max로 변경
    enableVibration: true,
    playSound: true,
    showBadge: true,
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
    defaultPresentAlert: true, // 포그라운드에서도 알림 표시
    defaultPresentSound: true, // 포그라운드에서도 소리 재생
    defaultPresentBadge: true, // 포그라운드에서도 배지 표시
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

  // 권한 상태 확인 및 로그 (Android만)
  if (Platform.isAndroid) {
    final notificationStatus = await Permission.notification.status;
    debugPrint('알림 권한 상태: $notificationStatus');
  }

  // 배터리 최적화 확인 (Android만)
  if (Platform.isAndroid) {
    await checkBatteryOptimization();
  }
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
        importance: Importance.max, // max로 변경
        priority: Priority.max, // max로 변경
        enableVibration: useVibration,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true, // 화면이 꺼져 있어도 표시
        autoCancel: false, // 자동으로 사라지지 않음
        ongoing: true, // 지속 알림으로 설정
        visibility: NotificationVisibility.public,
        showWhen: true,
        when: scheduledTime.millisecondsSinceEpoch,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical, // iOS에서 중요한 알림으로 설정
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
  debugPrint('타이머 알림 취소됨');
}

// 알림 권한 확인
Future<bool> hasNotificationPermission() async {
  final status = await Permission.notification.status;
  return status.isGranted;
}

// 정확한 알람 권한 요청 (Android 12+)
Future<void> requestExactAlarmPermission() async {
  if (!Platform.isAndroid) return;

  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt >= 31) {
    // Android 12+
    final status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      await Permission.systemAlertWindow.request();
    }
  }
}

// 배터리 최적화 확인 및 설정 안내
Future<void> checkBatteryOptimization() async {
  if (!Platform.isAndroid) return;

  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 23) {
      // Android 6.0+
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        debugPrint('배터리 최적화 권한이 필요합니다. 설정에서 확인해주세요.');
      }
    }
  } catch (e) {
    debugPrint('배터리 최적화 확인 중 오류: $e');
  }
}
