import SwiftUI

/// Schmaler Fortschrittsbalken. Bewusst ohne Prozentzahl und ohne Feier
/// beim Abschluss – erledigt ist erledigt.
struct ProgressBar: View {

    let progress: PhaseProgress
    var showsLabel: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Palette.surfaceMuted)
                    Capsule(style: .continuous)
                        .fill(Palette.accent)
                        .frame(width: max(0, geometry.size.width * progress.fraction))
                }
            }
            .frame(height: 6)

            if showsLabel {
                Text(progress.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fortschritt")
        .accessibilityValue("\(progress.done) von \(progress.total) Aufgaben erledigt")
    }
}

#Preview {
    VStack(spacing: Spacing.l) {
        ProgressBar(progress: PhaseProgress(done: 8, total: 12))
        ProgressBar(progress: PhaseProgress(done: 0, total: 9))
        ProgressBar(progress: PhaseProgress(done: 5, total: 5))
    }
    .padding()
}
