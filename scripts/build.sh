#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP="$PROJECT_DIR/dist/Local Voice.app"
mkdir -p "$APP/Contents/MacOS"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>LocalVoice</string>
<key>CFBundleIdentifier</key><string>local.whisperstarter.voicehotkey</string>
<key>CFBundleName</key><string>Local Voice</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSUIElement</key><true/>
<key>NSMicrophoneUsageDescription</key><string>Record your voice when you press Control–Option–Space, then transcribe locally with Whisper.</string>
</dict></plist>
PLIST
xcrun swiftc "$PROJECT_DIR/src/VoiceHotkey.swift" -o "$APP/Contents/MacOS/LocalVoice" -framework Cocoa -framework AVFoundation -framework Carbon -module-cache-path "$PROJECT_DIR/.swift-module-cache"
codesign --force --sign - "$APP"
printf 'Built: %s\n' "$APP"
