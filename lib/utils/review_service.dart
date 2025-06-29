import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../config/app_config.dart';

class ReviewService {
  static const String _completedTimersKey = 'completed_timers_count';
  static const String _lastReviewRequestKey = 'last_review_request';

  // 리뷰 요청 조건
  static const int _minCompletedTimers = AppConfig.minCompletedTimersForReview;
  static const int _daysBetweenRequests = AppConfig.daysBetweenReviewRequests;

  static Future<bool> shouldShowReviewRequest() async {
    final prefs = await SharedPreferences.getInstance();

    final completedCount = prefs.getInt(_completedTimersKey) ?? 0;
    final lastRequestTime = prefs.getInt(_lastReviewRequestKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 최소 조건 체크
    if (completedCount < _minCompletedTimers) {
      return false;
    }

    // 마지막 요청으로부터 충분한 시간이 지났는지 체크
    if (lastRequestTime > 0) {
      final daysSinceLastRequest =
          (now - lastRequestTime) / (1000 * 60 * 60 * 24);
      if (daysSinceLastRequest < _daysBetweenRequests) {
        return false;
      }
    }

    return true;
  }

  static Future<void> incrementCompletedTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_completedTimersKey) ?? 0;
    await prefs.setInt(_completedTimersKey, currentCount + 1);
  }

  static Future<void> markReviewRequested() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastReviewRequestKey, now);
  }

  static Future<void> showReviewDialog(BuildContext context) async {
    final shouldShow = await shouldShowReviewRequest();
    if (!shouldShow) return;

    await markReviewRequested();

    try {
      final InAppReview inAppReview = InAppReview.instance;

      // 시스템 리뷰 팝업이 사용 가능한지 확인
      if (await inAppReview.isAvailable()) {
        // 시스템 리뷰 팝업 표시
        await inAppReview.requestReview();
      } else {
        // 사용 불가능한 경우 앱스토어로 이동
        await _openAppStore();
      }
    } catch (e) {
      print('리뷰 요청 실패: $e');
      // 실패 시 앱스토어로 이동
      await _openAppStore();
    }
  }

  static Future<void> _openAppStore() async {
    try {
      String storeUrl;
      if (Platform.isIOS) {
        storeUrl = AppConfig.iosStoreUrl;
      } else {
        storeUrl = AppConfig.androidStoreUrl;
      }

      final Uri uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('앱스토어 열기 실패: $e');
    }
  }

  // 공유 기능
  static Future<void> shareStudyRecord({
    required int totalHours,
    required int totalMinutes,
    required int streakDays,
    required int todayMinutes,
  }) async {
    final String todayTimeText =
        todayMinutes >= 60
            ? '${todayMinutes ~/ 60}시간 ${todayMinutes % 60}분'
            : '$todayMinutes분';

    // 앱 정보 가져오기
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;

    // 플랫폼별 스토어 링크
    String storeLink;
    if (Platform.isIOS) {
      storeLink = AppConfig.iosStoreUrl;
    } else {
      storeLink = AppConfig.androidStoreUrl;
    }

    final String shareText = '''🎯 나의 공부 기록을 공유합니다!

📚 총 학습 시간: $totalHours시간 $totalMinutes분
🔥 연속 학습일: $streakDays일
📖 오늘 학습 시간: $todayTimeText

꾸준히 공부하고 있어요! 💪

📱 $appName으로 함께 공부해요!
$storeLink

#공부기록 #타이머앱 #학습관리 #포모도로''';

    try {
      await Share.share(shareText, subject: '나의 공부 기록');
    } catch (e) {
      print('공유 실패: $e');
    }
  }

  // 테스트용 리뷰 요청
  static Future<void> showTestReviewDialog(BuildContext context) async {
    try {
      final InAppReview inAppReview = InAppReview.instance;

      // 시스템 리뷰 팝업이 사용 가능한지 확인
      if (await inAppReview.isAvailable()) {
        // 시스템 리뷰 팝업 표시
        await inAppReview.requestReview();
      } else {
        // 사용 불가능한 경우 앱스토어로 이동
        await _openAppStore();
      }
    } catch (e) {
      print('리뷰 요청 실패: $e');
      // 실패 시 앱스토어로 이동
      await _openAppStore();
    }
  }
}
