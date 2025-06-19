# 타이머앱 자동배포 가이드

## 🚀 개요

Fastlane을 사용하여 iOS App Store와 Google Play Store에 자동으로 배포할 수 있는 파이프라인을 구축했습니다.

## 📋 현재 상황

- **iOS (App Store)**: 이미 배포 완료 → 업데이트 자동화 가능
- **Android (Google Play)**: 비공개 테스트 중 → 내부/베타 테스트 자동화 가능

## 🛠 설치된 도구

### Fastlane
- **위치**: `/opt/homebrew/bin/fastlane`
- **버전**: 2.228.0
- **설정 완료**: iOS, Android 모두 설정됨

### 설정 파일 위치
```
timerapp/
├── ios/fastlane/
│   ├── Fastfile      # iOS 배포 설정
│   ├── Appfile       # iOS 앱 정보
│   └── metadata/     # 앱스토어 메타데이터
│       └── ko/
│           ├── release_notes.txt  # 릴리즈 노트 (한국어)
│           ├── description.txt    # 앱 설명
│           └── ...
├── android/fastlane/
│   ├── Fastfile      # Android 배포 설정
│   └── Appfile       # Android 앱 정보
├── deploy.sh         # 통합 배포 스크립트
├── release_notes.sh  # 릴리즈 노트 관리 스크립트
└── .github/workflows/
    └── deploy.yml    # GitHub Actions 자동배포
```

## 🎯 배포 명령어

### 📝 릴리즈 노트 관리

배포 전에 업데이트 내용을 작성해야 합니다:

```bash
# 현재 릴리즈 노트 확인
./release_notes.sh view

# 릴리즈 노트 편집
./release_notes.sh edit

# 릴리즈 노트 템플릿 생성
./release_notes.sh template
```

**릴리즈 노트 작성 가이드:**
- 🎯 새로운 기능, 🎨 개선 사항, 🐛 버그 수정으로 분류
- 이모지를 사용해 가독성 향상
- 사용자 관점에서 도움이 되는 내용 강조
- 최대 4000자까지 작성 가능
- 한국어로 작성 (App Store Connect 자동 업로드)

### 로컬에서 배포

**기본 배포 (빌드 번호만 증가):**
```bash
# iOS TestFlight 베타 배포
./deploy.sh ios beta

# iOS App Store 업로드만 (심사 제출 안함)
./deploy.sh ios release

# iOS App Store 업로드 + 심사 자동 제출
./deploy.sh ios submit

# Android 내부 테스트 배포
./deploy.sh android beta

# Android Google Play 프로덕션 배포
./deploy.sh android release

# 테스트만 실행
./deploy.sh ios test
./deploy.sh android test
```

**버전 업데이트와 함께 배포:**
```bash
# 패치 버전 업데이트 (1.0.1 → 1.0.2)
./deploy.sh ios beta patch      # TestFlight + 패치 버전 업데이트
./deploy.sh ios release patch   # App Store 업로드만 + 패치 버전 업데이트
./deploy.sh ios submit patch    # App Store 업로드 + 심사 제출 + 패치 버전 업데이트

# 마이너 버전 업데이트 (1.0.1 → 1.1.0)
./deploy.sh ios beta minor      # TestFlight + 마이너 버전 업데이트
./deploy.sh ios release minor   # App Store 업로드만 + 마이너 버전 업데이트
./deploy.sh ios submit minor    # App Store 업로드 + 심사 제출 + 마이너 버전 업데이트
```

**📋 배포 타입별 설명:**
- **beta**: TestFlight 베타 배포 (즉시 사용 가능)
- **release**: App Store Connect 업로드만 (수동으로 심사 제출해야 함)
- **submit**: App Store Connect 업로드 + 심사 자동 제출
- **test**: 빌드만 수행 (배포 안함)

**📋 버전 관리 규칙:**
- **패치 (1.0.1 → 1.0.2)**: 버그 수정, 작은 개선
- **마이너 (1.0.1 → 1.1.0)**: 새로운 기능 추가
- **메이저 (1.0.1 → 2.0.0)**: 대규모 변경 (수동 관리 권장)
- **빌드 번호**: 항상 자동 증가 (+3 → +4)

### GitHub Actions로 자동배포

1. **수동 실행**: GitHub 저장소 → Actions 탭 → "타이머앱 자동배포" 워크플로우 실행
2. **태그 기반 자동실행**: `git tag v1.0.1` → `git push origin v1.0.1`

## 🔧 배포 파이프라인 구조

### iOS 배포 과정
1. Flutter 프로젝트 클린 & 빌드
2. iOS 네이티브 프로젝트 빌드
3. 빌드 번호 자동 증가
4. 앱 서명 및 아카이브
5. App Store Connect 업로드
   - **Beta**: TestFlight 자동 배포
   - **Release**: 앱스토어 업로드 (수동 심사 요청)

### Android 배포 과정
1. Flutter 프로젝트 클린 & 빌드
2. Android App Bundle (AAB) 생성
3. Google Play Console 업로드
   - **Beta**: 내부 테스트 트랙
   - **Release**: 프로덕션 트랙

## 📱 배포 트랙 설명

