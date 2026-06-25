#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/xcode_env.sh

SCHEME="${SCHEME:-OpsPulse}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"
BUNDLE_ID="${BUNDLE_ID:-com.naga.OpsPulse}"
export SIMULATOR_NAME
DEVICE_ID="$(SIMULATOR_NAME="$SIMULATOR_NAME" xcrun simctl list devices available -j | python3 -c 'import json, os, sys
name = os.environ["SIMULATOR_NAME"]
devices = [d for group in json.load(sys.stdin)["devices"].values() for d in group if d.get("isAvailable")]
match = next((d for d in devices if d["name"] == name), None)
if match is None:
    match = next((d for d in devices if d["name"].startswith("iPhone")), None)
if match is None:
    sys.exit("No available iPhone simulator found.")
print(match["udid"])')"

xcodebuild \
  -project OpsPulse.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug-iphonesimulator" -name 'OpsPulse.app' -maxdepth 2 -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "Could not locate OpsPulse.app under $DERIVED_DATA" >&2
  exit 1
fi

xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
open -a Simulator
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
echo "Launched OpsPulse on $SIMULATOR_NAME ($DEVICE_ID)."
