import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/study_timer_model.dart';
import '../../utils/review_service.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('공부 기록이 초기화되었습니다.')));
      }
    }
  }

  void _showCleanupDialog(BuildContext context) async {
    // 삭제된 타이머의 기록 개수 계산
    final recordBox = Hive.box<StudyRecordModel>('records');
    final timerBox = Hive.box<StudyTimerModel>('timers');

    final existingTimerIds = timerBox.values.map((t) => t.id).toSet();
    final orphanedRecords =
        recordBox.values
            .where((record) => !existingTimerIds.contains(record.timerId))
            .toList();

    if (orphanedRecords.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정리할 기록이 없습니다.')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('삭제된 타이머 기록 정리'),
            content: Text(
              '삭제된 타이머의 학습 기록 ${orphanedRecords.length}개를 정리하시겠습니까?\n\n'
              '이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('정리하기'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // 삭제된 타이머의 기록들 삭제
      final keysToDelete = <dynamic>[];
      for (int i = 0; i < recordBox.length; i++) {
        final record = recordBox.getAt(i);
        if (record != null && !existingTimerIds.contains(record.timerId)) {
          keysToDelete.add(recordBox.keyAt(i));
        }
      }

      for (final key in keysToDelete) {
        await recordBox.delete(key);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${orphanedRecords.length}개의 기록을 정리했습니다.')),
        );
      }
    }
  }

  void _shareStudyRecord() async {
    final recordBox = Hive.box<StudyRecordModel>('records');
    final records = recordBox.values.toList();

    if (records.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유할 기록이 없습니다.')));
      return;
    }

    // 총 학습 시간 계산
    int totalMinutes = records.fold(0, (sum, r) => sum + r.minutes);
    int totalSeconds = records.fold(0, (sum, r) => sum + r.seconds);
    totalMinutes += totalSeconds ~/ 60;

    final totalHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;

    // 연속 학습일 계산
    final streakDays = _calculateCurrentStreak(records);

    // 오늘 학습 시간 계산
    final now = DateTime.now();
    final todayRecords = records.where(
      (r) =>
          r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day,
    );
    int todayMinutes = todayRecords.fold(0, (sum, r) => sum + r.minutes);
    todayMinutes += todayRecords.fold(0, (sum, r) => sum + r.seconds) ~/ 60;

    await ReviewService.shareStudyRecord(
      totalHours: totalHours,
      totalMinutes: remainingMinutes,
      streakDays: streakDays,
      todayMinutes: todayMinutes,
    );
  }

  int _calculateCurrentStreak(List<StudyRecordModel> records) {
    if (records.isEmpty) return 0;

    final now = DateTime.now();
    final sortedDates =
        records
            .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    for (final date in sortedDates) {
      if (date.isAtSameMomentAs(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('삭제된 타이머 기록 정리'),
                    subtitle: const Text('삭제된 타이머의 학습 기록을 정리합니다'),
                    onTap: () => _showCleanupDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('학습 기록 공유'),
                    subtitle: const Text('나의 공부 기록을 친구들과 공유해보세요'),
                    onTap: _shareStudyRecord,
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
                subtitle: const Text('v1.1.2'),
                enabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
