#!/bin/bash
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$PROJECT_DIR/WebViewScreenSaver/build/Release"
OUTPUT_DIR="$PROJECT_DIR"
SAVER_NAME="LifeClock.saver"

echo "=== LifeClock Screen Saver Build Script ==="
echo ""

cd "$PROJECT_DIR/WebViewScreenSaver"

echo "Syncing index.html from project root..."
# 根目录 index.html 是唯一源文件，Xcode 打包用的是 WebViewScreenSaver/Resources/index.html
cp "$PROJECT_DIR/index.html" "$PROJECT_DIR/WebViewScreenSaver/Resources/index.html"

echo "Cleaning extended attributes from source resources..."
xattr -cr "$PROJECT_DIR/WebViewScreenSaver/Resources/"

echo "Building (arm64 + x86_64)..."
# 跳过 xcodebuild 自带的签名（因资源文件扩展属性导致失败），改为手动签名
xcodebuild -project WebViewScreenSaver.xcodeproj -target LifeClock -configuration Release \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build

echo "Cleaning extended attributes from build output for signing..."
xattr -cr "$BUILD_DIR/$SAVER_NAME"
codesign --force --sign - --timestamp=none --generate-entitlement-der "$BUILD_DIR/$SAVER_NAME"

echo ""
echo "Build succeeded!"
echo ""

echo "Copying to $OUTPUT_DIR..."
rm -rf "$OUTPUT_DIR/$SAVER_NAME"
cp -R "$BUILD_DIR/LifeClock.saver" "$OUTPUT_DIR/$SAVER_NAME"

# 注意：不要在此处再覆盖 index.html —— 那会让上面的 codesign 失效。
# index.html 已在构建前同步，由 Xcode 打进 bundle 并一起签名。

echo ""
echo "Updating .saver bundle modification time for Finder..."
find "$OUTPUT_DIR/$SAVER_NAME" -exec touch {} \;

echo ""
echo "Verifying code signature..."
codesign --verify --verbose=1 "$OUTPUT_DIR/$SAVER_NAME"

echo ""
echo "=== Done! ==="
echo "Output: $OUTPUT_DIR/$SAVER_NAME"