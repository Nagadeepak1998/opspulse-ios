# Portfolio Notes

## LinkedIn Project Description

Built OpsPulse, a native SwiftUI iOS/iPadOS SRE incident commander app that demonstrates service health monitoring, SLO/error-budget math, burn-rate classification, runbook-driven incident response, deterministic Reliability Lab simulations, and Markdown post-incident review export. The core logic is tested with Swift Testing and the app runs in demo mode without credentials.

## Resume Bullets

- Built a native SwiftUI SRE incident-command app with protocol-based repositories, deterministic fixtures, offline persistence, Keychain token storage, and a URLSession live API adapter.
- Implemented unit-tested SLO and error-budget calculations, burn-rate classification, incident transition rules, MTTA/MTTR timing, simulation behavior, and Markdown post-incident review generation.
- Designed a demo reliability workflow covering service catalog metrics, Swift Charts, runbook checklists, incident commander assignment, valid state transitions, and resettable failure simulations.

## 60-Second Demo Script

1. "OpsPulse is a mobile SRE incident commander app built in SwiftUI."
2. "The overview summarizes production and staging health, active incidents, availability, budget remaining, burn rate, MTTA, MTTR, and the last deployment."
3. "The service catalog shows ownership, status, SLOs, current availability, error rate, latency, saturation, recent deploys, and related incidents."
4. "In the service detail screen, Swift Charts show deterministic metric history so screenshots and tests are repeatable."
5. "The Reliability Lab generates demo-only failures such as API latency spikes or regional outage."
6. "A generated incident can be acknowledged, assigned to a commander, moved through valid states, paired with a runbook checklist, resolved, and exported as Markdown."
7. "The core SLO and incident workflow logic is tested separately from the UI."

## Suggested Screenshots

- Overview showing active P2 and service health counts
- API Gateway detail with SLO panel and charts
- Active generated incident with transition buttons
- Runbook checklist with safe reference command
- Reliability Lab scenario list
- Markdown post-incident review share panel

## Interview Questions And Answers

### How are error budgets calculated?

The app derives permitted failure from `100 - SLO target`, consumed budget from `SLO target - current availability`, remaining budget from permitted minus consumed, and burn rate from current error rate divided by permitted failure.

### How are invalid incident transitions prevented?

`IncidentWorkflow` owns the state machine. Each status exposes valid next states, and the transition function throws a typed error for invalid jumps such as Investigating directly to Resolved.

### Why use protocol-based repositories?

The app can swap deterministic demo data and a live `URLSession` adapter without changing SwiftUI screens. This also keeps tests focused on domain behavior.

### What is simulated versus production-capable?

Simulation data, generated incidents, local notifications, and widget counts are demo-only. The domain logic, URLSession API adapter, typed errors, Keychain token storage, and report generation are production-capable building blocks.

### What would you improve next?

Add app-group-backed widget data, Xcode UI tests, a mock API server, SwiftData history for local edits, and full simulator screenshot automation after full Xcode is available.

## Simulated Functionality

- Demo service metrics
- Reliability Lab incidents
- Local notification events
- Widget counts
- Sample runbook command text

## Production-Capable Functionality

- SLO and error-budget calculations
- Incident workflow validation
- Codable domain models
- URLSession live API adapter
- Keychain token storage
- Markdown report generation
- Protocol-based data-source injection
