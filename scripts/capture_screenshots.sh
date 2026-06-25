#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/xcode_env.sh

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16 Pro}"
DEVICE_ID="$(xcrun simctl list devices available | awk -v name="$SIMULATOR_NAME" '$0 ~ name && $0 ~ /Booted/ {gsub(/[()]/, "", $NF); print $NF; exit}')"
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
