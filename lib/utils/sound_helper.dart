import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // 사운드 설정 키
  static const String _soundEnabledKey = 'sound_enabled';

  // 사운드 효과 활성화 여부 확인
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true; // 기본값: 활성화
  }

  // 사운드 효과 활성화/비활성화 설정
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  // 타이머 시작 사운드
  static Future<void> playStartSound() async {
    if (await isSoundEnabled()) {
      try {
        // 시스템 기본 알림음 사용 (Android에서 지원)
        await _audioPlayer.play(AssetSource('sounds/timer_start.wav'));
      } catch (e) {
        // 파일이 없으면 시스템 사운드 사용
        print('커스텀 사운드 재생 실패, 무음 처리: $e');
      }
    }
  }

  // 타이머 완료 사운드
  static Future<void> playCompleteSound() async {
    if (await isSoundEnabled()) {
      try {
        await _audioPlayer.play(AssetSource('sounds/timer_complete.wav'));
      } catch (e) {
        print('커스텀 사운드 재생 실패, 무음 처리: $e');
      }
    }
  }

  // 타이머 일시정지 사운드
  static Future<void> playPauseSound() async {
    if (await isSoundEnabled()) {
      try {
        await _audioPlayer.play(AssetSource('sounds/timer_pause.wav'));
      } catch (e) {
        print('커스텀 사운드 재생 실패, 무음 처리: $e');
      }
    }
  }

  // 버튼 클릭 사운드
  static Future<void> playClickSound() async {
    if (await isSoundEnabled()) {
      try {
        await _audioPlayer.play(AssetSource('sounds/button_click.wav'));
      } catch (e) {
        print('커스텀 사운드 재생 실패, 무음 처리: $e');
      }
    }
  }

  // 성취 사운드 (기록 갱신 등)
  static Future<void> playAchievementSound() async {
    if (await isSoundEnabled()) {
      try {
        await _audioPlayer.play(AssetSource('sounds/achievement.wav'));
      } catch (e) {
        print('커스텀 사운드 재생 실패, 무음 처리: $e');
      }
    }
  }

  // 리소스 정리
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
