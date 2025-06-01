import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationGuideDialog extends StatelessWidget {
  const NotificationGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('백그라운드 알림 설정 안내'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '앱이 백그라운드에서도 정확한 알림을 받으려면 다음 설정을 확인해주세요:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('📱 안드로이드 설정 방법:'),
            SizedBox(height: 8),
            Text('1. 설정 > 앱 > 타이머앱'),
            Text('2. 배터리 > 배터리 최적화 안함'),
            Text('3. 알림 > 알림 허용'),
            Text('4. 설정 > 배터리 > 배터리 최적화'),
            Text('5. 타이머앱을 "최적화 안함"으로 설정'),
            SizedBox(height: 16),
            Text('🔔 알림이 오지 않는다면:'),
            SizedBox(height: 8),
            Text('• 설정에서 "테스트 알림" 버튼을 눌러보세요'),
            Text('• "백그라운드 알림 테스트"로 백그라운드 알림을 확인해보세요'),
            Text('• 휴대폰 제조사별 배터리 절약 모드를 확인해주세요'),
            Text('• Do Not Disturb 모드가 꺼져있는지 확인해주세요'),
            SizedBox(height: 16),
            Text('📋 제조사별 추가 설정:'),
            SizedBox(height: 8),
            Text('• 삼성: 설정 > 디바이스 케어 > 배터리 > 백그라운드 앱 제한'),
            Text('• LG: 설정 > 배터리 > 배터리 절약 > 백그라운드 앱 관리'),
            Text('• 화웨이: 설정 > 배터리 > 앱 실행 관리'),
            Text('• 샤오미: 설정 > 배터리 및 성능 > 배터리'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
        TextButton(
          onPressed: () async {
            const url = 'https://dontkillmyapp.com/';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            }
          },
          child: const Text('더 자세한 정보'),
        ),
      ],
    );
  }
}

// 백그라운드 알림 안내를 표시하는 함수
Future<void> showNotificationGuide(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return const NotificationGuideDialog();
    },
  );
}
