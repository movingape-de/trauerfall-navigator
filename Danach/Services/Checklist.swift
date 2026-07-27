import Foundation

/// Eine Aufgabe, wie sie in der Oberfläche erscheint: Inhalt aus dem JSON,
/// Zustand aus SwiftData, Frist aus der Fristen-Engine.
struct ChecklistEntry: Identifiable {
    let definition: TaskDefinition
    let state: TaskState?
    let dueDate: Date?

    var id: String { definition.id }
    var status: TaskStatus { state?.status ?? .open }
    var note: String { state?.note ?? "" }
    var hasNote: Bool { !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var urgency: Urgency? {
        guard let dueDate, status == .open else { return nil }
        return DeadlineEngine.urgency(due: dueDate)
    }
}

/// Fortschritt einer Phase. Nicht relevante Aufgaben zählen nicht mit.
struct PhaseProgress {
    let done: Int
    let total: Int

    var fraction: Double { total > 0 ? Double(done) / Double(total) : 0 }
    var isComplete: Bool { total > 0 && done == total }
    var text: String { "\(done) von \(total) erledigt" }
}

enum Checklist {

    /// Baut die sichtbaren Einträge einer Phase.
    static func entries(for phase: Phase,
                        profile: ProfileSnapshot,
                        states: [String: TaskState],
                        hideNotRelevant: Bool,
                        content: ContentStore = .shared) -> [ChecklistEntry] {
        content.tasks(in: phase, for: profile)
            .map { definition in
                let state = states[definition.id]
                return ChecklistEntry(
                    definition: definition,
                    state: state,
                    dueDate: DeadlineEngine.dueDate(for: definition,
                                                    profile: profile,
                                                    override: state?.customDueDate)
                )
            }
            .filter { entry in
                !(hideNotRelevant && entry.status == .notRelevant)
            }
    }

    /// Alle Einträge mit Frist, sortiert nach Dringlichkeit.
    /// Erledigte und als nicht relevant markierte Aufgaben fallen heraus.
    static func deadlineEntries(profile: ProfileSnapshot,
                                states: [String: TaskState],
                                content: ContentStore = .shared) -> [ChecklistEntry] {
        content.tasks(for: profile)
            .compactMap { definition -> ChecklistEntry? in
                guard definition.deadline != nil else { return nil }
                let state = states[definition.id]
                let status = state?.status ?? .open
                guard status == .open else { return nil }
                guard let due = DeadlineEngine.dueDate(for: definition,
                                                       profile: profile,
                                                       override: state?.customDueDate) else {
                    return nil
                }
                return ChecklistEntry(definition: definition, state: state, dueDate: due)
            }
            .sorted { lhs, rhs in
                guard let l = lhs.dueDate, let r = rhs.dueDate else { return false }
                if l != r { return l < r }
                return lhs.definition.priority < rhs.definition.priority
            }
    }

    static func progress(for phase: Phase,
                         profile: ProfileSnapshot,
                         states: [String: TaskState],
                         content: ContentStore = .shared) -> PhaseProgress {
        let relevant = content.tasks(in: phase, for: profile)
            .filter { (states[$0.id]?.status ?? .open) != .notRelevant }
        let done = relevant.filter { states[$0.id]?.status == .done }.count
        return PhaseProgress(done: done, total: relevant.count)
    }

    /// Bequemer Zugriff: Zustände als Wörterbuch.
    static func stateMap(_ states: [TaskState]) -> [String: TaskState] {
        Dictionary(states.map { ($0.taskID, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
