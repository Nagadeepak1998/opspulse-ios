import Foundation
import UserNotifications

protocol LocalIncidentNotificationScheduling: Sendable {
    func scheduleCriticalIncidentIfNeeded(_ incident: Incident) async
}

struct LocalIncidentNotificationScheduler: LocalIncidentNotificationScheduling {
    func scheduleCriticalIncidentIfNeeded(_ incident: Incident) async {
        guard incident.severity == .p1 else { return }
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "\(incident.severity.displayName) Incident"
            content.body = incident.title
            content.sound = .default
            content.userInfo = ["url": "opspulse://incidents/\(incident.id)"]

            let request = UNNotificationRequest(
                identifier: "incident-\(incident.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            try await center.add(request)
        } catch {
            // Demo notifications are helpful but should never block incident workflow actions.
        }
    }
}
