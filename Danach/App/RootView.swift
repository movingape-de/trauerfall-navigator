import SwiftUI
import SwiftData

/// Vorläufige Wurzelansicht für Schritt 1 der Entwicklung: zeigt den
/// geladenen Katalog, damit Datenmodell und JSON überprüft werden können.
/// Wird im nächsten Schritt durch Onboarding und Hauptansicht ersetzt.
struct RootView: View {

    private let content = ContentStore.shared
    @State private var profile = ProfileSnapshot.preview

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Aufgaben im Katalog", value: "\(content.tasks.count)")
                    LabeledContent("davon sichtbar", value: "\(content.tasks(for: profile).count)")
                    LabeledContent("Dokumente", value: "\(content.documents.count)")
                    LabeledContent("Content-Version", value: "\(content.contentVersion)")
                } header: {
                    SectionHeading(text: "Katalog")
                }

                ForEach(Phase.allCases) { phase in
                    Section {
                        ForEach(content.tasks(in: phase, for: profile)) { task in
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(task.title).font(.headline)
                                Text(task.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.textSecondary)
                                if let deadline = task.deadline {
                                    Text(deadline.label)
                                        .font(.footnote)
                                        .foregroundStyle(deadline.strict ? Palette.alert : Palette.caution)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    } header: {
                        SectionHeading(text: "\(phase.title) · \(content.tasks(in: phase, for: profile).count)")
                    }
                }
            }
            .navigationTitle("Katalogprüfung")
        }
    }
}

#Preview {
    RootView()
}
