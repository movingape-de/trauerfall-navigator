import SwiftUI
import SwiftData

/// Fünf Fragen, dann Hinweis und Erinnerungen. Jeder Schritt lässt sich
/// überspringen oder später in den Einstellungen ändern.
struct OnboardingFlowView: View {

    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: Profile

    @State private var step: Step = .welcome

    enum Step: Int, CaseIterable {
        case welcome, date, place, relationship, will, provision, disclaimer, reminders

        /// Der Begrüßungsschritt und die Abschlussschritte zählen nicht als Frage.
        var questionIndex: Int? {
            switch self {
            case .date: return 1
            case .place: return 2
            case .relationship: return 3
            case .will: return 4
            case .provision: return 5
            default: return nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let index = step.questionIndex {
                    StepIndicator(current: index, total: 5)
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, Spacing.s)
                }

                ScrollView {
                    content
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                        .readableWidth()
                }

                footer
                    .padding(.horizontal, Spacing.l)
                    .padding(.bottom, Spacing.l)
                    .readableWidth()
            }
            .background(Palette.background)
            .toolbar {
                if step != .welcome {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Zurück") { goBack() }
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Inhalte

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            WelcomeStep()
        case .date:
            DateOfDeathStep(date: $profile.dateOfDeath)
        case .place:
            PlaceOfDeathStep(selection: Binding(
                get: { profile.placeOfDeath },
                set: { profile.placeOfDeath = $0 }
            ))
        case .relationship:
            RelationshipStep(selection: Binding(
                get: { profile.relationship },
                set: { profile.relationship = $0 }
            ))
        case .will:
            TriStateStep(
                title: "Gibt es ein Testament oder einen Erbvertrag?",
                explanation: "Falls Sie es nicht wissen, ist das völlig in Ordnung. Wir nehmen dann die Aufgaben mit auf, die beim Suchen helfen.",
                selection: Binding(
                    get: { profile.hasWill },
                    set: { profile.hasWill = $0 }
                )
            )
        case .provision:
            TriStateStep(
                title: "Gibt es eine Bestattungsvorsorge?",
                explanation: "Ein Vorsorgevertrag oder eine Sterbegeldversicherung nimmt Ihnen viele Entscheidungen ab – und spart oft Geld.",
                selection: Binding(
                    get: { profile.hasFuneralProvision },
                    set: { profile.hasFuneralProvision = $0 }
                )
            )
        case .disclaimer:
            DisclaimerStep()
        case .reminders:
            RemindersStep(enabled: $profile.remindersEnabled)
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.m) {
            Button(primaryTitle) { advance() }
                .buttonStyle(CalmButtonStyle())

            if step == .reminders {
                Button("Später entscheiden") {
                    profile.remindersEnabled = false
                    finish()
                }
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
                .frame(minHeight: Layout.minTapTarget)
            }
        }
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: return "Beginnen"
        case .disclaimer: return "Verstanden"
        case .reminders: return "Erinnerungen erlauben"
        default: return "Weiter"
        }
    }

    // MARK: - Ablauf

    private func advance() {
        switch step {
        case .reminders:
            Task {
                let granted = await NotificationService.shared.requestAuthorization()
                profile.remindersEnabled = granted
                finish()
            }
        default:
            if let next = Step(rawValue: step.rawValue + 1) {
                withAnimation(.easeInOut(duration: 0.25)) { step = next }
            }
        }
    }

    private func goBack() {
        if let previous = Step(rawValue: step.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.25)) { step = previous }
        }
    }

    private func finish() {
        profile.disclaimerAcknowledgedAt = Date()
        profile.onboardingCompleted = true
        try? modelContext.save()
    }
}

// MARK: - Fortschrittspunkte

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: Spacing.s) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Palette.accent : Palette.surfaceMuted)
                    .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Frage \(current) von \(total)")
    }
}
