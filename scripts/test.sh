#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

swift test

if xcodebuild -version >/dev/null 2>&1; then
  python3 tools/generate_xcode_project.py >/dev/null
  SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16 Pro}"
  xcodebuild \
    -project OpsPulse.xcodeproj \
    -scheme OpsPulse \
    -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" \
    CODE_SIGNING_ALLOWED=NO \
    build
else
  echo "Swift package tests passed. Skipping iOS app build because full Xcode is not selected." >&2
  echo "Run scripts/build.sh after selecting Xcode to validate the app, widget, and SwiftUI sources." >&2
fi
