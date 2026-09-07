#!/bin/bash
set -euo pipefail

abort() {
  printf "%s\n" "$@"
  exit 1
}

if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

if [[ "$(uname)" != "Darwin" ]]; then
  abort "LifeClock is only supported on macOS."
fi

if ! command -v xcodebuild >/dev/null; then
    abort "Install process requires Xcode."
fi

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

printf 'Building LifeClock...\n'
cd "$PROJECT_DIR/WebViewScreenSaver"

xcodebuild -project WebViewScreenSaver.xcodeproj \
  -target LifeClock \
  -configuration Release \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  build

printf ' Done\n'

printf 'Installing LifeClock.saver...'
BUILD_DIR="build/Release"
cp -pr "$BUILD_DIR/LifeClock.saver" "${HOME}/Library/Screen Savers"
printf ' Done\n'

printf '\n=== LifeClock 安装完成！==='
printf '\n请前往 "系统设置 → 屏幕保护程序" 中选择 LifeClock。\n'