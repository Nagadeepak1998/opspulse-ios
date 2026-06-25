#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/xcode_env.sh

SCHEME="${SCHEME:-OpsPulse}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16 Pro}"

xcodebuild \
  -project OpsPulse.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" \
  CODE_SIGNING_ALLOWED=NO \
  build
