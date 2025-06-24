import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import '../../data/study_timer_model.dart';
import 'timer_circle_painter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../utils/notification_helper.dart';
import '../../utils/background_notification_helper.dart';
import '../../utils/sound_helper.dart';
import 'package:intl/intl.dart';

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
  late StudyTimerModel _timer; // final 제거하여 변경 가능하게 함

  Ticker? _ticker;
  double _elapsedSeconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _pausedTime; // 정지한 시간 저장
  bool _hasRecordSaved = false; // 기록 저장 여부 추적

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
      final calculatedElapsed =
          now.difference(_startTime!).inMilliseconds / 1000.0;

      setState(() {
        // 타이머 완료 시간을 초과하지 않도록 제한
        _elapsedSeconds = calculatedElapsed.clamp(
          0.0,
          _totalSeconds.toDouble(),
        );

        if (_elapsedSeconds >= _totalSeconds) {
          _elapsedSeconds = _totalSeconds.toDouble();
          _isRunning = false;
          _ticker?.stop();
          // 타이머 완료 시 항상 최종 기록 저장
          _saveRecord();
          // 타이머 완료 햅틱 피드백 + 사운드
          SoundHelper.playCompleteFeedback();
          // 완료 다이얼로그 표시
          _showCompletionDialog();
        }
      });
    });
  }

  void _start() {
    if (_isRunning) return;

    // 타이머 시작 햅틱 피드백
    SoundHelper.playStartFeedback();

    // 조용한 로그만 (권한 체크 없이)
    if (_elapsedSeconds == 0) {
      debugPrint('타이머 시작 - 완료 시 알림 예정');
    }

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
    scheduleBackgroundTimerNotification(
      _title,
      _timer.id,
      _durationMinutes,
      secondsLeft,
    );
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

    // 1분 이상 사용한 경우에만 기록 저장
    if (_elapsedSeconds >= 60) {
      _saveRecord();
    }
  }

  void _reset() {
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _startTime = null;
      _pausedTime = null; // 정지 시간도 초기화
      _hasRecordSaved = false; // 플래그 리셋
    });
    _ticker?.stop();
    cancelTimerNotification();
    cancelBackgroundTimerNotification(); // 백그라운드 알림도 취소
  }

  void _saveRecord() async {
    // 이미 저장되었거나 1분 미만이면 저장하지 않음
    if (_hasRecordSaved) return;

    final recordBox = Hive.box<StudyRecordModel>('records');

    // 실제 경과 시간을 정확히 계산
    int minutesToSave = _elapsedSeconds ~/ 60;
    int secondsToSave = (_elapsedSeconds % 60).toInt();

    // 1분 미만이면 저장하지 않음
    if (minutesToSave == 0 && secondsToSave < 60) {
      return;
    }

    await recordBox.add(
      StudyRecordModel(
        timerId: widget.timer.id,
        date: DateTime.now(),
        minutes: minutesToSave,
        seconds: secondsToSave,
      ),
    );

    _hasRecordSaved = true; // 저장 완료 플래그 설정
    debugPrint('기록 저장: $minutesToSave분 $secondsToSave초');
  }

  Future<void> _toggleFavorite() async {
    final timerBox = Hive.box<StudyTimerModel>('timers');
    final timers = timerBox.values.toList();
    final index = timers.indexWhere((t) => t.id == _timer.id);

    if (index >= 0) {
      final updatedTimer = StudyTimerModel(
        id: _timer.id,
        title: _timer.title,
        durationMinutes: _timer.durationMinutes,
        createdAt: _timer.createdAt,
        colorHex: _timer.colorHex,
        groupId: _timer.groupId,
        isInfinite: _timer.isInfinite,
        isFavorite: !_timer.isFavorite,
      );
      await timerBox.putAt(index, updatedTimer);
      setState(() {
        // _timer를 업데이트하여 UI 반영
        _timer = updatedTimer;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 화면을 나갈 때 실행 중이면 정지하고 기록 저장 (1분 이상 사용 시)
    if (_isRunning && _elapsedSeconds >= 60) {
      _ticker?.stop();
      _saveRecord();
    }

    _ticker?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      if (_startTime != null) {
        final now = DateTime.now();
        final calculatedElapsed =
            now.difference(_startTime!).inMilliseconds / 1000.0;

        setState(() {
          // 타이머 완료 시간을 초과하지 않도록 제한
          _elapsedSeconds = calculatedElapsed.clamp(
            0.0,
            _totalSeconds.toDouble(),
          );

          // 타이머가 완료되었으면 완료 처리
          if (_elapsedSeconds >= _totalSeconds) {
            _elapsedSeconds = _totalSeconds.toDouble();
            _isRunning = false;
            _ticker?.stop();
            // 타이머 완료 시 항상 최종 기록 저장
            _saveRecord();
            // 타이머 완료 햅틱 피드백 + 사운드
            SoundHelper.playCompleteFeedback();
            // 완료 다이얼로그 표시
            _showCompletionDialog();
          }
        });
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // 앱이 백그라운드로 가거나 비활성화될 때 기록 저장 (1분 이상 사용 시)
      if (_isRunning && _elapsedSeconds >= 60) {
        _saveRecord();
      }
    }
  }

  // 타이머 완료 다이얼로그 표시
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: Color(_timer.colorHex ?? 0xFF4A90E2),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('타이머 완료!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_durationMinutes분 집중 완료!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎉 수고하셨습니다! 🎉',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 타이머 화면 닫기
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        // 뒤로가기할 때 실행 중이면 기록 저장 (1분 이상 사용 시)
        if (_isRunning && _elapsedSeconds >= 60) {
          _saveRecord();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _timer.isFavorite ? Icons.star : Icons.star_border,
                color: _timer.isFavorite ? Colors.amber : null,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: Column(
          children: [
            // 통계 기록 안내 (배경 제거, 텍스트만)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '💡 1분 이상 사용시 통계에 기록됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // 나머지 컨텐츠
            Expanded(
              child: Center(
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
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  bottom: 12.0,
                                ),
                                child: Text(
                                  '정지한 시각: ${DateFormat('a h시 mm분', 'ko_KR').format(_pausedTime!)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(), // 공간은 유지하되 텍스트만 숨김
                    ),
                    const SizedBox(height: 24), // 고정 간격
                    // 동기부여 메시지 추가
                    _buildMotivationalMessage(
                      progress,
                      _elapsedSeconds,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                          ),
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
            ),
          ],
        ),
      ), // PopScope 닫는 괄호 추가
    );
  }
}
