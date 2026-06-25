# Screenshots

Simulator screenshots are intentionally not faked in this repository.

Capture them after selecting full Xcode:

```bash
scripts/build_and_launch.sh
scripts/capture_screenshots.sh
```

Expected outputs:

- `overview.png`
- `service-detail.png`
- `active-incident.png`
- `reliability-lab.png`
- `post-incident-review.png`

Current local blocker: `xcodebuild` is using `/Library/Developer/CommandLineTools`, and `simctl` is unavailable until full Xcode is selected.
