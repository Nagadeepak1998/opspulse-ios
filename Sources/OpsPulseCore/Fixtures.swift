import Foundation

public enum DemoFixtures {
    public static func snapshot() -> OpsPulseSnapshot {
        let runbooks = self.runbooks()
        let incidents = self.incidents()
        return OpsPulseSnapshot(
            services: services(incidents: incidents),
            incidents: incidents,
            runbooks: runbooks
        )
    }

    public static func runbooks() -> [Runbook] {
        [
            Runbook(
                id: "runbook-api-latency",
                title: "High API latency",
                owner: "Edge Platform",
                lastReviewed: DemoClock.minutes(-2_000),
                steps: [
                    step(1, "Confirm customer impact", "Review latency, error rate, and affected routes before changing traffic.", "kubectl get deploy -n edge # read-only"),
                    step(2, "Inspect recent deployments", "Compare the latency spike with the latest gateway release.", "kubectl rollout history deployment/api-gateway -n edge # read-only"),
                    step(3, "Shift traffic safely", "If approved, route a small percentage away from the affected region using the traffic manager."),
                    step(4, "Validate recovery", "Confirm P95 latency and error rate return below SLO thresholds.")
                ]
            ),
            Runbook(
                id: "runbook-db-connections",
                title: "Database connection exhaustion",
                owner: "Data Reliability",
                lastReviewed: DemoClock.minutes(-1_440),
                steps: [
                    step(1, "Confirm saturation", "Check active connections and queue depth using read-only dashboards."),
                    step(2, "Identify noisy clients", "Compare connection spikes by service and deployment version."),
                    step(3, "Reduce pressure", "Scale connection pool limits only after change approval."),
                    step(4, "Watch recovery", "Confirm connection usage and query latency stabilize.")
                ]
            ),
            Runbook(
                id: "runbook-auth-failures",
                title: "Elevated authentication failures",
                owner: "Identity",
                lastReviewed: DemoClock.minutes(-1_100),
                steps: [
                    step(1, "Validate failure source", "Separate expected invalid-login traffic from service-side failures."),
                    step(2, "Check token issuer health", "Review issuer latency and dependency errors."),
                    step(3, "Communicate impact", "Post a concise update for support and customer-facing teams."),
                    step(4, "Confirm sign-in recovery", "Verify successful login rate returns to the normal baseline.")
                ]
            ),
            Runbook(
                id: "runbook-rollback",
                title: "Failed deployment rollback",
                owner: "Release Engineering",
                lastReviewed: DemoClock.minutes(-800),
                steps: [
                    step(1, "Freeze rollout", "Pause progressive delivery while the incident commander reviews evidence."),
                    step(2, "Compare release health", "Review deploy-time metrics and alerts against the previous version."),
                    step(3, "Prepare rollback", "Document rollback target and approval before touching traffic."),
                    step(4, "Verify rollback", "Confirm errors, latency, and saturation recover after rollback completes.")
                ]
            ),
            Runbook(
                id: "runbook-payments",
                title: "Payment-processing errors",
                owner: "Payments Reliability",
                lastReviewed: DemoClock.minutes(-600),
                steps: [
                    step(1, "Measure failure mode", "Separate authorization, capture, timeout, and provider errors."),
                    step(2, "Check provider status", "Review payment provider status pages and synthetic checks."),
                    step(3, "Protect customers", "Enable safe retry guidance and support messaging."),
                    step(4, "Reconcile transactions", "Confirm delayed or duplicate transactions are queued for review.")
                ]
            )
        ]
    }

