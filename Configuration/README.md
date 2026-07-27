# StoreKit-Konfiguration

`Danach.storekit` beschreibt den Einmalkauf für Tests im Simulator, damit die
Kaufstrecke ohne App-Store-Connect-Eintrag durchgespielt werden kann.

## Im Simulator testen

1. In Xcode: **Product → Scheme → Edit Scheme → Run → Options**
2. Bei **StoreKit Configuration** die Datei `Configuration/Danach.storekit`
   auswählen.
3. App starten. Der Kauf läuft dann gegen die lokale Konfiguration.

Über **Debug → StoreKit → Manage Transactions** lassen sich Käufe zurücknehmen,
um den Zustand „noch nicht gekauft“ wiederherzustellen.

Ohne StoreKit-Konfiguration greift im Debug-Build der Schalter
„Vollversion simulieren“ unter *Mehr → Entwicklung*.

## Vor der Veröffentlichung

In App Store Connect ein nicht verbrauchbares Produkt anlegen:

| Feld | Wert |
|---|---|
| Produkt-ID | `de.movingape.danach.vollversion` |
| Typ | Nicht verbrauchbar |
| Referenzname | Vollversion |
| Preisstufe | 14,99 € |
| Anzeigename | Vollversion freischalten |

Die Produkt-ID steht in `PurchaseManager.productID` und muss übereinstimmen.
Ändert sich der Bundle-Identifier, ändert sich üblicherweise auch die
Produkt-ID – dann beide Stellen anpassen.
