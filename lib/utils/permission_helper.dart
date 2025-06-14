import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'dart:io';

class PermissionHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 알림 권한 요청
  static Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      // iOS 알림 권한 요청
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      // Android 13+ 알림 권한 요청
      if (await ph.Permission.notification.isDenied) {
        final status = await ph.Permission.notification.request();
        return status == ph.PermissionStatus.granted;
      }
      return true;
    }
    return true;
  }

  /// 알림 권한 상태 확인
  static Future<bool> hasNotificationPermission() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      return await ph.Permission.notification.isGranted;
    }
    return true;
  }

  /// 설정 앱으로 이동
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}
