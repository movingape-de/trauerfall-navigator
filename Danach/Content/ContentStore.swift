import Foundation

/// Lädt den Aufgaben- und Dokumentenkatalog aus dem App-Bundle.
///
/// Der gesamte Inhalt liegt in `tasks_de.json` und `documents_de.json`.
/// So lassen sich Texte pflegen, ohne Swift-Code anzufassen.
final class ContentStore {

    static let shared = ContentStore()

    let tasks: [TaskDefinition]
    let documents: [DocumentDefinition]
    let contentVersion: Int
    let contentUpdated: String

    private let tasksByID: [String: TaskDefinition]
    private let tasksByPhase: [Phase: [TaskDefinition]]

    private init(bundle: Bundle = .main) {
        let taskCatalog: TaskCatalog = ContentStore.load("tasks_de", from: bundle)
        let documentCatalog: DocumentCatalog = ContentStore.load("documents_de", from: bundle)

        self.tasks = taskCatalog.tasks.sorted { lhs, rhs in
            if lhs.phase.rawValue != rhs.phase.rawValue {
                return lhs.phase.rawValue < rhs.phase.rawValue
            }
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.id < rhs.id
        }
        self.documents = documentCatalog.documents.sorted {
            $0.priority == $1.priority ? $0.id < $1.id : $0.priority < $1.priority
        }
        self.contentVersion = taskCatalog.version
        self.contentUpdated = taskCatalog.updated

        self.tasksByID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        self.tasksByPhase = Dictionary(grouping: tasks, by: \.phase)

        assert(tasksByID.count == tasks.count, "Doppelte Aufgaben-IDs in tasks_de.json")
    }

    /// Nur für Tests und Previews.
    init(tasks: [TaskDefinition], documents: [DocumentDefinition]) {
        self.tasks = tasks
        self.documents = documents
        self.contentVersion = 0
        self.contentUpdated = ""
        self.tasksByID = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        self.tasksByPhase = Dictionary(grouping: tasks, by: \.phase)
    }

    // MARK: - Zugriff

    func task(id: String) -> TaskDefinition? { tasksByID[id] }

    func tasks(in phase: Phase) -> [TaskDefinition] { tasksByPhase[phase] ?? [] }

    /// Alle Aufgaben, die zum Profil passen.
    func tasks(for profile: ProfileSnapshot) -> [TaskDefinition] {
        tasks.filter { $0.conditions?.matches(profile) ?? true }
    }

    func tasks(in phase: Phase, for profile: ProfileSnapshot) -> [TaskDefinition] {
        tasks(in: phase).filter { $0.conditions?.matches(profile) ?? true }
    }

    func documents(for profile: ProfileSnapshot) -> [DocumentDefinition] {
        documents.filter { $0.conditions?.matches(profile) ?? true }
    }

    // MARK: - Laden

    private static func load<T: Decodable>(_ name: String, from bundle: Bundle) -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            fatalError("\(name).json fehlt im App-Bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("\(name).json konnte nicht gelesen werden: \(error)")
        }
    }
}
