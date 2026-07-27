import Foundation

/// Die vier Phasen der Checkliste. Der Rohwert entspricht dem Feld `phase`
/// in `tasks_de.json`.
enum Phase: Int, Codable, CaseIterable, Identifiable, Sendable {
    case firstHours = 1
    case firstDays = 2
    case firstWeeks = 3
    case firstMonths = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .firstHours: return "Die ersten Stunden"
        case .firstDays: return "Die ersten Tage"
        case .firstWeeks: return "Die ersten Wochen"
        case .firstMonths: return "Die ersten Monate"
        }
    }

    var subtitle: String {
        switch self {
        case .firstHours: return "Was jetzt unmittelbar zu tun ist"
        case .firstDays: return "Sterbeurkunde, Bestattung, erste Meldungen"
        case .firstWeeks: return "Verträge, Rente, Konten, Nachlass"
        case .firstMonths: return "Erbschein, Steuern, Auflösung"
        }
    }

    /// Phase 1 ist dauerhaft kostenfrei.
    var isFree: Bool { self == .firstHours }

    var symbolName: String {
        switch self {
        case .firstHours: return "clock"
        case .firstDays: return "calendar"
        case .firstWeeks: return "tray.full"
        case .firstMonths: return "leaf"
        }
    }
}

/// Sterbeort – steuert die ersten Aufgaben.
enum PlaceOfDeath: String, Codable, CaseIterable, Identifiable, Sendable {
    case home
    case hospital
    case careHome = "care_home"
    case elsewhere

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Zuhause"
        case .hospital: return "Im Krankenhaus"
        case .careHome: return "Im Pflegeheim"
        case .elsewhere: return "Andernorts"
        }
    }

    var explanation: String {
        switch self {
        case .home: return "Sie müssen selbst einen Arzt für die Todesbescheinigung rufen."
        case .hospital: return "Das Krankenhaus stellt die Todesbescheinigung aus."
        case .careHome: return "Das Heim organisiert in der Regel die Todesbescheinigung."
        case .elsewhere: return "Zum Beispiel unterwegs, im Ausland oder an einem unbekannten Ort."
        }
    }
}

/// Verhältnis zur verstorbenen Person – steuert Ansprüche und Pflichten.
enum Relationship: String, Codable, CaseIterable, Identifiable, Sendable {
    case spouse
    case partner
    case child
    case parent
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spouse: return "Ehepartner oder eingetragener Lebenspartner"
        case .partner: return "Partner ohne Trauschein"
        case .child: return "Kind"
        case .parent: return "Elternteil"
        case .other: return "Andere Angehörige"
        }
    }

    var explanation: String {
        switch self {
        case .spouse: return "Zum Beispiel für Witwenrente und Mietvertrag wichtig."
        case .partner: return "Ohne Ehe gelten andere Regeln – die App weist darauf hin."
        case .child: return "Zum Beispiel für Waisenrente und Erbfolge wichtig."
        case .parent: return "Zum Beispiel bei einem verstorbenen Kind."
        case .other: return "Geschwister, Enkel, Freunde, Betreuer."
        }
    }
}

/// Antwort auf Ja/Nein/Unbekannt-Fragen im Onboarding.
enum TriState: String, Codable, CaseIterable, Identifiable, Sendable {
    case yes
    case no
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes: return "Ja"
        case .no: return "Nein"
        case .unknown: return "Weiß ich nicht"
        }
    }
}

/// Bearbeitungsstand einer Aufgabe.
enum TaskStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case open
    case done
    case notRelevant = "not_relevant"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .open: return "Offen"
        case .done: return "Erledigt"
        case .notRelevant: return "Nicht relevant"
        }
    }

    var symbolName: String {
        switch self {
        case .open: return "circle"
        case .done: return "checkmark.circle.fill"
        case .notRelevant: return "minus.circle"
        }
    }
}
