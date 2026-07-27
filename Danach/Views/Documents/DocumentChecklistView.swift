import SwiftUI
import SwiftData

/// Welche Unterlagen werden gebraucht, wofür, und in welcher Anzahl.
struct DocumentChecklistView: View {

    @Bindable var profile: Profile
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Query private var documentStates: [DocumentState]

    @State private var showsPaywall = false
    @State private var expanded: Set<String> = []

    private var documents: [DocumentDefinition] {
        ContentStore.shared.documents(for: profile.snapshot)
    }

    private var collectedCount: Int {
        documents.filter { document in
            documentStates.first { $0.documentID == document.id }?.isCollected == true
        }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if purchases.isUnlocked {
                    unlockedContent
                } else {
                    lockedContent
                }
            }
            .background(Palette.background)
            .navigationTitle("Unterlagen")
            .sheet(isPresented: $showsPaywall) { PaywallView().environmentObject(purchases) }
        }
    }

    // MARK: - Freigeschaltet

    private var unlockedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Legen Sie sich eine Mappe an. Fast jede Stelle möchte etwas anderes sehen, und vieles wird im Original einbehalten.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ProgressBar(progress: PhaseProgress(done: collectedCount,
                                                        total: documents.count))
                }
                .cardStyle()

                ForEach(documents) { document in
                    documentCard(document)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
            .readableWidth()
        }
    }

    private func documentCard(_ document: DocumentDefinition) -> some View {
        let state = documentStates.first { $0.documentID == document.id }
        let isCollected = state?.isCollected ?? false
        let isExpanded = expanded.contains(document.id)

        return VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.m) {
                Button {
                    toggle(document)
                } label: {
                    Image(systemName: isCollected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isCollected ? Palette.accent : Palette.textSecondary)
                        .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCollected
                                    ? "\(document.title) als fehlend markieren"
                                    : "\(document.title) als vorhanden markieren")

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let count = document.recommendedCount {
                        Text(count)
                            .font(.subheadline)
                            .foregroundStyle(Palette.accent)
                    }

                    Text(document.purpose)
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Spacing.s)

                Spacer(minLength: 0)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expanded.remove(document.id) } else { expanded.insert(document.id) }
                }
            } label: {
                HStack(spacing: Spacing.s) {
                    Text(isExpanded ? "Weniger anzeigen" : "Wofür und woher?")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.footnote)
                }
                .font(.subheadline)
                .foregroundStyle(Palette.accent)
                .frame(minHeight: Layout.minTapTarget, alignment: .leading)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        SectionHeading(text: "Woher")
                        Text(document.source)
                            .font(.body)
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !document.usedFor.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            SectionHeading(text: "Wird verlangt von")
                            ForEach(document.usedFor, id: \.self) { item in
                                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                                    Text("·").foregroundStyle(Palette.accent)
                                    Text(item)
                                        .font(.body)
                                        .foregroundStyle(Palette.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    DocumentNoteField(documentID: document.id)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .cardStyle()
        .opacity(isCollected ? 0.75 : 1)
    }

    private func toggle(_ document: DocumentDefinition) {
        let state = TaskStateAccess.documentState(for: document.id,
                                                  in: documentStates,
                                                  context: modelContext)
        state.isCollected.toggle()
        state.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Gesperrt

    private var lockedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Image(systemName: "folder")
                        .font(.system(size: 36))
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                    Text("Die Unterlagen-Mappe")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text("Eine abhakbare Liste aller Dokumente, die Sie in den nächsten Wochen brauchen werden – mit der empfohlenen Anzahl, der ausstellenden Stelle und dem Grund. Enthalten in der Vollversion.")
                        .font(.body)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeading(text: "Enthalten sind unter anderem")
                    ForEach(documents.prefix(4)) { document in
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                            Image(systemName: "doc")
                                .font(.footnote)
                                .foregroundStyle(Palette.accent)
                                .accessibilityHidden(true)
                            Text(document.title)
                                .font(.body)
                                .foregroundStyle(Palette.textPrimary)
                        }
                    }
                    Text("und \(max(0, documents.count - 4)) weitere")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                .cardStyle()

                Button("Vollversion ansehen") { showsPaywall = true }
                    .buttonStyle(CalmButtonStyle())
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
            .readableWidth()
        }
    }
}

/// Eigenes Notizfeld je Dokument, damit der Text lokal gehalten wird und
/// nicht bei jedem Tastendruck in die Datenbank geschrieben wird.
private struct DocumentNoteField: View {

    let documentID: String

    @Environment(\.modelContext) private var modelContext
    @Query private var documentStates: [DocumentState]
    @State private var draft: String = ""
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeading(text: "Notiz")
            TextField("Zum Beispiel: liegt im Ordner „Wichtiges“", text: $draft, axis: .vertical)
                .lineLimit(2...5)
                .font(.body)
                .padding(Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .fill(Palette.surfaceMuted)
                )
                .accessibilityLabel("Notiz zu diesem Dokument")
                .onChange(of: draft) { _, newValue in save(newValue) }
        }
        .onAppear {
            guard !loaded else { return }
            draft = documentStates.first { $0.documentID == documentID }?.note ?? ""
            loaded = true
        }
    }

    private func save(_ value: String) {
        guard loaded else { return }
        let state = TaskStateAccess.documentState(for: documentID,
                                                  in: documentStates,
                                                  context: modelContext)
        state.note = value
        state.updatedAt = Date()
    }
}
