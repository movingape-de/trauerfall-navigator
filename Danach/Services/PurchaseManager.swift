import Foundation
import StoreKit

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
            state = .idle
        } catch {
            product = nil
            state = .failed("Der App Store ist gerade nicht erreichbar.")
        }
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
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    state = .idle
                    return true
                }
                state = .failed("Der Kauf konnte nicht bestätigt werden.")
                return false
            case .userCancelled:
                state = .idle
                return false
            case .pending:
                state = .idle
                return false
            @unknown default:
                state = .idle
                return false
            }
        } catch {
            state = .failed("Der Kauf wurde nicht abgeschlossen.")
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
            state = .failed("Die Wiederherstellung hat nicht geklappt.")
        }
    }

    func clearError() {
        if case .failed = state { state = .idle }
    }
}
