import Foundation
import UserNotifications

/// Lokale Erinnerungen an Fristen. Es werden ausschließlich Benachrichtigungen
/// auf dem Gerät erzeugt – keine Push-Nachrichten, kein Server.
@MainActor
final class NotificationService {

    static let shared = NotificationService()

    /// Vorlaufzeiten in Tagen.
    static let leadTimes = [7, 2]

    /// Uhrzeit der Erinnerung. Vormittags, damit noch Zeit zum Handeln bleibt.
    private static let hour = 9
    private static let minute = 30

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Berechtigung

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Planen

    /// Entfernt alle bisherigen Erinnerungen und plant sie neu.
    ///
    /// Wird nach jeder Änderung aufgerufen, die Fristen beeinflusst:
    /// Statuswechsel, geändertes Sterbedatum, angepasste Frist, Kauf.
    func reschedule(entries: [ChecklistEntry], enabled: Bool) async {
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }
        guard await authorizationStatus() == .authorized else { return }

        let now = Date()
        for entry in entries {
            guard entry.status == .open,
                  let due = entry.dueDate,
                  let spec = entry.definition.deadline,
                  !DeadlineEngine.isImmediate(spec) else { continue }

            for lead in Self.leadTimes {
                guard let fireDate = reminderDate(before: due, days: lead), fireDate > now else {
                    continue
                }
                await add(entry: entry, due: due, fireDate: fireDate, lead: lead)
            }
        }
    }

    func cancel(taskID: String) {
        let ids = Self.leadTimes.map { identifier(taskID: taskID, lead: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    // MARK: - Innerei

    private func add(entry: ChecklistEntry, due: Date, fireDate: Date, lead: Int) async {
        let content = UNMutableNotificationContent()
        content.title = entry.definition.title
        content.body = body(forLead: lead, due: due)
        content.sound = .default
        content.interruptionLevel = .passive
        content.userInfo = ["taskID": entry.definition.id]

        let components = GermanCalendar.calendar.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier(taskID: entry.definition.id, lead: lead),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Bewusst zurückhaltend formuliert. Keine Ausrufezeichen, kein Druck.
    private func body(forLead lead: Int, due: Date) -> String {
        let date = DeadlineEngine.dateFormatter.string(from: due)
        switch lead {
        case 7:
            return "Diese Frist läuft in einer Woche ab, am \(date). Wenn es Ihnen möglich ist, planen Sie es in den nächsten Tagen ein."
        case 2:
            return "Noch zwei Tage bis zum \(date). Falls die Aufgabe schon erledigt ist, haken Sie sie gern in der App ab."
        default:
            return "Die Frist endet am \(date)."
        }
    }

    private func reminderDate(before due: Date, days: Int) -> Date? {
        let calendar = GermanCalendar.calendar
        guard let shifted = calendar.date(byAdding: .day, value: -days, to: due) else { return nil }
        return calendar.date(bySettingHour: Self.hour, minute: Self.minute, second: 0, of: shifted)
    }

    private func identifier(taskID: String, lead: Int) -> String {
        "frist-\(taskID)-\(lead)"
    }
}