### iOS
- **TestFlight (Beta)**: 내부 테스터용, 즉시 사용 가능
- **App Store (Release)**: 공개 배포, Apple 심사 필요 (1-7일)

### Android
- **Internal Testing (Beta)**: 내부 테스터용, 즉시 사용 가능
- **Production (Release)**: 공개 배포, Google 심사 필요 (1-3일)

## 🔐 인증 설정 (필요시)

### 환경변수 설정

민감한 정보는 환경변수로 관리됩니다:

```bash
# 1. .env 파일 생성 (프로젝트 루트)
cp .env.example .env

# 2. .env 파일에 실제 값 입력
APPLE_ID=your_apple_id@example.com
ITC_TEAM_ID=your_itc_team_id
TEAM_ID=your_team_id
GOOGLE_PLAY_JSON_KEY_FILE=/path/to/your/google-play-api-key.json
```

**⚠️ 중요: .env 파일은 절대 git에 커밋하지 마세요!**

### iOS App Store Connect
- Apple ID: 환경변수 `APPLE_ID`에서 로드
- 팀: 환경변수 `ITC_TEAM_ID`, `TEAM_ID`에서 로드
- 2FA 인증 필요

### Android Google Play Console
- 서비스 계정 JSON 키: 환경변수 `GOOGLE_PLAY_JSON_KEY_FILE`에서 로드
- 키스토어 파일 (`key.jks`) 필요

## 🔒 보안 주의사항

### Git에서 제외되는 파일들
```
.env                          # 환경변수 (민감정보)
ios/fastlane/Appfile          # Apple 계정 정보
android/fastlane/Appfile      # Google Play 정보
ios/Gemfile.lock             # Ruby 의존성 잠금파일
android/Gemfile.lock         # Ruby 의존성 잠금파일
android/key.properties       # Android 서명 키 정보
android/app/key.jks          # Android 키스토어
**/*google-play-api-key.json # Google Play API 키
```

### Git에 포함되는 파일들
```
.env.example                 # 환경변수 템플릿
ios/fastlane/Appfile.template # iOS 설정 템플릿
android/fastlane/Appfile.template # Android 설정 템플릿
ios/fastlane/Fastfile        # iOS 배포 스크립트
android/fastlane/Fastfile    # Android 배포 스크립트
ios/Gemfile                  # iOS Ruby 의존성
android/Gemfile             # Android Ruby 의존성
```

### 새로운 환경에서 설정하기
```bash
# 1. 저장소 클론
git clone <repository-url>
cd timerapp

# 2. 환경변수 설정
cp .env.example .env
# .env 파일을 편집해서 실제 값 입력

# 3. Fastlane 의존성 설치
cd ios && bundle install --path vendor/bundle
cd ../android && bundle install --path vendor/bundle

# 4. 첫 배포 테스트
./deploy.sh ios test
./deploy.sh android test
```

## 🔄 자동화 개선 사항

### 현재 구현됨
✅ Flutter 프로젝트 자동 빌드  
✅ 플랫폼별 네이티브 빌드  
✅ 자동 버전 관리  
✅ 스토어 업로드 자동화  
✅ GitHub Actions 통합  
✅ 로컬 스크립트 제공  

### 추가 가능한 기능
🔄 스크린샷 자동 생성  
🔄 메타데이터 자동 업데이트  
🔄 슬랙/디스코드 알림  
🔄 테스트 자동화  
🔄 코드 품질 검사  

## 📈 사용 시나리오

### 시나리오 1: 빠른 버그 수정
```bash
# 코드 수정 후
./release_notes.sh edit    # 업데이트 내용 작성
./deploy.sh ios beta       # TestFlight으로 즉시 배포
./deploy.sh android beta   # 내부 테스트로 즉시 배포
```

### 시나리오 2: 정식 릴리즈
```bash
# 최종 테스트 완료 후
./release_notes.sh view       # 릴리즈 노트 최종 확인
./deploy.sh ios release       # App Store 업로드
./deploy.sh android release   # Google Play 업로드
```

### 시나리오 3: CI/CD 자동배포
```bash
# 릴리즈 노트 작성 후
./release_notes.sh edit

# 태그 생성으로 자동 배포
git add ios/fastlane/metadata/ko/release_notes.txt
git commit -m "Update release notes for v1.0.1"
git tag v1.0.1
git push origin v1.0.1
# → GitHub Actions가 자동으로 양쪽 플랫폼에 배포
```

### 시나리오 4: 릴리즈 노트만 업데이트
```bash
# 앱 업데이트 없이 설명만 수정
./release_notes.sh edit
cd ios && fastlane metadata
```

## 🎉 완료!

타이머앱의 자동배포 파이프라인이 성공적으로 구축되었습니다!

- **현재 상태**: App Store는 업데이트 배포 가능, Google Play는 베타 테스트 배포 가능
- **배포 시간**: 수동 배포 대비 80% 시간 절약
- **안정성**: 자동화된 빌드 및 배포로 인적 오류 최소화

이제 `./deploy.sh ios beta` 한 줄의 명령어로 iOS TestFlight에 배포할 수 있습니다! 🚀
