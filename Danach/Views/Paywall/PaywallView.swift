import SwiftUI

/// Der Kaufbildschirm. Bewusst ohne Countdown, ohne Rabattschild, ohne
/// „nur noch heute“. Wer diese App öffnet, steht ohnehin unter Druck.
struct PaywallView: View {

    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    header
                    included
                    honesty
                    purchaseButton
                    unavailableHint
                    restoreButton
                    footer
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.l)
                .readableWidth()
            }
            .background(Palette.background)
            .navigationTitle("Vollversion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .alert("Es hat nicht geklappt", isPresented: Binding(
                get: { if case .failed = purchases.state { return true } else { return false } },
                set: { if !$0 { purchases.clearError() } }
            )) {
                Button("In Ordnung") { purchases.clearError() }
            } message: {
                if case .failed(let message) = purchases.state {
                    Text(message)
                }
            }
            .onChange(of: purchases.isUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }

    // MARK: - Bausteine

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Die vollständige Begleitung")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Die erste Phase bleibt dauerhaft kostenlos. Alles Weitere schalten Sie einmalig frei.")
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var included: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            row("Alle vier Phasen",
                "Die ersten Tage, Wochen und Monate mit allen Aufgaben – von der Sterbeurkunde bis zur Steuererklärung.")
            Divider().background(Palette.separator)
            row("Erinnerungen an Fristen",
                "Sieben Tage und zwei Tage vorher. Manche Frist lässt sich nicht nachholen.")
            Divider().background(Palette.separator)
            row("Die Unterlagen-Mappe",
                "Welches Dokument Sie wofür brauchen und in welcher Anzahl.")
            Divider().background(Palette.separator)
            row("Notizen zu jeder Aufgabe",
                "Aktenzeichen, Ansprechpartner, offene Punkte – an der richtigen Stelle.")
        }
        .cardStyle()
    }

    private func row(_ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 20)
                .padding(.top, 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var honesty: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            statement("Einmalig \(purchases.displayPrice). Kein Abonnement, keine Folgekosten.")
            statement("Keine Weitergabe Ihrer Daten. Es gibt nichts weiterzugeben – die App hat keinen Server.")
            statement("Der Kauf gilt für alle Ihre Geräte mit derselben Apple-ID.")
        }
        .cardStyle(Palette.accentSurface)
    }

    private func statement(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Palette.accent)
                .padding(.top, 8)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var isBusy: Bool {
        purchases.state == .purchasing || purchases.state == .loading
    }

    /// Ohne geladenes Produkt bietet der Knopf keinen Kauf an, sondern einen
    /// neuen Versuch. Sonst verspräche er etwas, das er nicht halten kann.
    private var purchaseButton: some View {
        Button {
            Task {
                if purchases.canPurchase {
                    await purchases.purchase()
                } else {
                    await purchases.loadProduct()
                }
            }
        } label: {
            if isBusy {
                ProgressView()
                    .tint(.white)
            } else if purchases.canPurchase {
                Text("Für \(purchases.displayPrice) freischalten")
            } else {
                Text("Erneut versuchen")
            }
        }
        .buttonStyle(CalmButtonStyle())
        .disabled(isBusy)
    }

    @ViewBuilder
    private var unavailableHint: some View {
        if !purchases.canPurchase, !isBusy {
            Text("Das Angebot lässt sich gerade nicht laden. Prüfen Sie Ihre Internetverbindung und versuchen Sie es noch einmal.")
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var restoreButton: some View {
        Button("Früheren Kauf wiederherstellen") {
            Task { await purchases.restore() }
        }
        .font(.subheadline)
        .foregroundStyle(Palette.textSecondary)
        .frame(maxWidth: .infinity, minHeight: Layout.minTapTarget)
    }

    private var footer: some View {
        Text("Diese App ersetzt keine Rechtsberatung. Wenn Ihnen die Vollversion nicht weiterhilft, wenden Sie sich an Apple – Erstattungen laufen über den App Store.")
            .font(.footnote)
            .foregroundStyle(Palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Spacing.s)
    }
}
