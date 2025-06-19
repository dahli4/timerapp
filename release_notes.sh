#!/bin/bash

# 릴리즈 노트 관리 스크립트
# 사용법: ./release_notes.sh [edit|view|template]

set -e

RELEASE_NOTES_FILE="ios/fastlane/metadata/ko/release_notes.txt"
TEMPLATE_FILE="release_notes_template.txt"

# 릴리즈 노트 템플릿
create_template() {
    cat > "$TEMPLATE_FILE" << 'EOF'
🎯 새로운 기능
• 새로운 기능에 대한 설명을 여기에 추가하세요

🎨 개선 사항
• UI/UX 개선 내용을 여기에 추가하세요
• 성능 향상 내용을 여기에 추가하세요

🐛 버그 수정
• 수정된 버그에 대한 설명을 여기에 추가하세요

💡 팁: 
- 사용자에게 도움이 되는 변경사항을 강조하세요
- 이모지를 사용해 가독성을 높이세요
- 간결하고 명확하게 작성하세요
- 최대 4000자까지 작성 가능합니다
EOF
    echo "📝 릴리즈 노트 템플릿이 생성되었습니다: $TEMPLATE_FILE"
}

# 릴리즈 노트 편집
edit_notes() {
    if [ ! -f "$RELEASE_NOTES_FILE" ]; then
        echo "❌ 릴리즈 노트 파일을 찾을 수 없습니다: $RELEASE_NOTES_FILE"
        exit 1
    fi
    
    echo "📝 릴리즈 노트를 편집합니다..."
    echo "현재 내용:"
    echo "────────────────────────────────────────"
    cat "$RELEASE_NOTES_FILE"
    echo "────────────────────────────────────────"
    echo ""
    
    # 기본 에디터로 열기
    if command -v code &> /dev/null; then
        code "$RELEASE_NOTES_FILE"
        echo "💡 VS Code로 열었습니다. 편집 완료 후 저장하세요."
    elif command -v nano &> /dev/null; then
        nano "$RELEASE_NOTES_FILE"
    elif command -v vim &> /dev/null; then
        vim "$RELEASE_NOTES_FILE"
    else
        echo "❌ 사용 가능한 에디터를 찾을 수 없습니다."
        echo "다음 명령어로 직접 편집하세요:"
        echo "open -a TextEdit $RELEASE_NOTES_FILE"
        exit 1
    fi
}

# 릴리즈 노트 보기
view_notes() {
    if [ ! -f "$RELEASE_NOTES_FILE" ]; then
        echo "❌ 릴리즈 노트 파일을 찾을 수 없습니다: $RELEASE_NOTES_FILE"
        exit 1
    fi
    
    echo "📱 현재 iOS 릴리즈 노트:"
    echo "════════════════════════════════════════"
    cat "$RELEASE_NOTES_FILE"
    echo "════════════════════════════════════════"
    echo ""
    echo "📊 글자 수: $(wc -c < "$RELEASE_NOTES_FILE") / 4000"
    echo "📝 줄 수: $(wc -l < "$RELEASE_NOTES_FILE")"
}

# 도움말 출력
show_help() {
    echo "📱 타이머앱 릴리즈 노트 관리 도구"
    echo ""
    echo "사용법: ./release_notes.sh [명령어]"
    echo ""
    echo "명령어:"
    echo "  edit      릴리즈 노트 편집"
    echo "  view      현재 릴리즈 노트 보기"
    echo "  template  릴리즈 노트 템플릿 생성"
    echo "  help      도움말 출력"
    echo ""
    echo "예시:"
    echo "  ./release_notes.sh edit      # 릴리즈 노트 편집"
    echo "  ./release_notes.sh view      # 현재 내용 확인"
    echo "  ./release_notes.sh template  # 템플릿 생성"
    echo ""
    echo "📍 릴리즈 노트 위치: $RELEASE_NOTES_FILE"
    echo ""
    echo "💡 팁:"
    echo "- 릴리즈 노트는 한국어로 작성됩니다"
    echo "- 최대 4000자까지 작성 가능합니다"
    echo "- 배포 시 자동으로 App Store Connect에 업로드됩니다"
}

# 메인 로직
case "${1:-help}" in
    edit)
        edit_notes
        ;;
    view)
        view_notes
        ;;
    template)
        create_template
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ 알 수 없는 명령어: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
