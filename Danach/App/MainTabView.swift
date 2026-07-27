import SwiftUI
import SwiftData

struct MainTabView: View {

    @Bindable var profile: Profile
    @StateObject private var purchases = PurchaseManager()

    @Query private var taskStates: [TaskState]

    var body: some View {
        TabView {
            PhaseOverviewView(profile: profile)
                .tabItem { Label("Aufgaben", systemImage: "checklist") }

            DeadlineOverviewView(profile: profile)
                .tabItem { Label("Fristen", systemImage: "clock") }

            DocumentChecklistView(profile: profile)
                .tabItem { Label("Unterlagen", systemImage: "folder") }

            SettingsView(profile: profile)
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle") }
        }
        .environmentObject(purchases)
        .task {
            await purchases.start()
            await syncReminders()
        }
        // Fristen können sich ändern, ohne dass eine Aufgabe angefasst wird –
        // etwa wenn das Sterbedatum korrigiert wird.
        .onChange(of: profile.dateOfDeath) { _, _ in Task { await syncReminders() } }
        .onChange(of: profile.remindersEnabled) { _, _ in Task { await syncReminders() } }
        .onChange(of: taskStates.count) { _, _ in Task { await syncReminders() } }
        .onChange(of: purchases.isUnlocked) { _, _ in Task { await syncReminders() } }
    }

    /// Erinnerungen gehören zur Vollversion. Ohne Kauf werden nur die
    /// Fristen aus der kostenfreien Phase eingeplant.
    private func syncReminders() async {
        let states = Checklist.stateMap(taskStates)
        var entries = Checklist.deadlineEntries(profile: profile.snapshot, states: states)
        if !purchases.isUnlocked {
            entries = entries.filter { $0.definition.phase.isFree }
        }
        await NotificationService.shared.reschedule(entries: entries,
                                                    enabled: profile.remindersEnabled)
    }
}
