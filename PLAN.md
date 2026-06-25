# OpsPulse Implementation Plan

## Assumptions
- Build target is a new standalone repository under `showcase-repos/opspulse-ios`.
- Demo mode is the default and must work without credentials.
- Live mode is implemented as a compile-time-ready `URLSession` adapter with Keychain-backed token storage in the app layer, but no real backend credentials are required.
- The current machine has Apple Swift 6.1.2 but does not have a full Xcode installation selected, so simulator build, launch, and screenshots are expected to be blocked until Xcode is installed or `DEVELOPER_DIR` points at Xcode.
- GitHub token has `repo` scope but not `workflow` scope, so active workflow files cannot be pushed under `.github/workflows` until `workflow` scope is granted.

## Success Criteria
1. Core SRE domain logic is deterministic and covered by unit tests.
2. SwiftUI app source is organized by feature and supports iPhone/iPad layout, accessibility labels, light/dark mode, and Dynamic Type-friendly controls.
3. Demo mode includes service catalog, service detail charts, incident workflow, runbooks, reliability lab simulations, reset, and Markdown post-incident export.
4. Live mode includes documented REST contract, configurable base URL, Keychain token storage, and typed network errors.
5. Scripts provide repeatable build, test, launch, and screenshot commands with clear Xcode failure output.
6. Documentation is recruiter-ready and truthful about local verification and remaining Xcode/simulator blockers.
7. Repository can be initialized, committed, pushed to GitHub, and linked from the local portfolio site when auth permits.

## Implementation Steps
1. Scaffold repo, package, app source layout, scripts, docs, and Xcode project generator.
   - Verify: `swift package describe` succeeds.
2. Implement domain models, SLO/error-budget calculations, incident transitions, fixtures, demo repository, live API client, and report generation.
   - Verify: focused `swift test` passes for core logic.
3. Implement SwiftUI app shell and feature screens.
   - Verify: source generation succeeds; Xcode build script reaches the expected Xcode availability check.
4. Add runbooks, Reliability Lab, Keychain, persistence, local notification hooks, App Intents, widget source, and deep links.
   - Verify: code is wired into app source and documented.
5. Add unit tests, CI template, README, API/security/testing/portfolio docs, license, changelog, and portfolio-site update.
   - Verify: `swift test`, script checks, git status, and publish readiness checks.
6. Publish to GitHub if possible.
   - Verify: local `HEAD`, `origin/main`, and `git ls-remote origin refs/heads/main` match.

## Known Tooling Constraint
`xcodebuild` currently reports that the active developer directory is Command Line Tools, not Xcode. Full simulator validation, UI tests, widget build, App Intents build, and screenshots require installing/selecting Xcode.
