import SwiftUI

/// Das Häkchen einer Aufgabe. Bewusst als eigenständige Schaltfläche neben
/// dem Navigationsbereich – verschachtelte Buttons in einem NavigationLink
/// reagieren auf iOS unzuverlässig.
struct TaskCheckButton: View {

    let status: TaskStatus
    let title: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var symbolSize: CGFloat = 26

    var body: some View {
        Button(action: action) {
            Image(systemName: status.symbolName)
                .font(.system(size: symbolSize, weight: .regular))
                .foregroundStyle(status == .done ? Palette.accent : Palette.textSecondary)
                .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(status == .done ? "Als offen markieren" : "Als erledigt markieren")
        .accessibilityHint(title)
    }
}

/// Der Textteil einer Aufgabenzeile.
struct TaskRowContent: View {

    let entry: ChecklistEntry

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.definition.title)
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .strikethrough(entry.status == .done, color: Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(entry.definition.summary)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if entry.status == .open, entry.definition.deadline != nil {
                    DeadlineBadge(spec: entry.definition.deadline, dueDate: entry.dueDate)
                        .padding(.top, 2)
                }

                if entry.status == .notRelevant {
                    Text("Nicht relevant")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }

                if entry.hasNote {
                    Label("Notiz vorhanden", systemImage: "text.alignleft")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, Spacing.xs)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
        .opacity(entry.status == .open ? 1 : 0.65)
        .accessibilityElement(children: .combine)
    }
}
