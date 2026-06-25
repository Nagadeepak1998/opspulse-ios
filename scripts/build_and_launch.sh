#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/xcode_env.sh

SCHEME="${SCHEME:-OpsPulse}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16 Pro}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"
BUNDLE_ID="${BUNDLE_ID:-com.naga.OpsPulse}"

xcodebuild \
  -project OpsPulse.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug-iphonesimulator" -name 'OpsPulse.app' -maxdepth 2 -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "Could not locate OpsPulse.app under $DERIVED_DATA" >&2
  exit 1
fi

DEVICE_ID="$(xcrun simctl list devices available | awk -v name="$SIMULATOR_NAME" '$0 ~ name && $0 ~ /Booted/ {gsub(/[()]/, "", $NF); print $NF; exit}')"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available | awk -v name="$SIMULATOR_NAME" '$0 ~ name {gsub(/[()]/, "", $NF); print $NF; exit}')"
fi
if [[ -z "$DEVICE_ID" ]]; then
  echo "No available simulator named $SIMULATOR_NAME." >&2
  xcrun simctl list devices available >&2
  exit 1
fi

xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
open -a Simulator
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
echo "Launched OpsPulse on $SIMULATOR_NAME ($DEVICE_ID)."