    public static func incidents() -> [Incident] {
        [
            Incident(
                id: "INC-2025-0007",
                title: "Checkout latency above P95 threshold",
                severity: .p2,
                affectedServiceIDs: ["api-gateway", "orders-service"],
                status: .investigating,
                commander: "Avery Chen",
                startedAt: DemoClock.minutes(-74),
                acknowledgedAt: DemoClock.minutes(-68),
                mitigatedAt: nil,
                resolvedAt: nil,
                customerImpact: "Some customers see delayed checkout confirmation after submitting orders.",
                timeline: [
                    TimelineEvent(id: "tl-1", timestamp: DemoClock.minutes(-74), author: "Alertmanager", message: "P95 checkout latency exceeded 1.2s for 10 minutes."),
                    TimelineEvent(id: "tl-2", timestamp: DemoClock.minutes(-68), author: "Avery Chen", message: "Acknowledged and started gateway trace review."),
                    TimelineEvent(id: "tl-3", timestamp: DemoClock.minutes(-56), author: "OpsPulse", message: "Orders Service shows normal error rate; API Gateway queueing elevated.")
                ],
                runbookID: "runbook-api-latency",
                relatedDeploymentID: "deploy-api-2025-0101",
                contributingFactors: ["Gateway autoscaling lagged behind traffic spike."],
                wentWell: ["Alert fired before total checkout failure."],
                improvements: ["Add a synthetic checkout probe per region."],
                followUpActions: ["Tune gateway scale-out threshold."]
            ),
            Incident(
                id: "INC-2025-0005",
                title: "Authentication retries elevated after token cache miss",
                severity: .p3,
                affectedServiceIDs: ["auth-service"],
                status: .resolved,
                commander: "Mina Patel",
                startedAt: DemoClock.minutes(-420),
                acknowledgedAt: DemoClock.minutes(-414),
                mitigatedAt: DemoClock.minutes(-395),
                resolvedAt: DemoClock.minutes(-381),
                customerImpact: "A small percentage of login attempts required retry.",
                timeline: [
                    TimelineEvent(id: "tl-4", timestamp: DemoClock.minutes(-420), author: "Alertmanager", message: "Login failure rate exceeded baseline."),
                    TimelineEvent(id: "tl-5", timestamp: DemoClock.minutes(-414), author: "Mina Patel", message: "Acknowledged; token cache metrics show high miss rate."),
                    TimelineEvent(id: "tl-6", timestamp: DemoClock.minutes(-381), author: "Mina Patel", message: "Cache warmup completed and error rate returned to baseline.")
                ],
                runbookID: "runbook-auth-failures",
                relatedDeploymentID: "deploy-auth-2025-0101",
                contributingFactors: ["Cache warmup did not include the newest tenant partition."],
                wentWell: ["Runbook narrowed the issue to cache health quickly."],
                improvements: ["Add tenant-aware cache warmup validation."],
                followUpActions: ["Create pre-deploy cache coverage check."]
            )
        ]
    }

    public static func services(incidents: [Incident] = incidents()) -> [OpsService] {
        [
            service(
                id: "api-gateway",
                name: "API Gateway",
                owner: "Edge Platform",
                environment: .production,
                status: .degraded,
                slo: 99.9,
                availability: 99.86,
                errorRate: 0.08,
                p50: 122,
                p95: 920,
                p99: 1_480,
                saturation: 71,
                runbookIDs: ["runbook-api-latency", "runbook-rollback"],
                incidents: incidents,
                version: "2025.01.01+edge.17"
            ),
            service(
                id: "auth-service",
                name: "Authentication Service",
                owner: "Identity",
                environment: .production,
                status: .healthy,
                slo: 99.95,
                availability: 99.97,
                errorRate: 0.018,
                p50: 88,
                p95: 240,
                p99: 510,
                saturation: 44,
                runbookIDs: ["runbook-auth-failures"],
                incidents: incidents,
                version: "2025.01.01+auth.09"
            ),
            service(
                id: "payments-service",
                name: "Payments Service",
                owner: "Payments Reliability",
                environment: .production,
                status: .healthy,
                slo: 99.9,
                availability: 99.94,
                errorRate: 0.04,
                p50: 210,
                p95: 610,
                p99: 1_100,
                saturation: 53,
                runbookIDs: ["runbook-payments", "runbook-rollback"],
                incidents: incidents,
                version: "2025.01.01+pay.11"
            ),
            service(
                id: "orders-service",
                name: "Orders Service",
                owner: "Commerce Platform",
                environment: .production,
                status: .degraded,
                slo: 99.9,
                availability: 99.88,
                errorRate: 0.05,
                p50: 145,
                p95: 740,
                p99: 1_260,
                saturation: 67,
                runbookIDs: ["runbook-api-latency", "runbook-rollback"],
                incidents: incidents,
                version: "2025.01.01+orders.22"
            ),
            service(
                id: "notification-service",
                name: "Notification Service",
                owner: "Messaging",
                environment: .staging,
                status: .healthy,
                slo: 99.5,
                availability: 99.72,
                errorRate: 0.12,
                p50: 180,
                p95: 460,
                p99: 780,
                saturation: 38,
                runbookIDs: ["runbook-rollback"],
                incidents: incidents,
                version: "2025.01.01+notify.04"
            ),
            service(
                id: "postgres-cluster",
                name: "PostgreSQL Cluster",
                owner: "Data Reliability",
                environment: .production,
                status: .healthy,
                slo: 99.95,
                availability: 99.98,
                errorRate: 0.011,
                p50: 34,
                p95: 120,
                p99: 250,
                saturation: 58,
                runbookIDs: ["runbook-db-connections"],
                incidents: incidents,
                version: "2025.01.01+pg.06"
            )
        ]
    }

