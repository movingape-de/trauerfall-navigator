import SwiftUI

/// Gemeinsamer Aufbau der Rechtstexte: viel Weißraum, lange Zeilen begrenzt.
private struct LegalPage<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                content
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
            .readableWidth()
        }
        .background(Palette.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalParagraph: View {
    let heading: String?
    let text: String

    init(_ heading: String? = nil, _ text: String) {
        self.heading = heading
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let heading {
                Text(heading)
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(text)
                .font(.body)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Datenschutz

struct PrivacyView: View {
    var body: some View {
        LegalPage(title: "Datenschutz") {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Image(systemName: "hand.raised")
                    .font(.system(size: 32))
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)
                Text("Ihre Daten bleiben auf diesem Gerät.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle(Palette.accentSurface)

            LegalParagraph("Was wir nicht tun",
                           "Diese App hat keinen Server. Es gibt kein Nutzerkonto, keine Anmeldung, keine Registrierung. Wir übertragen nichts, was Sie eingeben. Wir setzen keine Analyse- oder Werbewerkzeuge ein und binden keine fremden Dienste ein.")

            LegalParagraph("Was gespeichert wird",
                           "Das Sterbedatum, Ihre vier Antworten aus dem Onboarding, der Stand Ihrer Aufgaben und Ihre Notizen. Alles liegt ausschließlich im Speicher dieser App auf diesem Gerät und wird nicht in iCloud abgelegt.")

            LegalParagraph("Erinnerungen",
                           "Die Erinnerungen an Fristen werden von Ihrem iPhone selbst erzeugt. Es werden keine Push-Nachrichten von außen zugestellt, es fließen keine Daten ab.")

            LegalParagraph("Der Kauf",
                           "Der Einmalkauf wird über den App Store abgewickelt. Wir erfahren dabei nicht, wer Sie sind. Apple teilt uns lediglich anonymisiert mit, dass ein Kauf stattgefunden hat.")

            LegalParagraph("Löschen",
                           "Über „Alle Daten löschen“ in den Einstellungen entfernen Sie sämtliche Eingaben unwiderruflich. Beim Löschen der App verschwindet ebenfalls alles.")
        }
    }
}

// MARK: - Rechtlicher Hinweis

struct DisclaimerView: View {
    var body: some View {
        LegalPage(title: "Rechtlicher Hinweis") {
            LegalParagraph("Keine Rechtsberatung",
                           "Diese App bietet allgemeine Orientierung nach einem Todesfall. Sie ersetzt keine Rechts-, Steuer- oder Finanzberatung und trifft keine Aussage über Ihren konkreten Fall.")

            LegalParagraph("Landesrecht",
                           "Bestattungs- und Friedhofsrecht ist Sache der Bundesländer. Bestattungsfristen, zulässige Bestattungsarten und Meldepflichten unterscheiden sich. Wir nennen die verbreiteten Regelungen und weisen darauf hin, wo es Unterschiede gibt.")

            LegalParagraph("Fristen",
                           "Alle Fristen werden aus dem von Ihnen angegebenen Sterbedatum berechnet. Einige gesetzliche Fristen laufen jedoch ab dem Zeitpunkt der Kenntnis – etwa die Frist zur Ausschlagung des Erbes. Die angezeigten Termine sind daher Anhaltspunkte, keine verbindlichen Angaben.")

            LegalParagraph("Wann Sie jemanden hinzuziehen sollten",
                           "Bei Schulden im Nachlass, unklarer Erbfolge, Streit in der Familie, Unternehmensbeteiligungen, Immobilien oder Auslandsbezug wenden Sie sich bitte an einen Fachanwalt für Erbrecht, einen Notar, einen Steuerberater oder eine Verbraucherzentrale.")

            LegalParagraph("Haftung",
                           "Die Inhalte wurden sorgfältig erstellt. Für Richtigkeit, Vollständigkeit und Aktualität kann keine Gewähr übernommen werden.")
        }
    }
}

// MARK: - Impressum

struct ImprintView: View {
    var body: some View {
        LegalPage(title: "Impressum") {
            LegalParagraph("Anbieter",
                           "Dominik Stingl\nKüllenhahnerstr. 194\n42349 Wuppertal\nDeutschland")

            LegalParagraph("Kontakt",
                           "E-Mail: movingape@gmail.com")

            LegalParagraph("Verantwortlich für den Inhalt",
                           "Dominik Stingl, Anschrift wie oben")

            LegalParagraph("Streitbeilegung",
                           "Wir sind nicht bereit und nicht verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.")
        }
    }
}

// MARK: - Quellen

struct SourcesView: View {
    var body: some View {
        LegalPage(title: "Woher die Inhalte stammen") {
            LegalParagraph(nil,
                           "Die Aufgabenliste wurde aus öffentlich zugänglichen Checklisten und den einschlägigen Gesetzen zusammengestellt.")

            LegalParagraph("Verwendete Quellen",
                           "· Stiftung Warentest, Ratgeber und Checklisten zum Todesfall\n· Bundesverband Deutscher Bestatter\n· Verbraucherzentralen der Länder\n· Deutsche Rentenversicherung, Hinweise für Hinterbliebene\n· Bundesnotarkammer zum Zentralen Testamentsregister")

            LegalParagraph("Rechtsgrundlagen",
                           "· Bürgerliches Gesetzbuch, insbesondere zu Erbschaft, Ausschlagung und Mietverhältnis\n· Personenstandsgesetz zur Anzeige des Sterbefalls\n· Erbschaftsteuer- und Schenkungsteuergesetz zur Anzeigepflicht\n· Sechstes Buch Sozialgesetzbuch zur Hinterbliebenenrente\n· Bestattungsgesetze der Länder")

            LegalParagraph("Aktualität",
                           "Inhalte mit Stand \(ContentStore.shared.contentUpdated). Gesetze ändern sich. Wenn Ihnen etwas veraltet oder falsch erscheint, schreiben Sie uns gern.")
        }
    }
}
