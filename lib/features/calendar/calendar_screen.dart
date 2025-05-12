import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_record_model.dart';
import '../../data/study_timer_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final Box<StudyRecordModel> _recordBox;
  late final Box<StudyTimerModel> _timerBox;

  @override
  void initState() {
    super.initState();
    _recordBox = Hive.box<StudyRecordModel>('records');
    _timerBox = Hive.box<StudyTimerModel>('timers');
  }

  List<StudyRecordModel> _getRecordsForDay(DateTime day) {
    return _recordBox.values
        .where(
          (record) =>
              record.date.year == day.year &&
              record.date.month == day.month &&
              record.date.day == day.day,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay ?? _focusedDay;
    final records = _getRecordsForDay(selected);

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate:
                (day) =>
                    _selectedDay != null &&
                    day.year == _selectedDay!.year &&
                    day.month == _selectedDay!.month &&
                    day.day == _selectedDay!.day,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.indigo,
                  width: 2,
                ), // 오늘 날짜 테두리 강조
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green, // 마커 색상
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter, // 마커를 날짜 아래로 내림
              markersMaxCount: 3,
            ),
            eventLoader: (day) => _getRecordsForDay(day),
            calendarBuilders: CalendarBuilders(
              todayBuilder: (context, date, _) {
                final isSelected =
                    _selectedDay != null &&
                    date.year == _selectedDay!.year &&
                    date.month == _selectedDay!.month &&
                    date.day == _selectedDay!.day;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightBlue, width: 2),
                    color: isSelected ? Colors.red : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.lightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              selectedBuilder: (context, date, _) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 2),
                    color: Colors.red.withOpacity(0.15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '공부 기록이 없습니다.',
                style: TextStyle(fontSize: 22, color: Colors.blueGrey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, idx) {
                  final record = records[idx];
                  final timer = _timerBox.values.firstWhere(
                    (t) => t.id == record.timerId,
                    orElse:
                        () => StudyTimerModel(
                          id: '',
                          title: '알 수 없음',
                          durationMinutes: 0,
                          createdAt: DateTime.now(),
                        ),
                  );
                  final color =
                      timer.colorHex != null
                          ? Color(timer.colorHex!)
                          : Colors.red;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          // 왼쪽 컬러 바
                          Container(
                            width: 8,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              timer.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${record.minutes}분 ${record.seconds}초',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
