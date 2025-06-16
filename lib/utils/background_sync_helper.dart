import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/study_record_model.dart';

class BackgroundSyncHelper {
  /// 백그라운드에서 저장된 타이머 기록들을 Hive로 동기화
  static Future<void> syncBackgroundRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backgroundRecords =
          prefs.getStringList('background_timer_records') ?? [];

      if (backgroundRecords.isEmpty) return;

      final recordBox = Hive.box<StudyRecordModel>('records');

      // 각 백그라운드 기록을 Hive에 저장
      for (final recordString in backgroundRecords) {
        final parts = recordString.split('|');
        if (parts.length == 4) {
          final timestamp = int.tryParse(parts[0]);
          final timerId = parts[1];
          final minutes = int.tryParse(parts[2]) ?? 0;
          final seconds = int.tryParse(parts[3]) ?? 0;

          if (timestamp != null) {
            await recordBox.add(
              StudyRecordModel(
                timerId: timerId,
                date: DateTime.fromMillisecondsSinceEpoch(timestamp),
                minutes: minutes,
                seconds: seconds,
              ),
            );
          }
        }
      }

      // 동기화 완료 후 백그라운드 기록 삭제
      await prefs.remove('background_timer_records');
    } catch (e) {
      // 오류 발생 시 조용히 처리
    }
  }
}
