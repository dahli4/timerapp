# 집중 타이머 앱 배포 가이드

## 🚀 배포 준비 완료 사항

### ✅ 완료된 작업
- [x] iOS 알림 권한 설정
- [x] 온보딩 화면 구현
- [x] 앱 정보 업데이트 (한국어 이름: "집중 타이머")
- [x] 빌드 테스트 완료
- [x] 권한 관리 시스템 구현

### 🎯 핵심 기능
- 타이머 생성 및 관리
- 색상별 타이머 분류
- 통계 및 달력 기능
- 알림 및 사운드 피드백
- 다크모드 지원
- 한국어 완전 지원

## 📱 다음 단계

### 1. Apple Developer 계정 준비
1. [Apple Developer](https://developer.apple.com) 가입 ($99/년)
2. Certificates, Identifiers & Profiles 설정
3. App ID 생성 (권장: `com.yourcompany.focustimer`)

### 2. Xcode 설정
```bash
cd /Users/Dahlia/Documents/timerapp
open ios/Runner.xcworkspace
```

**Xcode에서 설정할 항목:**
- Team 선택 (Apple Developer 계정)
- Bundle Identifier 설정
- Signing & Capabilities 확인
- App Store Connect 앱 등록

### 3. 배포용 빌드
```bash
# 릴리즈 빌드 생성
flutter build ios --release

# Archive 생성 (Xcode에서)
Product → Archive → Distribute App
```

### 4. 앱스토어 제출 전 준비사항

#### 📸 스크린샷 필요
다양한 iPhone 크기별로 스크린샷 촬영:
- iPhone 6.7" (iPhone 15 Pro Max)
- iPhone 6.1" (iPhone 15 Pro)
- iPhone 5.5" (iPhone 8 Plus)

#### 📝 앱 정보 작성
- **앱 이름**: 집중 타이머
- **부제목**: 생산성 향상을 위한 스마트 타이머
- **키워드**: 타이머,집중,생산성,포모도로,공부,업무
- **설명**: 
```
🕐 집중 타이머로 생산성을 극대화하세요!

📚 주요 기능:
• 다양한 색상으로 타이머 분류
• 일별/주별 통계 확인
• 달력에서 활동 기록 조회
• 다크모드 완벽 지원
• 포모도로 기법 지원
• 알림 및 사운드 피드백

✨ 특징:
• 직관적이고 깔끔한 디자인
• 한국어 완전 지원
• 오프라인에서도 완벽 동작
• 개인정보 보호 (데이터 로컬 저장)

💪 이런 분들께 추천:
• 공부 시간을 체계적으로 관리하고 싶은 학생
• 업무 효율성을 높이고 싶은 직장인
• 운동이나 취미 활동 시간을 측정하고 싶은 분
• 포모도로 기법을 실천하고 싶은 분

지금 시작해서 더 나은 내일을 만들어보세요! 🚀
```

#### 🔒 개인정보 보호정책
- 수집 정보: 없음 (모든 데이터 로컬 저장)
- 광고: 없음
- 인앱 구매: 없음
- 연령 등급: 4+

### 5. 실기기 테스트
```bash
# iOS 기기 연결 후
flutter run --release

# 테스트 항목:
# - 알림 권한 요청
# - 타이머 기능
# - 백그라운드 알림
# - 데이터 저장/불러오기
```

## 🎨 리소스 파일

### 앱 아이콘
현재 SVG 형태로 생성됨. PNG 변환 필요:
- `assets/icon/app_icon.svg` → 1024x1024 PNG 변환

### 스플래시 화면
- `assets/splash/splash_icon.svg` (라이트모드)
- `assets/splash/splash_icon_dark.svg` (다크모드)

## 📋 체크리스트

### 배포 전 최종 확인
- [ ] Apple Developer 계정 준비
- [ ] 앱 아이콘 PNG 변환 (1024x1024)
- [ ] 스크린샷 촬영 (모든 기기 크기)
- [ ] 개인정보 보호정책 작성
- [ ] App Store Connect 앱 등록
- [ ] 실기기 테스트 완료
- [ ] 메타데이터 작성 완료

### 제출 후
- [ ] 앱 심사 대기
- [ ] 심사 완료 후 출시
- [ ] 사용자 피드백 모니터링
- [ ] 업데이트 계획 수립

## 🔧 문제 해결

### 일반적인 문제
1. **빌드 오류**: `flutter clean && flutter pub get` 실행
2. **코드사인 오류**: Xcode에서 Team 설정 확인
3. **권한 오류**: Info.plist 권한 설정 확인

### 연락처
배포 과정에서 문제가 발생하면 Flutter 커뮤니티나 Apple Developer Support에 문의하세요.

---
**마지막 업데이트**: 2025년 6월 14일
**앱 버전**: 1.0.0+1
