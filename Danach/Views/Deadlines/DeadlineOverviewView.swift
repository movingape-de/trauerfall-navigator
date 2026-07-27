import SwiftUI
import SwiftData

/// Alle offenen Fristen, nach Dringlichkeit sortiert.
///
/// Auch ohne Kauf sichtbar – wer eine Frist verpasst, weil sie hinter einer
/// Bezahlschranke lag, würde uns das zu Recht übelnehmen. Ohne Vollversion
/// führt der Weg in die Aufgabe allerdings über den Kaufhinweis.
struct DeadlineOverviewView: View {

    @Bindable var profile: Profile
    @EnvironmentObject private var purchases: PurchaseManager
    @Query private var taskStates: [TaskState]

    @State private var showsPaywall = false

    private var entries: [ChecklistEntry] {
        Checklist.deadlineEntries(profile: profile.snapshot,
                                  states: Checklist.stateMap(taskStates))
    }

    private var groups: [(title: String, entries: [ChecklistEntry])] {
        let now = Date()
        var passed: [ChecklistEntry] = []
        var thisWeek: [ChecklistEntry] = []
        var later: [ChecklistEntry] = []

        for entry in entries {
            guard let due = entry.dueDate else { continue }
            switch DeadlineEngine.urgency(due: due, now: now) {
            case .passed: passed.append(entry)
            case .today, .imminent, .soon: thisWeek.append(entry)
            case .upcoming, .distant: later.append(entry)
            }
        }

        var result: [(String, [ChecklistEntry])] = []
        if !passed.isEmpty { result.append(("Frist verstrichen", passed)) }
        if !thisWeek.isEmpty { result.append(("In den nächsten Tagen", thisWeek)) }
        if !later.isEmpty { result.append(("Später", later)) }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(groups, id: \.title) { group in
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                SectionHeading(text: group.title)
                                VStack(spacing: 0) {
                                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                        row(entry)
                                        if index < group.entries.count - 1 {
                                            Divider().background(Palette.separator)
                                        }
                                    }
                                }
                                .cardStyle()
                            }
                        }
                    }

                    hintCard
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.l)
                .readableWidth()
            }
            .background(Palette.background)
            .navigationTitle("Fristen")
            .sheet(isPresented: $showsPaywall) { PaywallView() }
        }
    }

    // MARK: - Bausteine

    @ViewBuilder
    private func row(_ entry: ChecklistEntry) -> some View {
        let locked = !entry.definition.phase.isFree && !purchases.isUnlocked

        Group {
            if locked {
                Button { showsPaywall = true } label: { rowContent(entry, locked: true) }
                    .buttonStyle(.plain)
            } else {
                NavigationLink {
                    TaskDetailView(taskID: entry.definition.id, profile: profile)
                } label: {
                    rowContent(entry, locked: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func rowContent(_ entry: ChecklistEntry, locked: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.definition.title)
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                DeadlineBadge(spec: entry.definition.deadline, dueDate: entry.dueDate)

                if let due = entry.dueDate, !DeadlineEngine.isImmediate(entry.definition.deadline) {
                    Text(DeadlineEngine.formatted(due, spec: entry.definition.deadline))
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }

                Text(entry.definition.phase.title)
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: locked ? "lock" : "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.s)
        .frame(minHeight: Layout.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Zurzeit steht keine Frist an.")
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
            Text("Entweder sind alle Aufgaben mit Frist erledigt, oder es sind für Ihre Situation keine vorgesehen.")
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Zu den Fristen")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
            Text("Wir rechnen alle Fristen vom Sterbedatum aus. Manche Fristen laufen tatsächlich ab dem Tag, an dem Sie von etwas erfahren haben – dann haben Sie eher mehr Zeit als hier angezeigt. Verlassen Sie sich im Zweifel nicht darauf und fragen Sie nach.")
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle(Palette.surfaceMuted)
    }
}
