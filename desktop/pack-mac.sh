#!/bin/bash
# 맥용 「인생라멘.app」 만들기 (Electron 앱 껍데기에 게임을 넣음)
# 사용: cd desktop && ./pack-mac.sh   → dist/인생라멘.app
set -e
cd "$(dirname "$0")"
export PATH="$HOME/.local/node/bin:$PATH"
node build.mjs

APP="dist/인생라멘.app"
rm -rf "$APP" && mkdir -p dist
ditto node_modules/electron/dist/Electron.app "$APP"          # Electron 껍데기 복사 (기호 링크 유지)

RES="$APP/Contents/Resources"
rm -f "$RES/default_app.asar"
mkdir -p "$RES/app"
cp package.json main.js "$RES/app/"
ditto app "$RES/app/app"                                       # 게임 파일

# 앱 이름·번들 정보 바꾸기
PL="$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName 인생라멘" "$PL"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 인생라멘" "$PL" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string 인생라멘" "$PL"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.insaengramen.game" "$PL"
VER=$(node -p "require('./package.json').version")
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VER" "$PL"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VER" "$PL"

# 서명 안 된 앱을 내 맥에서 열 수 있게 임시 서명 (스팀 배포 때는 정식 서명이 필요)
codesign --force --deep --sign - "$APP" 2>/dev/null || true
echo "완성: $(pwd)/$APP"
