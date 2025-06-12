import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import '../../data/study_timer_model.dart';
import 'timer_circle_painter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../utils/notification_helper.dart';
import '../../utils/background_notification_helper.dart';
import '../../utils/sound_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerRunScreen extends StatefulWidget {
  final StudyTimerModel timer;
  const TimerRunScreen({super.key, required this.timer});

  @override
  State<TimerRunScreen> createState() => _TimerRunScreenState();
}

class _TimerRunScreenState extends State<TimerRunScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final int _totalSeconds;
  late final String _title;
  late final int _durationMinutes;
  late final StudyTimerModel _timer;

  Ticker? _ticker;
  double _elapsedSeconds = 0;
  bool _recordSaved = false; // 1분 이상 기록 저장 여부
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _pausedTime; // 정지한 시간 저장

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = widget.timer;
    _title = _timer.title;
    _durationMinutes = _timer.durationMinutes;
    _totalSeconds = _durationMinutes * 60;
    _elapsedSeconds = 0;

    _ticker = createTicker((_) {
      if (!_isRunning) return;
      final now = DateTime.now();
      setState(() {
        _elapsedSeconds = now.difference(_startTime!).inMilliseconds / 1000.0;

        if (_elapsedSeconds >= 60 && !_recordSaved) {
          _saveRecord();
          _recordSaved = true;
        }

        if (_elapsedSeconds >= _totalSeconds) {
          _elapsedSeconds = _totalSeconds.toDouble();
          _isRunning = false;
          _ticker?.stop();
          if (!_recordSaved) {
            _saveRecord();
            _recordSaved = true;
          }
          // 타이머 완료 햅틱 피드백
          SoundHelper.playCompleteFeedback();
          // 예약된 알림 외에도 직접 알림 표시 (백그라운드에서도 작동하도록)
          _showCompletionNotification();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('타이머 종료!')));
        }
      });
    });
  }

  void _start() {
    if (_isRunning) return;

    // 타이머 시작 햅틱 피드백
    SoundHelper.playStartFeedback();

    setState(() {
      _isRunning = true;
      _pausedTime = null; // 재개할 때 정지 시간 초기화
      _startTime = DateTime.now().subtract(
        Duration(milliseconds: (_elapsedSeconds * 1000).toInt()),
      );
    });
    _ticker?.start();

    final secondsLeft =
        (_totalSeconds - _elapsedSeconds).clamp(0, _totalSeconds).toInt();

    // 기존 알림 예약
    scheduleTimerNotification(secondsLeft);

    // 백그라운드 알림도 함께 예약 (추가 보장)
    scheduleBackgroundTimerNotification(_title, secondsLeft);
  }

  void _pause() {
    // 일시정지 햅틱 피드백
    SoundHelper.playPauseFeedback();

    setState(() {
      _isRunning = false;
      _pausedTime = DateTime.now(); // 정지한 현재 시간 저장
    });
    _ticker?.stop();
    cancelTimerNotification();
    cancelBackgroundTimerNotification(); // 백그라운드 알림도 취소
    if (_elapsedSeconds >= 60 && !_recordSaved) {
      _saveRecord();
      _recordSaved = true;
    }
  }

  void _reset() {
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _startTime = null;
      _pausedTime = null; // 정지 시간도 초기화
      _recordSaved = false;
    });
    _ticker?.stop();
    cancelTimerNotification();
    cancelBackgroundTimerNotification(); // 백그라운드 알림도 취소
  }

  void _saveRecord() async {
    final recordBox = Hive.box<StudyRecordModel>('records');
    await recordBox.add(
      StudyRecordModel(
        timerId: widget.timer.id,
        date: DateTime.now(),
        minutes: _elapsedSeconds ~/ 60,
        seconds: (_elapsedSeconds % 60).toInt(),
      ),
    );
  }

  // 타이머 완료 시 알림 즉시 표시 (백그라운드에서도 작동하도록)
  Future<void> _showCompletionNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final useAlarm = prefs.getBool('alarm') ?? true;
    final useVibration = prefs.getBool('vibration') ?? false;

    if (!useAlarm) return;

    // 알림 즉시 표시 - 더 강화된 설정으로
    await flutterLocalNotificationsPlugin.show(
      0,
      '$_title 타이머 종료',
      '설정한 시간이 모두 지났어요!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_channel',
          '타이머 알림',
          channelDescription: '타이머 종료 시 알림을 표시합니다.',
          importance: Importance.max, // max로 변경
          priority: Priority.max, // max로 변경
          enableVibration: useVibration,
          playSound: true,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true, // 화면이 꺼져 있어도 표시
          autoCancel: false, // 자동으로 사라지지 않음
          ongoing: false, // 완료 알림은 ongoing하지 않음
          visibility: NotificationVisibility.public,
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          ticker: '$_title 타이머가 종료되었습니다!',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical, // iOS에서 중요한 알림으로 설정
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      if (_startTime != null) {
        final now = DateTime.now();
        setState(() {
          _elapsedSeconds = now.difference(_startTime!).inMilliseconds / 1000.0;
        });
      }
    }
  }

  // 동기부여 메시지 생성
  Widget _buildMotivationalMessage(
    double progress,
    double elapsedSeconds,
    bool isDark,
  ) {
    String message = '';
    IconData icon = Icons.emoji_events;
    Color color = Colors.blue;

    if (progress == 0) {
      message = '집중할 시간입니다! 💪';
      icon = Icons.play_circle_outline;
      color = Colors.green;
    } else if (progress < 0.25) {
      message = '좋은 시작이에요! 🌟';
      icon = Icons.trending_up;
      color = Colors.blue;
    } else if (progress < 0.5) {
      message = '순조롭게 진행 중이에요! 📈';
      icon = Icons.show_chart;
      color = Colors.teal;
    } else if (progress < 0.75) {
      message = '절반을 넘었어요! 🎯';
      icon = Icons.timeline;
      color = Colors.orange;
    } else if (progress < 0.9) {
      message = '거의 다 왔어요! 🚀';
      icon = Icons.rocket_launch;
      color = Colors.purple;
    } else if (progress < 1.0) {
      message = '마지막 스퍼트! 🔥';
      icon = Icons.local_fire_department;
      color = Colors.red;
    } else {
      message = '완주하셨습니다! 🏆';
      icon = Icons.emoji_events;
      color = Colors.amber;
    }

    // 경과 시간에 따른 추가 격려
    final minutes = elapsedSeconds ~/ 60;
    if (minutes >= 25) {
      message += '\n포모도로 달성!';
    } else if (minutes >= 60) {
      message += '\n1시간 돌파!';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondsLeft =
        (_totalSeconds - _elapsedSeconds).clamp(0, _totalSeconds).toInt();
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    final progress = (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerTextColor =
        isDark ? Colors.white : Colors.black87; // 라이트모드에서 살짝 검은색
    final timerBgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    // 타이머의 라벨 색상 추출
    final timerColor =
        _timer.colorHex != null
            ? Color(_timer.colorHex!)
            : Colors.blue.shade600;

    return Scaffold(
      appBar: AppBar(title: Text(_title), elevation: 0, centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(300, 300),
                  painter: TimerCirclePainter(
                    progress: progress,
                    bgColor: timerBgColor, // 배경색 전달
                    progressColor: timerColor, // 타이머 색상 전달
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 48,
                    color: timerTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // 정지한 시간 표시 (공간은 항상 유지, 텍스트만 조건부)
            Container(
              height: 60,
              alignment: Alignment.center,
              child:
                  _pausedTime != null
                      ? Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
                        child: Text(
                          '정지한 시각: '
                          '${_pausedTime!.hour.toString().padLeft(2, '0')}:'
                          '${_pausedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 20,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(), // 공간은 유지하되 텍스트만 숨김
            ),
            const SizedBox(height: 24), // 고정 간격
            // 동기부여 메시지 추가
            _buildMotivationalMessage(progress, _elapsedSeconds, isDark),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                  onPressed: _isRunning ? _pause : _start,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: 48,
                  onPressed: _reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
