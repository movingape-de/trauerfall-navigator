import SwiftUI
import SwiftData

/// Einstieg in die Checkliste: die vier Phasen als ruhige Karten.
struct PhaseOverviewView: View {

    @Bindable var profile: Profile
    @EnvironmentObject private var purchases: PurchaseManager
    @Query private var taskStates: [TaskState]

    @State private var showsPaywall = false

    private var states: [String: TaskState] { Checklist.stateMap(taskStates) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    header

                    ForEach(Phase.allCases) { phase in
                        phaseCard(phase)
                    }

                    if !purchases.isUnlocked {
                        upgradeHint
                    }

                    footerNote
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.l)
                .readableWidth()
            }
            .background(Palette.background)
            .navigationTitle("Aufgaben")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showsPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Bausteine

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(dayText)
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
            Text("Sie müssen nicht alles heute schaffen.")
                .font(.title3)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.s)
    }

    private var dayText: String {
        let days = DeadlineEngine.daysBetween(profile.dateOfDeath, Date())
        switch days {
        case ..<0: return "Sterbedatum liegt in der Zukunft"
        case 0: return "Heute"
        case 1: return "Ein Tag danach"
        case 2...13: return "\(days) Tage danach"
        case 14...59: return "Etwa \(days / 7) Wochen danach"
        default: return "Etwa \(days / 30) Monate danach"
        }
    }

    private func phaseCard(_ phase: Phase) -> some View {
        let progress = Checklist.progress(for: phase, profile: profile.snapshot, states: states)
        let locked = !phase.isFree && !purchases.isUnlocked

        return Group {
            if locked {
                Button { showsPaywall = true } label: {
                    phaseCardContent(phase, progress: progress, locked: true)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Teil der Vollversion. Öffnet die Kaufinformationen.")
            } else {
                NavigationLink {
                    PhaseDetailView(phase: phase, profile: profile)
                } label: {
                    phaseCardContent(phase, progress: progress, locked: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func phaseCardContent(_ phase: Phase,
                                  progress: PhaseProgress,
                                  locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .top, spacing: Spacing.m) {
                Image(systemName: locked ? "lock" : phase.symbolName)
                    .font(.title3)
                    .foregroundStyle(locked ? Palette.textSecondary : Palette.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(phase.title)
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(phase.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
            }

            if locked {
                Text("In der Vollversion enthalten")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ProgressBar(progress: progress)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var upgradeHint: some View {
        Button { showsPaywall = true } label: {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Die erste Phase ist dauerhaft kostenlos.")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                Text("Die übrigen Phasen, die Unterlagen-Liste und die Erinnerungen schalten Sie einmalig für \(purchases.displayPrice) frei. Kein Abonnement.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle(Palette.accentSurface)
        }
        .buttonStyle(.plain)
    }

    private var footerNote: some View {
        Text("Diese App ersetzt keine Rechtsberatung.")
            .font(.footnote)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, Spacing.m)
    }
}
