import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  tz.initializeTimeZones();
}

Future<void> scheduleTimerNotification(int seconds) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    '타이머 종료',
    '설정한 시간이 모두 지났어요!',
    tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
    const NotificationDetails(
      android: AndroidNotificationDetails('timer_channel', '타이머 알림'),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> cancelTimerNotification() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}
