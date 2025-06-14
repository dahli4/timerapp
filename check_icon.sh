#!/bin/bash

echo "🎨 새 타이머 캐릭터 아이콘 적용 중..."

# PNG 아이콘이 있는지 확인
if [ -f "assets/icon/timer_app_icon.png" ]; then
    echo "✅ PNG 아이콘 파일이 발견되었습니다."
    
    # 파일 정보 확인
    if command -v file > /dev/null; then
        file assets/icon/timer_app_icon.png
    fi
    
    # 아이콘 크기 확인 (sips 명령어 사용)
    if command -v sips > /dev/null; then
        echo "📏 이미지 크기:"
        sips -g pixelWidth -g pixelHeight assets/icon/timer_app_icon.png
    fi
    
    echo ""
    echo "🚀 다음 명령어로 앱 아이콘을 생성하세요:"
    echo "flutter pub run flutter_launcher_icons:main"
    
else
    echo "❌ timer_app_icon.png 파일이 assets/icon/ 폴더에 없습니다."
    echo "📝 다음 중 하나를 수행해주세요:"
    echo "1. 제공된 이미지를 assets/icon/timer_app_icon.png로 저장"
    echo "2. 또는 온라인 도구로 1024x1024 PNG 변환"
fi