    private static func service(
        id: String,
        name: String,
        owner: String,
        environment: ServiceEnvironment,
        status: ServiceStatus,
        slo: Double,
        availability: Double,
        errorRate: Double,
        p50: Double,
        p95: Double,
        p99: Double,
        saturation: Double,
        runbookIDs: [String],
        incidents: [Incident],
        version: String
    ) -> OpsService {
        let deployment = Deployment(
            id: "deploy-\(id)-2025-0101",
            version: version,
            environment: environment,
            deployedAt: DemoClock.minutes(-180),
            status: "Succeeded",
            summary: "Progressive release completed with automated smoke checks."
        )
        let openIncidentIDs = incidents
            .filter { $0.status != .resolved && $0.affectedServiceIDs.contains(id) }
            .map(\.id)

        return OpsService(
            id: id,
            name: name,
            owner: owner,
            environment: environment,
            status: status,
            availabilitySLO: slo,
            currentAvailability: availability,
            errorRate: errorRate,
            p50Latency: p50,
            p95Latency: p95,
            p99Latency: p99,
            saturation: saturation,
            recentDeployment: deployment,
            openIncidentIDs: openIncidentIDs,
            runbookIDs: runbookIDs,
            availabilityHistory: history(base: availability, variance: 0.05, floor: slo - 0.12),
            errorRateHistory: history(base: errorRate, variance: 0.025, floor: 0.002),
            latencyP95History: history(base: p95, variance: 90, floor: 80),
            errorBudgetHistory: history(base: SLOCalculator.snapshotPlaceholder(slo: slo, availability: availability), variance: 0.07, floor: 0),
            ownerContact: TeamContact(
                team: owner,
                slackChannel: "#\(owner.lowercased().replacingOccurrences(of: " ", with: "-"))",
                escalationPolicy: "\(owner) primary on-call",
                primaryOnCall: owner == "Edge Platform" ? "Avery Chen" : "Mina Patel"
            )
        )
    }

    private static func step(_ order: Int, _ title: String, _ detail: String, _ safeCommand: String? = nil) -> RunbookStep {
        RunbookStep(id: "step-\(order)-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))", order: order, title: title, detail: detail, safeCommand: safeCommand)
    }

    private static func history(base: Double, variance: Double, floor: Double) -> [MetricPoint] {
        (0..<14).map { index in
            let offset = Double((index % 5) - 2) * variance
            return MetricPoint(id: "point-\(index)", timestamp: DemoClock.minutes(-((13 - index) * 30)), value: max(floor, base + offset).rounded(toPlaces: 3))
        }
    }
}

private extension SLOCalculator {
    static func snapshotPlaceholder(slo: Double, availability: Double) -> Double {
        let permitted = permittedFailurePercentage(sloTarget: slo)
        guard permitted > 0 else { return 0 }
        return remainingBudgetPercentagePoints(sloTarget: slo, currentAvailability: availability) / permitted
    }
}
