#!/bin/bash
# 타이머 아이콘 생성 스크립트

echo "타이머 아이콘을 생성하는 중..."

# 제공받은 이미지가 있다면 사용하고, 없다면 앱 아이콘 생성
if [ ! -f "assets/icon/timer_app_icon.png" ]; then
    echo "타이머 아이콘이 없습니다. 기본 아이콘을 생성합니다..."
    
    # 1024x1024 크기의 아이콘 디렉토리 생성
    mkdir -p assets/icon
    
    # Flutter의 기본 아이콘을 복사 (임시)
    if [ -f "web/favicon.png" ]; then
        cp web/favicon.png assets/icon/timer_app_icon.png
        echo "임시 아이콘을 생성했습니다."
    else
        echo "기본 아이콘 파일을 찾을 수 없습니다."
        echo "수동으로 assets/icon/timer_app_icon.png 파일을 추가해주세요."
    fi
fi

echo "아이콘 생성이 완료되었습니다!"
echo "flutter pub run flutter_launcher_icons 명령어로 앱 아이콘을 적용하세요."
