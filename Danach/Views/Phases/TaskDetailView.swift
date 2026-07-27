import SwiftUI
import SwiftData

/// Alles zu einer Aufgabe: was, warum, welche Unterlagen, an wen, bis wann.
struct TaskDetailView: View {

    let taskID: String
    @Bindable var profile: Profile

    @Environment(\.modelContext) private var modelContext
    @Query private var taskStates: [TaskState]
    @FocusState private var noteFocused: Bool

    @State private var noteDraft: String = ""
    @State private var didLoadNote = false

    private var definition: TaskDefinition? { ContentStore.shared.task(id: taskID) }

    private var state: TaskState? { taskStates.first { $0.taskID == taskID } }

    private var dueDate: Date? {
        guard let definition else { return nil }
        return DeadlineEngine.dueDate(for: definition,
                                      profile: profile.snapshot,
                                      override: state?.customDueDate)
    }

    var body: some View {
        Group {
            if let definition {
                content(definition)
            } else {
                ContentUnavailableView("Aufgabe nicht gefunden",
                                       systemImage: "questionmark.folder")
            }
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") { noteFocused = false }
            }
        }
        .onDisappear(perform: saveNote)
    }

    private func content(_ definition: TaskDefinition) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                title(definition)

                if definition.deadline != nil {
                    DeadlineBadge(spec: definition.deadline,
                                  dueDate: dueDate,
                                  style: .detailed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                statusPicker

                section("Darum geht es") {
                    Text(definition.details)
                        .font(.body)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                if !definition.documents.isEmpty {
                    section("Das brauchen Sie dafür") {
                        bulletList(definition.documents, symbol: "doc")
                    }
                }

                if !definition.contacts.isEmpty {
                    section("Da wenden Sie sich hin") {
                        bulletList(definition.contacts, symbol: "person")
                    }
                }

                if !definition.tips.isEmpty {
                    section("Gut zu wissen") {
                        bulletList(definition.tips, symbol: "lightbulb")
                    }
                }

                noteEditor

                Text("Allgemeine Orientierung, keine Rechtsberatung.")
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Spacing.m)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
            .readableWidth()
        }
        .onAppear {
            guard !didLoadNote else { return }
            noteDraft = state?.note ?? ""
            didLoadNote = true
        }
    }

    // MARK: - Bausteine

    private func title(_ definition: TaskDefinition) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(definition.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(definition.summary)
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeading(text: "Stand")
            Picker("Stand", selection: Binding(
                get: { state?.status ?? .open },
                set: { setStatus($0) }
            )) {
                ForEach(TaskStatus.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: Layout.minTapTarget)
        }
    }

    private func section<Content: View>(_ heading: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeading(text: heading)
            content()
                .cardStyle()
        }
    }

    private func bulletList(_ items: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                    Image(systemName: symbol)
                        .font(.footnote)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 18)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(.body)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeading(text: "Ihre Notiz")
            TextEditor(text: $noteDraft)
                .focused($noteFocused)
                .font(.body)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .stroke(Palette.separator, lineWidth: 1)
                )
                .accessibilityLabel("Notiz zu dieser Aufgabe")

            Text("Zum Beispiel Ansprechpartner, Aktenzeichen oder was noch fehlt.")
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
    }

    // MARK: - Änderungen

    @MainActor
    private func setStatus(_ status: TaskStatus) {
        let state = TaskStateAccess.state(for: taskID, in: taskStates, context: modelContext)
        state.status = status
        try? modelContext.save()
        if status != .open {
            NotificationService.shared.cancel(taskID: taskID)
        }
    }

    private func saveNote() {
        let trimmed = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != (state?.note ?? "") else { return }
        let state = TaskStateAccess.state(for: taskID, in: taskStates, context: modelContext)
        state.note = trimmed
        state.updatedAt = Date()
        try? modelContext.save()
    }
}
