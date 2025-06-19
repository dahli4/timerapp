#!/bin/bash

# 타이머앱 자동배포 스크립트
# 사용법: ./deploy.sh [ios|android] [beta|release] [patch|minor|major]

set -e

PLATFORM=$1
LANE=$2
VERSION_BUMP=$3

if [ -z "$PLATFORM" ] || [ -z "$LANE" ]; then
    echo "사용법: ./deploy.sh [ios|android] [beta|release|submit|test] [patch|minor|major]"
    echo ""
    echo "플랫폼:"
    echo "  ios     - iOS 앱스토어 배포"
    echo "  android - Google Play 배포"
    echo ""
    echo "배포 타입:"
    echo "  beta    - 베타 테스트 배포"
    echo "  release - 프로덕션 배포 (업로드만, 심사 제출 안함)"
    echo "  submit  - 프로덕션 배포 + 심사 자동 제출"
    echo "  test    - 테스트 실행"
    echo ""
    echo "버전 업데이트 (선택사항):"
    echo "  patch   - 패치 업데이트 (1.0.1 → 1.0.2)"
    echo "  minor   - 마이너 업데이트 (1.0.1 → 1.1.0)"
    echo "  major   - 메이저 업데이트 (1.0.1 → 2.0.0)"
    echo "  생략    - 버전 변경 없이 빌드 번호만 증가"
    echo ""
    echo "예시:"
    echo "  ./deploy.sh ios beta          # iOS TestFlight 베타 배포"
    echo "  ./deploy.sh ios release patch # iOS 앱스토어 업로드만 + 패치 버전 업데이트"
    echo "  ./deploy.sh ios submit minor  # iOS 앱스토어 업로드 + 심사 제출 + 마이너 버전 업데이트"
    echo "  ./deploy.sh android release   # Google Play 프로덕션 배포"
    exit 1
fi

echo "🚀 타이머앱 자동배포 시작"
echo "플랫폼: $PLATFORM"
echo "타입: $LANE"
echo ""

# Flutter 프로젝트 체크
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Flutter 프로젝트 루트 디렉토리에서 실행해주세요"
    exit 1
fi

# Flutter 환경 체크
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter가 설치되지 않았습니다"
    exit 1
fi

# Fastlane 환경 체크
if ! command -v fastlane &> /dev/null; then
    echo "❌ Fastlane이 설치되지 않았습니다"
    exit 1
fi

# 플랫폼별 배포
case $PLATFORM in
    ios)
        echo "📱 iOS 배포 시작..."
        
        # 릴리즈 노트 확인
        if [ -f "ios/fastlane/metadata/ko/release_notes.txt" ]; then
            echo ""
            echo "📝 현재 릴리즈 노트:"
            echo "────────────────────────────────────────"
            cat ios/fastlane/metadata/ko/release_notes.txt
            echo "────────────────────────────────────────"
            echo ""
            read -p "릴리즈 노트를 확인했습니다. 계속하시겠습니까? (y/N): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "배포가 취소되었습니다."
                echo "릴리즈 노트를 수정하려면: ./release_notes.sh edit"
                exit 1
            fi
        fi
        
        cd ios
        case $LANE in
            beta)
                echo "🧪 TestFlight 베타 배포..."
                if [ "$VERSION_BUMP" = "patch" ]; then
                    echo "📈 패치 버전 업데이트 포함"
                    fastlane beta_patch
                elif [ "$VERSION_BUMP" = "minor" ]; then
                    echo "📈 마이너 버전 업데이트 포함"
                    fastlane beta_minor
                else
                    echo "🔢 빌드 번호만 증가"
                    fastlane beta
                fi
                ;;
            release)
                echo "🚀 App Store 배포 (업로드만)..."
                if [ "$VERSION_BUMP" = "patch" ]; then
                    echo "📈 패치 버전 업데이트 포함"
                    fastlane release_patch
                elif [ "$VERSION_BUMP" = "minor" ]; then
                    echo "📈 마이너 버전 업데이트 포함"
                    fastlane release_minor
                else
                    echo "🔢 빌드 번호만 증가"
                    fastlane release
                fi
                ;;
            submit)
                echo "🚀 App Store 배포 + 심사 제출..."
                echo "⚠️  주의: 심사에 자동으로 제출됩니다!"
                read -p "계속하시겠습니까? (y/N): " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "배포가 취소되었습니다."
                    exit 1
                fi
                fastlane release_submit
                ;;
            test)
                echo "🧪 iOS 테스트..."
                fastlane build
                ;;
            *)
                echo "❌ 지원하지 않는 iOS 배포 타입: $LANE"
                exit 1
                ;;
        esac
        ;;
    android)
        echo "🤖 Android 배포 시작..."
        cd android
        case $LANE in
            beta)
                echo "🧪 Google Play 내부 테스트 배포..."
                fastlane beta
                ;;
            release)
                echo "🚀 Google Play Store 배포..."
                fastlane deploy
                ;;
            test)
                echo "🧪 Android 테스트..."
                fastlane test
                ;;
            *)
                echo "❌ 지원하지 않는 Android 배포 타입: $LANE"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "❌ 지원하지 않는 플랫폼: $PLATFORM"
        exit 1
        ;;
esac

echo ""
echo "✅ 배포 완료!"
echo "📱 $PLATFORM $LANE 배포가 성공적으로 완료되었습니다."
