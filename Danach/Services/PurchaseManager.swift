import Foundation
import OSLog
import StoreKit

/// Kaufvorgänge landen im Systemprotokoll, damit sich ein Fehlschlag auch
/// aus einem TestFlight-Build nachvollziehen lässt – dort greift `#if DEBUG`
/// nicht, weil TestFlight gegen die Release-Konfiguration baut.
private let log = Logger(subsystem: "de.movingape.danach", category: "kauf")

/// Verwaltet den einmaligen Kauf der Vollversion.
///
/// Bewusst kein Abonnement: Bei diesem Thema wäre eine laufende Zahlung
/// unangemessen. Wer die App braucht, braucht sie einige Wochen lang.
@MainActor
final class PurchaseManager: ObservableObject {

    static let productID = "de.movingape.danach.vollversion"

    enum State: Equatable {
        case idle
        case loading
        case purchasing
        case failed(String)
    }

    /// Ob der App Store einen gültigen Kauf bestätigt hat.
    @Published private(set) var hasEntitlement: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var state: State = .idle

    private var updateTask: Task<Void, Never>?

    /// Erlaubt das Freischalten im Simulator ohne StoreKit-Konfiguration.
    /// Nur in Debug-Builds wirksam.
    @Published var debugUnlockOverride: Bool = false

    /// Bewusst berechnet statt gespeichert. Ein `didSet` auf
    /// `debugUnlockOverride`, das hier hineinschreibt, verwirft SwiftUI
    /// mitten im Aktualisierungslauf – der Schalter klappte zurück.
    var isUnlocked: Bool {
        #if DEBUG
        return hasEntitlement || debugUnlockOverride
        #else
        return hasEntitlement
        #endif
    }

    init() {
        updateTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    deinit { updateTask?.cancel() }

    /// Der hinterlegte Preis. Gilt nur, solange der App Store noch keinen
    /// eigenen geliefert hat – muss mit App Store Connect und
    /// `Configuration/Danach.storekit` übereinstimmen.
    static let fallbackPrice = "14,99 €"

    /// Preis als Text. Bevorzugt der Wert aus dem App Store, weil nur der
    /// Storefront, Währung und Preisstufe berücksichtigt.
    var displayPrice: String { product?.displayPrice ?? Self.fallbackPrice }

    /// Ob ein Kauf überhaupt angeboten werden kann.
    var canPurchase: Bool { product != nil }

    func start() async {
        await loadProduct()
        await refreshEntitlements()
    }

    func loadProduct() async {
        state = .loading
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if product == nil {
                // Der App Store hat geantwortet, kennt die Kennung aber nicht.
                // Typisch, solange das Produkt in App Store Connect noch nicht
                // freigegeben ist oder der Vertrag für kostenpflichtige Apps fehlt.
                log.error("Produkt \(Self.productID, privacy: .public) unbekannt")
            }
            state = .idle
        } catch {
            product = nil
            log.error("Laden fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
            state = .failed(zusammen("Der App Store ist gerade nicht erreichbar.", error))
        }
    }

    /// Nennt den Grund mit, statt ihn zu verschlucken. Apples eigene
    /// Fehlertexte sind übersetzt und verständlich – sie zu verstecken
    /// hilft niemandem, am wenigsten bei der Fehlersuche.
    private func zusammen(_ satz: String, _ error: Error) -> String {
        let grund = error.localizedDescription
        return grund.isEmpty ? satz : "\(satz)\n\n\(grund)"
    }

    func refreshEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                hasEntitlement = true
                return
            }
        }
        hasEntitlement = false
    }

    /// - Returns: `true`, wenn der Kauf erfolgreich abgeschlossen wurde.
    @discardableResult
    func purchase() async -> Bool {
        guard let product else {
            await loadProduct()
            guard product != nil else {
                state = .failed("Das Angebot konnte nicht geladen werden.")
                return false
            }
            return await purchase()
        }

        state = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    state = .idle
                    return true
                case .unverified(_, let error):
                    log.error("Beleg nicht prüfbar: \(error.localizedDescription, privacy: .public)")
                    state = .failed(zusammen("Der Kauf konnte nicht bestätigt werden.", error))
                    return false
                }
            case .userCancelled:
                state = .idle
                return false
            case .pending:
                // Etwa bei "Kauf anfragen" in der Familienfreigabe oder wenn die
                // Bank noch bestätigen muss. Ohne Hinweis wirkt der Knopf kaputt.
                state = .failed("Der Kauf wurde noch nicht abgeschlossen. Er wartet auf eine Bestätigung – sobald sie vorliegt, schaltet sich die Vollversion von selbst frei.")
                return false
            @unknown default:
                state = .idle
                return false
            }
        } catch {
            log.error("Kauf fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
            state = .failed(zusammen("Der Kauf wurde nicht abgeschlossen.", error))
            return false
        }
    }

    func restore() async {
        state = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            state = isUnlocked ? .idle : .failed("Es wurde kein früherer Kauf gefunden.")
        } catch {
            log.error("Wiederherstellung fehlgeschlagen: \(error.localizedDescription, privacy: .public)")
            state = .failed(zusammen("Die Wiederherstellung hat nicht geklappt.", error))
        }
    }

    func clearError() {
        if case .failed = state { state = .idle }
    }
}
