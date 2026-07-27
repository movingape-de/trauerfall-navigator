import SwiftUI

/// Nachträgliches Ändern der Onboarding-Angaben.
struct ProfileEditView: View {

    @Bindable var profile: Profile

    var body: some View {
        Form {
            Section {
                DatePicker("Sterbedatum",
                           selection: $profile.dateOfDeath,
                           in: ...Date(),
                           displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "de_DE"))
            } footer: {
                Text("Grundlage für alle Fristen. Eine Änderung berechnet Fristen und Erinnerungen neu.")
            }

            Section("Sterbeort") {
                Picker("Sterbeort", selection: Binding(
                    get: { profile.placeOfDeath },
                    set: { profile.placeOfDeath = $0 }
                )) {
                    ForEach(PlaceOfDeath.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Ihr Verhältnis zur verstorbenen Person") {
                Picker("Verhältnis", selection: Binding(
                    get: { profile.relationship },
                    set: { profile.relationship = $0 }
                )) {
                    ForEach(Relationship.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Testament oder Erbvertrag") {
                Picker("Testament", selection: Binding(
                    get: { profile.hasWill },
                    set: { profile.hasWill = $0 }
                )) {
                    ForEach(TriState.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Picker("Bestattungsvorsorge", selection: Binding(
                    get: { profile.hasFuneralProvision },
                    set: { profile.hasFuneralProvision = $0 }
                )) {
                    ForEach(TriState.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Bestattungsvorsorge")
            } footer: {
                Text("Wenn Sie eine Angabe ändern, können Aufgaben hinzukommen oder verschwinden. Ihre Häkchen und Notizen bleiben erhalten.")
            }
        }
        .navigationTitle("Angaben ändern")
        .navigationBarTitleDisplayMode(.inline)
    }
}
