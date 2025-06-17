import 'package:flutter/services.dart';

class SoundHelper {
  // 간단한 시스템 사운드만 사용 - 타이머 완료 시에만 피드백

  // 타이머 시작 시 간단한 햅틱 피드백
  static Future<void> playStartFeedback() async {
    await HapticFeedback.lightImpact();
  }

  // 타이머 완료 시 진동 + 사운드 피드백
  static Future<void> playCompleteFeedback() async {
    // 시스템 사운드 재생
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();

    // 0.3초 후 한 번 더 (완료를 확실히 인지할 수 있도록)
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.mediumImpact();

    // 한 번 더 시스템 사운드
    await Future.delayed(const Duration(milliseconds: 200));
    await SystemSound.play(SystemSoundType.click);
  }

  // 타이머 일시정지 시 간단한 햅틱 피드백
  static Future<void> playPauseFeedback() async {
    await HapticFeedback.mediumImpact();
  }

  // 리소스 정리 (더 이상 필요 없음)
  static Future<void> dispose() async {
    // 시스템 햅틱만 사용하므로 정리할 것이 없음
  }
}
