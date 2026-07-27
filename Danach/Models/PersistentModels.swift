import Foundation
import SwiftData

/// Die Angaben aus dem Onboarding. Es gibt genau einen Datensatz.
@Model
final class Profile {
    var dateOfDeath: Date
    /// Rohwerte, damit spätere Content-Erweiterungen die Datenbank nicht brechen.
    var placeOfDeathRaw: String
    var relationshipRaw: String
    var hasWillRaw: String
    var hasFuneralProvisionRaw: String

    var onboardingCompleted: Bool
    var disclaimerAcknowledgedAt: Date?
    var remindersEnabled: Bool
    var hideNotRelevant: Bool
    var createdAt: Date

    init(dateOfDeath: Date = Date(),
         placeOfDeath: PlaceOfDeath = .hospital,
         relationship: Relationship = .other,
         hasWill: TriState = .unknown,
         hasFuneralProvision: TriState = .unknown,
         onboardingCompleted: Bool = false) {
        self.dateOfDeath = dateOfDeath
        self.placeOfDeathRaw = placeOfDeath.rawValue
        self.relationshipRaw = relationship.rawValue
        self.hasWillRaw = hasWill.rawValue
        self.hasFuneralProvisionRaw = hasFuneralProvision.rawValue
        self.onboardingCompleted = onboardingCompleted
        self.disclaimerAcknowledgedAt = nil
        self.remindersEnabled = false
        self.hideNotRelevant = true
        self.createdAt = Date()
    }

    var placeOfDeath: PlaceOfDeath {
        get { PlaceOfDeath(rawValue: placeOfDeathRaw) ?? .elsewhere }
        set { placeOfDeathRaw = newValue.rawValue }
    }

    var relationship: Relationship {
        get { Relationship(rawValue: relationshipRaw) ?? .other }
        set { relationshipRaw = newValue.rawValue }
    }

    var hasWill: TriState {
        get { TriState(rawValue: hasWillRaw) ?? .unknown }
        set { hasWillRaw = newValue.rawValue }
    }

    var hasFuneralProvision: TriState {
        get { TriState(rawValue: hasFuneralProvisionRaw) ?? .unknown }
        set { hasFuneralProvisionRaw = newValue.rawValue }
    }

    var snapshot: ProfileSnapshot {
        ProfileSnapshot(dateOfDeath: dateOfDeath,
                        placeOfDeath: placeOfDeath,
                        relationship: relationship,
                        hasWill: hasWill,
                        hasFuneralProvision: hasFuneralProvision)
    }
}

/// Nutzerzustand zu einer Aufgabe aus `tasks_de.json`.
/// Der Inhalt der Aufgabe selbst wird bewusst **nicht** gespeichert – so
/// können Inhalte per App-Update gepflegt werden, ohne Nutzerdaten zu berühren.
@Model
final class TaskState {
    @Attribute(.unique) var taskID: String
    var statusRaw: String
    var note: String
    var completedAt: Date?
    /// Vom Nutzer angepasste Frist, überschreibt die berechnete.
    var customDueDate: Date?
    var updatedAt: Date

    init(taskID: String, status: TaskStatus = .open) {
        self.taskID = taskID
        self.statusRaw = status.rawValue
        self.note = ""
        self.completedAt = nil
        self.customDueDate = nil
        self.updatedAt = Date()
    }

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .open }
        set {
            statusRaw = newValue.rawValue
            completedAt = newValue == .done ? Date() : nil
            updatedAt = Date()
        }
    }
}

/// Nutzerzustand zu einem Dokument aus `documents_de.json`.
@Model
final class DocumentState {
    @Attribute(.unique) var documentID: String
    var isCollected: Bool
    var note: String
    var updatedAt: Date

    init(documentID: String, isCollected: Bool = false) {
        self.documentID = documentID
        self.isCollected = isCollected
        self.note = ""
        self.updatedAt = Date()
    }
}
