import SwiftUI
import SwiftData

struct SettingsView: View {

    @Bindable var profile: Profile
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.modelContext) private var modelContext

    @Query private var taskStates: [TaskState]
    @Query private var documentStates: [DocumentState]

    @State private var showsPaywall = false
    @State private var showsResetConfirmation = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileEditView(profile: profile)
                    } label: {
                        Label("Angaben ändern", systemImage: "person.text.rectangle")
                    }
                } header: {
                    Text("Ihre Situation")
                } footer: {
                    Text("Sterbedatum, Ort und Verhältnis bestimmen, welche Aufgaben angezeigt und wie Fristen berechnet werden.")
                }

                Section {
                    Toggle(isOn: $profile.remindersEnabled) {
                        Label("Erinnerungen an Fristen", systemImage: "bell")
                    }
                    .disabled(!purchases.isUnlocked)

                    Toggle(isOn: $profile.hideNotRelevant) {
                        Label("Nicht relevante Aufgaben ausblenden", systemImage: "eye.slash")
                    }
                } header: {
                    Text("Ansicht")
                } footer: {
                    if purchases.isUnlocked {
                        Text("Wir erinnern sieben Tage und zwei Tage vor Ablauf einer Frist, vormittags um halb zehn.")
                    } else {
                        Text("Erinnerungen sind Teil der Vollversion.")
                    }
                }

                Section {
                    if purchases.isUnlocked {
                        Label("Vollversion ist freigeschaltet", systemImage: "checkmark.seal")
                            .foregroundStyle(Palette.accent)
                    } else {
                        Button {
                            showsPaywall = true
                        } label: {
                            Label("Vollversion freischalten", systemImage: "lock.open")
                        }
                    }

                    Button {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isUnlocked
                                ? "Ihr Kauf wurde wiederhergestellt."
                                : "Es wurde kein früherer Kauf gefunden."
                        }
                    } label: {
                        Label("Kauf wiederherstellen", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("Vollversion")
                } footer: {
                    Text("Einmaliger Kauf, kein Abonnement. Der Kauf ist an Ihre Apple-ID gebunden und lässt sich auf Ihren Geräten wiederherstellen.")
                }

                Section {
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Label("Datenschutz", systemImage: "hand.raised")
                    }
                    NavigationLink {
                        DisclaimerView()
                    } label: {
                        Label("Rechtlicher Hinweis", systemImage: "text.book.closed")
                    }
                    NavigationLink {
                        ImprintView()
                    } label: {
                        Label("Impressum", systemImage: "info.circle")
                    }
                    NavigationLink {
                        SourcesView()
                    } label: {
                        Label("Woher die Inhalte stammen", systemImage: "books.vertical")
                    }
                } header: {
                    Text("Rechtliches")
                }

                Section {
                    Button(role: .destructive) {
                        showsResetConfirmation = true
                    } label: {
                        Label("Alle Daten löschen", systemImage: "trash")
                    }
                } footer: {
                    Text("Löscht Ihre Angaben, alle Häkchen und alle Notizen unwiderruflich von diesem Gerät.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Inhalte", value: "Stand \(ContentStore.shared.contentUpdated)")
                }
                #if DEBUG
                Section("Entwicklung") {
                    Toggle("Vollversion simulieren", isOn: $purchases.debugUnlockOverride)
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("Mehr")
            .sheet(isPresented: $showsPaywall) { PaywallView() }
            .alert("Hinweis", isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("In Ordnung") { restoreMessage = nil }
            } message: {
                Text(restoreMessage ?? "")
            }
            .confirmationDialog("Wirklich alle Daten löschen?",
                                isPresented: $showsResetConfirmation,
                                titleVisibility: .visible) {
                Button("Alles löschen", role: .destructive) { reset() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Ihre Notizen und der Fortschritt gehen dabei verloren. Das lässt sich nicht rückgängig machen.")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func reset() {
        NotificationService.shared.cancelAll()
        for state in taskStates { modelContext.delete(state) }
        for state in documentStates { modelContext.delete(state) }
        profile.onboardingCompleted = false
        profile.disclaimerAcknowledgedAt = nil
        profile.remindersEnabled = false
        profile.dateOfDeath = Date()
        try? modelContext.save()
    }
}
