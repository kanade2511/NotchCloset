#!/bin/bash
set -euo pipefail

APP="NotchCloset"
BUILD_DIR=".build/debug"
APP_DIR="${APP}.app"
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "==> Building..."
swift build

echo "==> Creating .app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp "${BUILD_DIR}/${APP}" "${MACOS}/"

# Bundle resources
BUNDLE="${BUILD_DIR}/${APP}_${APP}.bundle"
if [ -d "$BUNDLE" ]; then
    find "$BUNDLE" -name '*.lproj' -type d | while read lproj; do
        cp -R "$lproj" "$RESOURCES/"
    done
fi

# Bundle Info.plist
cat > "${CONTENTS}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP}</string>
    <key>CFBundleIdentifier</key>
    <string>com.kanade2511.${APP}</string>
    <key>CFBundleName</key>
    <string>${APP}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Done: open ${APP_DIR}"
