#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/xcode_env.sh

SCHEME="${SCHEME:-OpsPulse}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
BUNDLE_ID="${BUNDLE_ID:-com.naga.OpsPulse}"
DERIVED_DATA="${DERIVED_DATA:-build/DerivedData}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-docs/screenshots/linkedin}"
export SIMULATOR_NAME

DEVICE_ID="$(xcrun simctl list devices available -j | python3 -c 'import json, os, sys
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

APP_PATH="$(find "$DERIVED_DATA/Build/Products/Debug-iphonesimulator" -name 'OpsPulse.app' -type d | head -1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Built app not found." >&2
  exit 1
fi

xcrun simctl shutdown "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
open -a Simulator
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl status_bar "$DEVICE_ID" override --time "9:41" --dataNetwork wifi --wifiBars 3 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true

mkdir -p "$SCREENSHOT_DIR"

capture() {
  local route="$1"
  local file="$2"
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" --screenshot-route "$route" >/dev/null
  sleep 1.5
  xcrun simctl io "$DEVICE_ID" screenshot --type=png "$SCREENSHOT_DIR/$file" >/dev/null
  echo "Captured $SCREENSHOT_DIR/$file"
}

capture "overview" "01-overview.png"
capture "services" "02-services.png"
capture "services/api-gateway" "03-service-detail.png"
capture "incidents" "04-incidents.png"
capture "incidents/INC-2025-0007" "05-incident-detail.png"
capture "lab" "06-reliability-lab.png"
