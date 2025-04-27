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
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) => _getRecordsForDay(day),
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
              child: Text('공부 기록이 없습니다.'),
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
                  return ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(timer.title),
                    trailing: Text('${record.minutes}분'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
