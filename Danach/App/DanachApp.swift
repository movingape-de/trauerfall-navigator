import SwiftUI
import SwiftData

@main
struct DanachApp: App {

    /// Alle Daten bleiben auf dem Gerät. Kein Backend, kein Account,
    /// keine Analyse, keine iCloud-Synchronisierung.
    private let container: ModelContainer = {
        let schema = Schema([Profile.self, TaskState.self, DocumentState.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Datenspeicher konnte nicht geöffnet werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Palette.accent)
        }
        .modelContainer(container)
    }
}
