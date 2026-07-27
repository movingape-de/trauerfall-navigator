import SwiftUI
import SwiftData

/// Entscheidet, ob das Onboarding oder die Hauptansicht gezeigt wird.
/// Es gibt genau ein Profil; fehlt es, wird es beim ersten Start angelegt.
struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                if profile.onboardingCompleted {
                    MainTabView(profile: profile)
                } else {
                    OnboardingFlowView(profile: profile)
                }
            } else {
                // Kurzer Moment beim allerersten Start, bis das Profil steht.
                Color.clear
                    .onAppear {
                        modelContext.insert(Profile())
                        try? modelContext.save()
                    }
            }
        }
        .background(Palette.background)
    }
}
