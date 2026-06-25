#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/xcode_env.sh

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro}"
export SIMULATOR_NAME
DEVICE_ID="$(SIMULATOR_NAME="$SIMULATOR_NAME" xcrun simctl list devices available -j | python3 -c 'import json, os, sys
name = os.environ["SIMULATOR_NAME"]
devices = [d for group in json.load(sys.stdin)["devices"].values() for d in group if d.get("isAvailable") and d.get("state") == "Booted"]
match = next((d for d in devices if d["name"] == name), None)
if match is None:
    match = next((d for d in devices if d["name"].startswith("iPhone")), None)
if match is not None:
    print(match["udid"])')"
if [[ -z "$DEVICE_ID" ]]; then
  echo "Boot and launch OpsPulse first with scripts/build_and_launch.sh." >&2
  exit 1
fi

mkdir -p docs/screenshots
echo "Capture each requested screen after navigating in Simulator."
for name in overview service-detail active-incident reliability-lab post-incident-review; do
  read -r -p "Navigate to ${name}, then press Return to capture..."
  xcrun simctl io "$DEVICE_ID" screenshot "docs/screenshots/${name}.png"
done
