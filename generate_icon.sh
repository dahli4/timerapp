#!/bin/bash

# 집중 타이머 앱 아이콘 생성 스크립트

echo "🎨 앱 아이콘 PNG 생성을 위한 안내"
echo ""
echo "현재 SVG 파일이 생성되어 있습니다:"
echo "- assets/icon/app_icon.svg"
echo ""
echo "📋 1024x1024 PNG 변환 방법:"
echo ""
echo "1. 온라인 변환 도구 사용:"
echo "   • convertio.co/svg-png"
echo "   • cloudconvert.com"
echo "   • 또는 GIMP, Photoshop 등"
echo ""
echo "2. macOS 기본 도구 사용:"
echo "   • assets/icon/app_icon.svg를 미리보기 앱에서 열기"
echo "   • 파일 → 내보내기 → PNG 선택"
echo "   • 해상도: 1024x1024 픽셀로 설정"
echo ""
echo "3. 명령줄 도구 설치 (선택사항):"
echo "   brew install imagemagick"
echo "   convert assets/icon/app_icon.svg -resize 1024x1024 assets/icon/app_icon.png"
echo ""
echo "✅ PNG 변환 후 다음 명령어로 아이콘 생성:"
echo "   flutter pub run flutter_launcher_icons:main"
echo ""

# SVG 내용이 올바른지 확인
if [ -f "assets/icon/app_icon.svg" ]; then
    echo "✅ SVG 파일이 존재합니다."
    echo "파일 크기: $(ls -lh assets/icon/app_icon.svg | awk '{print $5}')"
else
    echo "❌ SVG 파일이 없습니다. 먼저 SVG 파일을 확인해주세요."
fi
