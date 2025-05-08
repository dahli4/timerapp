import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/study_record_model.dart';
import '../../main.dart'; // themeNotifier를 import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showResetDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('공부 기록 초기화'),
            content: const Text('정말로 모든 공부 기록을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('초기화'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final recordBox = Hive.box<StudyRecordModel>('records');
      await recordBox.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공부 기록이 초기화되었습니다.')));
    }
  }

  Future<void> _checkNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        // 권한 거부 시 안내 다이얼로그
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('알림 권한 필요'),
                content: const Text(
                  '타이머 종료 알림을 받으려면 알림 권한이 필요합니다.\n'
                  '설정에서 권한을 허용해 주세요.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.pop(context);
                    },
                    child: const Text('앱 설정 열기'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('알림 설정'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await _checkNotificationPermission(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('다크모드'),
                  trailing: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder:
                        (context, mode, _) => Switch(
                          value: mode == ThemeMode.dark,
                          onChanged: (val) {
                            themeNotifier.value =
                                val ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('공부 기록 전체 초기화'),
                  onTap: () => _showResetDialog(context),
                ),
                const Divider(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 버전'),
              subtitle: const Text('v1.0.0'),
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _alarm = true;
  bool _vibration = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarm = prefs.getBool('alarm') ?? true;
      _vibration = prefs.getBool('vibration') ?? false;
    });
  }

  Future<void> _setAlarm(bool value) async {
    // 알림 토글 시 권한 확인
    await (context
            .findAncestorWidgetOfExactType<SettingsScreen>()
            ?._checkNotificationPermission(context) ??
        Future.value());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm', value);
    setState(() => _alarm = value);
  }

  Future<void> _setVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', value);
    setState(() => _vibration = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('타이머 종료 시 알림'),
            value: _alarm,
            onChanged: (val) async {
              await _setAlarm(val);
            },
          ),
          SwitchListTile(
            title: const Text('타이머 종료 시 진동'),
            value: _vibration,
            onChanged: _setVibration,
          ),
        ],
      ),
    );
  }
}
