import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../main.dart'; // themeNotifier를 import
import '../../utils/sound_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                  leading: const Icon(Icons.notifications),
                  title: const Text('알림 설정'),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const NotificationSettingsScreen(),
                        ),
                      ),
                ),

                // 사운드 설정 추가
                FutureBuilder<bool>(
                  future: SoundHelper.isSoundEnabled(),
                  builder: (context, snapshot) {
                    return ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text('사운드 효과'),
                      subtitle: const Text('타이머 시작/일시정지/완료 시 소리'),
                      trailing: Switch(
                        value: snapshot.data ?? true,
                        onChanged: (val) async {
                          await SoundHelper.setSoundEnabled(val);
                          if (val) {
                            // 사운드 활성화 시 테스트 사운드 재생
                            SoundHelper.playClickSound();
                          }
                          // UI 새로고침을 위해 setState 호출
                          setState(() {});
                        },
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
