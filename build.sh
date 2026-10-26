#!/bin/bash
set -e

APP_NAME="JobPipeline"
BUNDLE_ID="com.jobpipeline.app"
BUILD_DIR="/tmp/${APP_NAME}_build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
SDK=$(xcrun --sdk macosx --show-sdk-path)
TARGET="x86_64-apple-macosx13.0"

echo "=== Building $APP_NAME ==="

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Compile
echo "Compiling Swift sources..."
SOURCES=$(find "$(dirname "$0")/Sources" -name "*.swift" | sort)
echo "$SOURCES"

swiftc \
    -sdk "$SDK" \
    -target "$TARGET" \
    -O \
    -framework SwiftUI \
    -framework AppKit \
    -lsqlite3 \
    -o "$MACOS/$APP_NAME" \
    $SOURCES

echo "Compiled OK"

# Info.plist
cp "$(dirname "$0")/Info.plist" "$CONTENTS/Info.plist"

# Resources: asset catalog (light/dark icon) + icns fallback
if [ -f "$(dirname "$0")/Resources/Assets.car" ]; then
    cp "$(dirname "$0")/Resources/Assets.car" "$RESOURCES/Assets.car"
fi
if [ -f "$(dirname "$0")/Resources/AppIcon.icns" ]; then
    cp "$(dirname "$0")/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi
# Named light/dark variants for programmatic Dock icon
if [ -f "$(dirname "$0")/Resources/pipeline-light.icns" ]; then
    cp "$(dirname "$0")/Resources/pipeline-light.icns" "$RESOURCES/AppIcon-light.icns"
fi
if [ -f "$(dirname "$0")/Resources/pipeline-dark.icns" ]; then
    cp "$(dirname "$0")/Resources/pipeline-dark.icns" "$RESOURCES/AppIcon-dark.icns"
fi

# PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

# Ad-hoc codesign
echo "Signing..."
xattr -cr "$APP_DIR" 2>/dev/null
codesign --force --deep --sign - "$APP_DIR" 2>&1

echo ""
echo "=== SUCCESS ==="
echo "App at: $APP_DIR"
echo "To install: cp -R '$APP_DIR' /Applications/"
echo "To run: open '$APP_DIR'"
