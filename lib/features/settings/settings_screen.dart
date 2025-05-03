import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // TODO: 공부 기록 전체 삭제 로직 추가
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
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('알림 설정'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
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
            onChanged: _setAlarm,
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
