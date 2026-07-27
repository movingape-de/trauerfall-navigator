import Foundation
import SwiftUI

/// Wie dringend ist eine Frist?
enum Urgency: Int, Comparable {
    case passed = 0
    case today = 1
    case imminent = 2   // bis 2 Tage
    case soon = 3       // bis 7 Tage
    case upcoming = 4   // bis 30 Tage
    case distant = 5

    static func < (lhs: Urgency, rhs: Urgency) -> Bool { lhs.rawValue < rhs.rawValue }

    var color: Color {
        switch self {
        case .passed, .today: return Palette.alert
        case .imminent, .soon: return Palette.caution
        case .upcoming, .distant: return Palette.textSecondary
        }
    }

    var surface: Color {
        switch self {
        case .passed, .today: return Palette.alertSurface
        case .imminent, .soon: return Palette.cautionSurface
        case .upcoming, .distant: return Palette.surfaceMuted
        }
    }
}

/// Berechnet aus dem Sterbedatum und der Frist-Beschreibung ein konkretes
/// Datum – und die Texte, die dazu angezeigt werden.
enum DeadlineEngine {

    private static var calendar: Calendar { GermanCalendar.calendar }

    /// Fälligkeitszeitpunkt einer Aufgabe.
    /// - Parameter override: vom Nutzer angepasste Frist, hat Vorrang.
    static func dueDate(for spec: DeadlineSpec?,
                        dateOfDeath: Date,
                        override: Date? = nil) -> Date? {
        if let override { return override }
        guard let spec else { return nil }

        switch spec.unit {
        case .hours:
            return calendar.date(byAdding: .hour, value: spec.amount, to: dateOfDeath)
        case .days:
            let day = calendar.date(byAdding: .day, value: spec.amount, to: dateOfDeath) ?? dateOfDeath
            return endOfDay(day)
        case .months:
            let day = calendar.date(byAdding: .month, value: spec.amount, to: dateOfDeath) ?? dateOfDeath
            return endOfDay(day)
        case .businessDays:
            let day = GermanCalendar.addingWorkdays(spec.amount, to: dateOfDeath)
            return endOfDay(day)
        }
    }

    static func dueDate(for task: TaskDefinition,
                        profile: ProfileSnapshot,
                        override: Date? = nil) -> Date? {
        dueDate(for: task.deadline, dateOfDeath: profile.dateOfDeath, override: override)
    }

    /// Fristen mit einer Frist von 0 Stunden bedeuten „sofort“ und bekommen
    /// keinen Countdown.
    static func isImmediate(_ spec: DeadlineSpec?) -> Bool {
        guard let spec else { return false }
        return spec.amount == 0
    }

    static func urgency(due: Date, now: Date = Date()) -> Urgency {
        if due < now { return .passed }
        let days = daysBetween(now, due)
        switch days {
        case ..<1: return .today
        case 1...2: return .imminent
        case 3...7: return .soon
        case 8...30: return .upcoming
        default: return .distant
        }
    }

    /// Ganze Kalendertage zwischen zwei Zeitpunkten.
    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    // MARK: - Texte

    /// Kurzer Countdown, bewusst nüchtern formuliert.
    static func countdownText(due: Date, now: Date = Date()) -> String {
        let days = daysBetween(now, due)
        switch days {
        case ..<(-1):
            return "Frist war vor \(abs(days)) Tagen"
        case -1:
            return "Frist war gestern"
        case 0:
            return due < now ? "Frist heute abgelaufen" : "heute"
        case 1:
            return "morgen"
        case 2...13:
            return "in \(days) Tagen"
        case 14...59:
            let weeks = days / 7
            return "in etwa \(weeks) Wochen"
        default:
            let months = days / 30
            return "in etwa \(months) Monaten"
        }
    }

    /// Vollständiger Satz für VoiceOver.
    static func accessibilityText(label: String, due: Date, now: Date = Date()) -> String {
        let formatted = dateFormatter.string(from: due)
        let days = daysBetween(now, due)
        if days < 0 {
            return "\(label). Die Frist war am \(formatted) und ist verstrichen."
        }
        if days == 0 {
            return "\(label). Die Frist endet heute, am \(formatted)."
        }
        return "\(label). Noch \(days) Tage, bis zum \(formatted)."
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    /// Bei stundengenauen Fristen ist die Uhrzeit relevant.
    static func formatted(_ due: Date, spec: DeadlineSpec?) -> String {
        if spec?.unit == .hours && (spec?.amount ?? 0) > 0 {
            return dateTimeFormatter.string(from: due)
        }
        return dateFormatter.string(from: due)
    }

    private static func endOfDay(_ date: Date) -> Date {
        calendar.date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
    }
}
