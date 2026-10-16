#!/bin/bash
# 双击此文件即可构建并安装 LifeClock 屏保
# 流程：build_saver.sh 构建 → 拷到 /tmp 绕过 TCC → osascript 提权安装到 /Library/Screen Savers

set -euo pipefail
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "╔══════════════════════════════════════════╗"
echo "║     LifeClock 屏保构建 + 安装工具          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. 构建 ──
echo "[1/3] 构建中..."
bash "$PROJECT_DIR/build_saver.sh"
echo ""

# ── 2. 暂存到 /tmp（绕过 ~/Documents 的 TCC 限制）──
echo "[2/3] 准备安装包..."
rm -rf /tmp/LifeClock.saver
cp -R "$PROJECT_DIR/LifeClock.saver" /tmp/LifeClock.saver
xattr -cr /tmp/LifeClock.saver
codesign --force --sign - --timestamp=none --generate-entitlement-der /tmp/LifeClock.saver
codesign --verify /tmp/LifeClock.saver
echo "  签名验证通过"
echo ""

# ── 3. 提权安装到系统目录 ──
echo "[3/3] 安装到 /Library/Screen Savers（需要输入密码）..."
osascript -e "do shell script \"
  rm -rf /Library/Screen\\ Savers/LifeClock.saver &&
  cp -R /tmp/LifeClock.saver /Library/Screen\\ Savers/LifeClock.saver &&
  xattr -cr /Library/Screen\\ Savers/LifeClock.saver &&
  chown -R root:admin /Library/Screen\\ Savers/LifeClock.saver &&
  codesign --verify /Library/Screen\\ Savers/LifeClock.saver &&
  killall legacyScreenSaver 2>/dev/null;
  killall ScreenSaverEngine 2>/dev/null;
  echo done
\" with administrator privileges"
echo ""

echo "╔══════════════════════════════════════════╗"
echo "║  安装完成！                               ║"
echo "║  系统设置 → 屏幕保护程序 → 选择 LifeClock  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "窗口可以关闭了。"
