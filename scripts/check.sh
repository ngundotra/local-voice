#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "$0")/.." && pwd)"
for script in "$PROJECT_DIR"/scripts/*.sh; do bash -n "$script"; done
APP="$PROJECT_DIR/dist/Local Voice.app"
plutil -lint "$APP/Contents/Info.plist"
codesign --verify --strict "$APP"
OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/local-voice-check.XXXXXX")"
"$APP/Contents/MacOS/LocalVoice" --self-test "$HOME/.local/share/whisper-starter/whisper.cpp/samples/jfk.wav" "$OUTPUT/smoke-test"
grep -qi 'ask not what your country can do for you' "$OUTPUT/smoke-test.txt"
echo "Sample transcription passed. Output retained at $OUTPUT/smoke-test.txt"
