import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../main.dart'; // themeNotifier를 import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alarm = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarm = prefs.getBool('alarm') ?? true;
    });
  }

  Future<void> _setAlarm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm', value);
    setState(() => _alarm = value);
  }

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
                // 알림 설정
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('타이머 완료 알림'),
                  subtitle: const Text('타이머가 끝났을 때 알림 표시'),
                  trailing: Switch(value: _alarm, onChanged: _setAlarm),
                ),

                const Divider(),
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
