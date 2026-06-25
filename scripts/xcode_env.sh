#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not installed. Install Xcode from the App Store or Apple Developer downloads." >&2
  exit 127
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  fi
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "xcodebuild is present but full Xcode is not selected." >&2
  echo "Current developer directory: $(xcode-select -p 2>/dev/null || echo unknown)" >&2
  echo "Fix: install Xcode, then run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  echo "Alternative for one command: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer $0" >&2
  exit 69
fi

python3 tools/generate_xcode_project.py >/dev/null
