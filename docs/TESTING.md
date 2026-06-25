# Testing

## Verified Locally

The current local machine has Swift 6.1.2 available. The full Xcode install is not selected, so simulator tests are blocked.

Verified command:

```bash
swift test
```

Coverage:

- JSON encoding/decoding of the deterministic snapshot
- SLO permitted failure, consumed budget, remaining budget, burn rate, and classification
- Incident transition rules
- MTTA, mitigation time, and MTTR calculations
- Demo simulation behavior
- Runbook step completion state
- Post-incident Markdown report generation
- Network success, unauthorized, and decoding failure cases

## iOS Build Validation

After selecting full Xcode:

```bash
scripts/build.sh
scripts/build_and_launch.sh
```

## UI Smoke Tests To Add

- Launching in demo mode
- Opening a service
- Opening an incident
- Acknowledging an incident
- Completing one runbook step
- Running and resetting one reliability simulation

## Screenshot Validation

After launch:

```bash
scripts/capture_screenshots.sh
```

Capture:

- Reliability overview
- Service-detail metrics
- Active incident
- Reliability Lab
- Generated post-incident review

## Current Blocker

`xcodebuild -version` fails because the active developer directory is `/Library/Developer/CommandLineTools`, not full Xcode.
