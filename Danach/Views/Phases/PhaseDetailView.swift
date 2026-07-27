import SwiftUI
import SwiftData

/// Die Aufgabenliste einer Phase.
struct PhaseDetailView: View {

    let phase: Phase
    @Bindable var profile: Profile

    @Environment(\.modelContext) private var modelContext
    @Query private var taskStates: [TaskState]

    private var states: [String: TaskState] { Checklist.stateMap(taskStates) }

    private var entries: [ChecklistEntry] {
        Checklist.entries(for: phase,
                          profile: profile.snapshot,
                          states: states,
                          hideNotRelevant: profile.hideNotRelevant)
    }

    private var progress: PhaseProgress {
        Checklist.progress(for: phase, profile: profile.snapshot, states: states)
    }

    private var hiddenCount: Int {
        guard profile.hideNotRelevant else { return 0 }
        return ContentStore.shared.tasks(in: phase, for: profile.snapshot)
            .filter { states[$0.id]?.status == .notRelevant }
            .count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(phase.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ProgressBar(progress: progress)
                }
                .cardStyle()

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .top, spacing: Spacing.s) {
                            TaskCheckButton(status: entry.status,
                                            title: entry.definition.title) {
                                toggle(entry)
                            }

                            NavigationLink {
                                TaskDetailView(taskID: entry.definition.id, profile: profile)
                            } label: {
                                TaskRowContent(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }

                        if index < entries.count - 1 {
                            Divider()
                                .background(Palette.separator)
                                .padding(.leading, Layout.minTapTarget + Spacing.m)
                        }
                    }
                }
                .cardStyle()

                if hiddenCount > 0 {
                    Button {
                        profile.hideNotRelevant = false
                    } label: {
                        Text(hiddenCount == 1
                             ? "Eine als nicht relevant markierte Aufgabe anzeigen"
                             : "\(hiddenCount) als nicht relevant markierte Aufgaben anzeigen")
                            .font(.subheadline)
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity, minHeight: Layout.minTapTarget)
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
            .readableWidth()
        }
        .background(Palette.background)
        .navigationTitle(phase.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Nicht relevante ausblenden", isOn: $profile.hideNotRelevant)
                } label: {
                    Label("Ansicht", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }

    @MainActor
    private func toggle(_ entry: ChecklistEntry) {
        let state = TaskStateAccess.state(for: entry.definition.id,
                                          in: taskStates,
                                          context: modelContext)
        state.status = state.status == .done ? .open : .done
        try? modelContext.save()

        if state.status == .done {
            NotificationService.shared.cancel(taskID: entry.definition.id)
        }
    }
}

/// Holt einen Zustand oder legt ihn an. Zustände entstehen erst, wenn der
/// Nutzer etwas tut – eine frische Installation hat eine leere Datenbank.
enum TaskStateAccess {
    static func state(for taskID: String,
                      in states: [TaskState],
                      context: ModelContext) -> TaskState {
        if let existing = states.first(where: { $0.taskID == taskID }) { return existing }
        let created = TaskState(taskID: taskID)
        context.insert(created)
        return created
    }

    static func documentState(for documentID: String,
                              in states: [DocumentState],
                              context: ModelContext) -> DocumentState {
        if let existing = states.first(where: { $0.documentID == documentID }) { return existing }
        let created = DocumentState(documentID: documentID)
        context.insert(created)
        return created
    }
}
