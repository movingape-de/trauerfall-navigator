import SwiftUI

/// Zeigt eine Frist als ruhige Zeile, nicht als Alarmzeichen.
struct DeadlineBadge: View {

    let spec: DeadlineSpec?
    let dueDate: Date?
    var style: Style = .compact

    enum Style {
        case compact   // in der Liste
        case detailed  // in der Detailansicht und im Fristen-Bereich
    }

    private var urgency: Urgency {
        guard let dueDate else { return .distant }
        return DeadlineEngine.urgency(due: dueDate)
    }

    private var isImmediate: Bool { DeadlineEngine.isImmediate(spec) }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: urgency == .passed ? "exclamationmark.circle" : "clock")
                .font(.footnote)
                .foregroundStyle(urgency.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryText)
                    .font(.subheadline)
                    .foregroundStyle(urgency.color)

                if style == .detailed, let dueDate, !isImmediate {
                    Text(DeadlineEngine.formatted(dueDate, spec: spec))
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }

                if style == .detailed, let note = spec?.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, style == .detailed ? Spacing.s : 0)
        .padding(.horizontal, style == .detailed ? Spacing.m : 0)
        .background {
            if style == .detailed {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .fill(urgency.surface)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var primaryText: String {
        guard let dueDate, !isImmediate else {
            return spec?.label ?? ""
        }
        let countdown = DeadlineEngine.countdownText(due: dueDate)
        guard let label = spec?.label else { return countdown }
        return style == .detailed ? "\(label) · \(countdown)" : countdown
    }

    private var accessibilityText: String {
        guard let dueDate, !isImmediate else {
            return "Frist: \(spec?.label ?? "keine")"
        }
        return DeadlineEngine.accessibilityText(label: spec?.label ?? "Frist", due: dueDate)
    }
}
