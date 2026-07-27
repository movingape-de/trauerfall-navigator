import SwiftUI

// MARK: - Gemeinsamer Aufbau

/// Überschrift und Erklärung eines Onboarding-Schritts.
struct StepHeader: View {
    let title: String
    var explanation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let explanation {
                Text(explanation)
                    .font(.body)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Große Auswahlkarte. Mindestens 52 pt hoch, Text bricht um.
struct ChoiceCard: View {
    let title: String
    var explanation: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.m) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let explanation {
                        Text(explanation)
                            .font(.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.m)
            .frame(minHeight: Layout.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(isSelected ? Palette.accentSurface : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(isSelected ? Palette.accent : Palette.separator,
                            lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Schritte

struct WelcomeStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: "leaf")
                .font(.system(size: 44))
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)

            Text("Danach")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Es tut uns leid, dass Sie diese App brauchen.")
                .font(.title3)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Nach einem Todesfall gibt es vieles zu regeln, und fast nichts davon ist offensichtlich. Diese App zeigt Ihnen, was zu tun ist – in Ruhe, Schritt für Schritt, in der richtigen Reihenfolge.\n\nWir stellen Ihnen dafür fünf kurze Fragen. Sie können jede Antwort später ändern.\n\nAlles, was Sie eingeben, bleibt auf diesem Gerät.")
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DateOfDeathStep: View {
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            StepHeader(
                title: "Wann ist die Person verstorben?",
                explanation: "Aus diesem Datum berechnen wir alle Fristen. Wenn Sie sich nicht sicher sind, nehmen Sie den Tag, an dem Sie es erfahren haben."
            )

            DatePicker("Sterbedatum",
                       selection: $date,
                       in: ...Date(),
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Palette.accent)
                .padding(Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Palette.surface)
                )
                .environment(\.locale, Locale(identifier: "de_DE"))
        }
    }
}

struct PlaceOfDeathStep: View {
    @Binding var selection: PlaceOfDeath

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            StepHeader(
                title: "Wo ist die Person verstorben?",
                explanation: "Davon hängt ab, wer die Todesbescheinigung ausstellt und was jetzt zuerst zu tun ist."
            )

            VStack(spacing: Spacing.m) {
                ForEach(PlaceOfDeath.allCases) { place in
                    ChoiceCard(title: place.title,
                               explanation: place.explanation,
                               isSelected: selection == place) {
                        selection = place
                    }
                }
            }
        }
    }
}

struct RelationshipStep: View {
    @Binding var selection: Relationship

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            StepHeader(
                title: "In welchem Verhältnis standen Sie zur verstorbenen Person?",
                explanation: "Davon hängen Ansprüche wie Hinterbliebenenrente ab – und Pflichten wie die Anzeige beim Nachlassgericht."
            )

            VStack(spacing: Spacing.m) {
                ForEach(Relationship.allCases) { relationship in
                    ChoiceCard(title: relationship.title,
                               explanation: relationship.explanation,
                               isSelected: selection == relationship) {
                        selection = relationship
                    }
                }
            }
        }
    }
}

struct TriStateStep: View {
    let title: String
    let explanation: String
    @Binding var selection: TriState

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            StepHeader(title: title, explanation: explanation)

            VStack(spacing: Spacing.m) {
                ForEach(TriState.allCases) { value in
                    ChoiceCard(title: value.title,
                               isSelected: selection == value) {
                        selection = value
                    }
                }
            }
        }
    }
}

struct DisclaimerStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            StepHeader(title: "Ein wichtiger Hinweis")

            Text("Diese App gibt allgemeine Orientierung. Sie ersetzt keine Rechts-, Steuer- oder Finanzberatung.\n\nWir haben die Inhalte sorgfältig zusammengestellt, aber jeder Fall ist anders, und Bestattungsrecht ist in jedem Bundesland etwas anders geregelt. Bei Erbschaft, Schulden im Nachlass oder Streit in der Familie wenden Sie sich bitte an einen Anwalt, einen Notar oder eine Verbraucherzentrale.\n\nFristen berechnen wir aus dem Sterbedatum. Prüfen Sie im Einzelfall bitte nach, ob für Sie etwas anderes gilt.")
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: Spacing.m) {
                Image(systemName: "lock")
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)
                Text("Ihre Angaben verlassen dieses Gerät nicht. Es gibt kein Konto, keine Übertragung, keine Auswertung.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle(Palette.accentSurface)
        }
    }
}

struct RemindersStep: View {
    @Binding var enabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            StepHeader(
                title: "Sollen wir Sie an Fristen erinnern?",
                explanation: "Manche Fristen sind kurz und lassen sich nicht nachholen – die Meldung an die Lebensversicherung etwa oder die Frist zur Ausschlagung des Erbes."
            )

            VStack(alignment: .leading, spacing: Spacing.m) {
                Label("Eine Erinnerung sieben Tage vorher", systemImage: "bell")
                Label("Eine Erinnerung zwei Tage vorher", systemImage: "bell")
                Label("Sonst nichts. Keine Werbung, keine Tipps.", systemImage: "hand.raised")
            }
            .font(.body)
            .foregroundStyle(Palette.textPrimary)
            .cardStyle()

            Text("Die Erinnerungen werden auf Ihrem Gerät erzeugt. Es wird nichts gesendet und nichts gespeichert.")
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
