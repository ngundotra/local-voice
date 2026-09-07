#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE="$PROJECT_DIR/dist/Local Voice.app"
DEST="$HOME/Applications/Local Voice.app"
[[ -x "$SOURCE/Contents/MacOS/LocalVoice" ]] || { echo 'Run bash scripts/build.sh first.' >&2; exit 1; }
[[ ! -e "$DEST" ]] || { echo "Already installed: $DEST. Quit the app and move the old app to Trash before reinstalling." >&2; exit 1; }
mkdir -p "$HOME/Applications"
ditto "$SOURCE" "$DEST"
codesign --verify --strict "$DEST"
echo "Installed: $DEST"
echo 'Launch with: open "$HOME/Applications/Local Voice.app"'
