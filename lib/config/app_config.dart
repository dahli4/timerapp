/// 앱 설정 상수들
/// 배포 시 실제 값으로 변경 필요
class AppConfig {
  // 앱스토어 ID (배포 후 실제 ID로 변경)
  static const String iosAppId = '6747347774'; // TODO: 실제 앱스토어 ID로 변경
  static const String androidPackageId = 'com.dong.timerapp';

  // 앱스토어 URL 생성
  static String get iosStoreUrl => 'https://apps.apple.com/app/$iosAppId';
  static String get androidStoreUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  // 리뷰 설정
  static const int minCompletedTimersForReview = 5;
  static const int daysBetweenReviewRequests = 30;
}
