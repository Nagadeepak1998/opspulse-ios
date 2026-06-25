# Architecture

OpsPulse separates SRE domain behavior from SwiftUI presentation.

## Layers

- `Sources/OpsPulseCore`: domain models, SLO calculations, incident workflow rules, deterministic fixtures, demo repository, live HTTP API adapter, report generation, and file snapshot persistence.
- `OpsPulse/App`: root app, tabs, routing, and `OpsStore`.
- `OpsPulse/Features`: overview, service catalog/detail, incidents, runbooks, Reliability Lab, and settings.
- `OpsPulse/Platform`: Keychain token storage, local notifications, App Intents, and snapshot persistence wiring.
- `OpsPulseWidget`: WidgetKit source with deep links into the app.

## State

`OpsStore` is an `@Observable` root store. It owns the current `OpsPulseSnapshot`, selected tab, navigation paths, demo/live settings, and user-facing errors. Views read from the store and call small async methods; they do not calculate SLOs or mutate incidents directly.

## Dependency Injection

`OpsRepository` is protocol-based. The app defaults to `DemoOpsRepository`; live API behavior is isolated in `HTTPOpsAPI`.

## Domain Rules

- `SLOCalculator` derives permitted failure, consumed budget, remaining budget, burn rate, and classification from service metrics.
- `IncidentWorkflow` enforces valid transitions and sets acknowledgment, mitigation, and resolution timestamps.
- `PostIncidentReport` generates Markdown from the incident, services, runbook, and timing data.

## Persistence

The MVP uses `FileSnapshotStore` to persist the current demo snapshot. This keeps offline state deterministic and easy to reset. SwiftData can be added later if richer local editing history becomes necessary.

## Project Generation

`tools/generate_xcode_project.py` scans source files and regenerates `OpsPulse.xcodeproj` plus the shared scheme. This avoids manual project-file drift while keeping the build process dependency-free.
