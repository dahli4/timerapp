import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import '../../data/study_timer_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../utils/sound_helper.dart';
import 'package:intl/intl.dart';

class InfiniteTimerRunScreen extends StatefulWidget {
  final StudyTimerModel timer;
  const InfiniteTimerRunScreen({super.key, required this.timer});

  @override
  State<InfiniteTimerRunScreen> createState() => _InfiniteTimerRunScreenState();
}

class _InfiniteTimerRunScreenState extends State<InfiniteTimerRunScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final String _title;
  late StudyTimerModel _timer; // final 제거하여 변경 가능하게 함

  Ticker? _ticker;
  double _elapsedSeconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _pausedTime;
  bool _hasRecordSaved = false; // 기록 저장 여부 추적

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = widget.timer;
    _title = _timer.title;

    _ticker = createTicker((_) {
      if (!_isRunning) return;
      final now = DateTime.now();
      final calculatedElapsed =
          now.difference(_startTime!).inMilliseconds / 1000.0;

      setState(() {
        _elapsedSeconds = calculatedElapsed;
      });
    });
  }

  void _start() {
    if (_isRunning) return;

    SoundHelper.playStartFeedback();

    setState(() {
      _isRunning = true;
      _pausedTime = null;
      _startTime = DateTime.now().subtract(
        Duration(milliseconds: (_elapsedSeconds * 1000).toInt()),
      );
    });
    _ticker?.start();
  }

  void _pause() {
    SoundHelper.playPauseFeedback();

    setState(() {
      _isRunning = false;
      _pausedTime = DateTime.now();
    });
    _ticker?.stop();

    // 1분 이상 사용한 경우에만 기록 저장
    if (_elapsedSeconds >= 60) {
      _saveRecord();
    }
  }

  void _reset() {
    // 실행 중이면 먼저 정지
    if (_isRunning) {
      _ticker?.stop();
    }

    // 1분 이상 사용한 경우에만 기록 저장
    if (_elapsedSeconds >= 60) {
      _saveRecord();
    }

    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _startTime = null;
      _pausedTime = null;
      _hasRecordSaved = false; // 플래그 리셋
    });
  }

  void _saveRecord() async {
    // 이미 저장되었거나 1분 미만이면 저장하지 않음
    if (_hasRecordSaved) return;

    final recordBox = Hive.box<StudyRecordModel>('records');

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

    // 화면을 나갈 때 실행 중이면 정지하고 기록 저장
    if (_isRunning) {
      _ticker?.stop();
      if (_elapsedSeconds >= 60) {
        _saveRecord();
      }
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
          _elapsedSeconds = calculatedElapsed;
        });
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // 앱이 백그라운드로 가거나 비활성화될 때 기록 저장
      if (_isRunning && _elapsedSeconds >= 60) {
        _saveRecord();
      }
    }
  }

  Widget _buildMotivationalMessage(double elapsedSeconds, bool isDark) {
    String message = '';
    IconData icon = Icons.all_inclusive;
    Color color = Colors.blue;

    if (elapsedSeconds == 0) {
      message = '집중력의 한계를 뛰어넘어보세요! 🚀';
      icon = Icons.play_circle_outline;
      color = Colors.green;
    } else if (elapsedSeconds < 300) {
      // 5분 미만
      message = '집중하고 계시네요! 계속하세요! 📚';
      icon = Icons.trending_up;
      color = Colors.blue;
    } else if (elapsedSeconds < 900) {
      // 15분 미만
      message = '좋은 집중력이에요! 💪';
      icon = Icons.show_chart;
      color = Colors.teal;
    } else if (elapsedSeconds < 1800) {
      // 30분 미만
      message = '훌륭한 집중 상태입니다! 🎯';
      icon = Icons.timeline;
      color = Colors.orange;
    } else if (elapsedSeconds < 3600) {
      // 1시간 미만
      message = '대단한 집중력입니다! 🔥';
      icon = Icons.local_fire_department;
      color = Colors.red;
    } else {
      message = '놀라운 집중력! 🏆';
      icon = Icons.emoji_events;
      color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 32),
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
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = ((_elapsedSeconds % 60).toInt()).toString().padLeft(2, '0');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final timerColor =
        _timer.colorHex != null
            ? Color(_timer.colorHex!)
            : Colors.blue.shade600;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        // 뒤로가기할 때 실행 중이면 기록 저장
        if (_isRunning && _elapsedSeconds >= 60) {
          _saveRecord();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.all_inclusive, color: timerColor),
              const SizedBox(width: 8),
              Text(_title),
            ],
          ),
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
            // 통계 기록 안내
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
                    // 무제한 타이머 표시
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: timerColor, width: 8),
                        boxShadow: [
                          BoxShadow(
                            color: timerColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.all_inclusive,
                              size: 40,
                              color: timerColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$hours:$minutes:$seconds',
                              style: TextStyle(
                                fontSize: 36,
                                color: timerColor, // 타이머 색상으로 변경
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 정지한 시간 표시
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
                              : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // 동기부여 메시지
                    _buildMotivationalMessage(_elapsedSeconds, isDark),

                    const SizedBox(height: 24),

                    // 컨트롤 버튼들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 시작/정지 버튼
                        Container(
                          decoration: BoxDecoration(
                            color: timerColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: timerColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                            ),
                            iconSize: 48,
                            color: Colors.white,
                            onPressed: _isRunning ? _pause : _start,
                          ),
                        ),

                        // 리셋 버튼 (항상 표시, 오른쪽에 위치)
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            iconSize: 36,
                            color: Colors.white,
                            onPressed: _reset,
                          ),
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
