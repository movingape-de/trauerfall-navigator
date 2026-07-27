# Von hier bis in den App Store

Alles, was ohne Mac vorbereitbar war, ist vorbereitet. Was bleibt, sind
Schritte, die zwingend Xcode oder App Store Connect brauchen. Rechnen Sie mit
einem halben Tag, das meiste davon Warten auf Apple.

---

## 1 · Das Projekt auf Ihren Mac holen

```bash
cd ~/Downloads
git clone trauerfall-navigator.bundle trauerfall-navigator
cd trauerfall-navigator
git remote set-url origin https://github.com/movingape-de/trauerfall-navigator.git
git push -u origin main
```

---

## 2 · In Xcode bauen

```bash
open Danach.xcodeproj
```

1. In der Dateiliste links oben **Danach** anklicken, Reiter
   **Signing & Capabilities**.
2. Bei **Team** Ihren Apple-Developer-Account wählen. Fehlt er, unter
   *Xcode → Settings → Accounts* die Apple-ID hinzufügen.
3. Oben einen Simulator wählen, etwa *iPhone 16*, dann **⌘R**.

Der Bundle-Identifier ist `de.movingape.danach`. Wollen Sie einen anderen,
ändern Sie ihn hier und im gleichen Zug in `Configuration/Danach.storekit`
sowie in `PurchaseManager.productID`.

**Wenn der Build rot wird:** Das ist möglich – das Projekt wurde ohne Xcode
geschrieben. Syntax und Symbole sind maschinell geprüft, der Typcheck des
Compilers nicht. Erwartbar sind einzelne SwiftUI-Modifier. Schicken Sie mir die
Meldungen, das ist in Minuten erledigt.

### Kaufstrecke im Simulator prüfen

Das mitgelieferte Schema verweist bereits auf `Configuration/Danach.storekit`.
Der Kauf funktioniert also sofort, ohne Eintrag in App Store Connect. Unter
*Debug → StoreKit → Manage Transactions* nehmen Sie einen Kauf wieder zurück,
um den Ausgangszustand herzustellen.

Ohne StoreKit-Konfiguration hilft im Debug-Build der Schalter
*Mehr → Entwicklung → Vollversion simulieren*.

---

## 3 · Auf einem echten Gerät testen

Der Simulator zeigt nicht alles. Vor der Einreichung mindestens einmal auf
einem iPhone prüfen:

- **Benachrichtigungen.** Erlauben, App schließen, Systemzeit vorstellen oder
  ein Sterbedatum wählen, bei dem eine Frist in sieben Tagen liegt.
- **Dynamic Type.** In *Einstellungen → Anzeige & Helligkeit → Textgröße* auf
  die größte Stufe. Nichts darf abgeschnitten sein.
- **VoiceOver.** Einmal durch die Aufgabenliste wischen. Jedes Häkchen muss
  sich ansagen lassen.
- **Dunkelmodus.**

---

## 4 · Angaben in eckigen Klammern ersetzen

An drei Stellen stehen Platzhalter:

| Datei | Was |
|---|---|
| `Danach/Views/Settings/LegalViews.swift` | Impressum in der App, `struct ImprintView` |
| `AppStore/website/impressum.html` | Impressum der Website |
| `AppStore/website/datenschutz.html` | Verantwortlicher, Datum, Hosting-Anbieter |

Alle finden:

```bash
grep -rn "\[" AppStore/website/*.html Danach/Views/Settings/LegalViews.swift
```

Ohne vollständiges Impressum lehnt Apple die App ab, und abmahnfähig ist es
außerdem.

---

## 5 · Website veröffentlichen

Apple verlangt zwei erreichbare URLs. Die Seiten liegen fertig in
`AppStore/website/`.

```bash
git subtree push --prefix AppStore/website origin gh-pages
```

Danach im Repository unter *Settings → Pages* als Quelle den Zweig `gh-pages`
wählen. Nach wenigen Minuten erreichbar unter
`https://movingape-de.github.io/trauerfall-navigator/`.

Prüfen Sie beide Seiten im Browser, bevor Sie die URLs eintragen. Eine tote
Datenschutz-URL ist ein häufiger Ablehnungsgrund.

---

## 6 · App Store Connect einrichten

Unter [appstoreconnect.apple.com](https://appstoreconnect.apple.com) →
*Meine Apps* → **+** → *Neue App*.

| Feld | Wert |
|---|---|
| Plattform | iOS |
| Name | Danach – Trauerfall-Navigator |
| Sprache | Deutsch |
| Bundle-ID | de.movingape.danach |
| SKU | danach-1 |

Alle weiteren Texte stehen fertig in [`metadaten.md`](metadaten.md) und lassen
sich von dort übernehmen: Untertitel, Werbetext, Schlüsselwörter, Beschreibung,
Kategorien, Altersfreigabe.

### In-App-Kauf anlegen

*Monetarisierung → In-App-Käufe → Erstellen*, Typ **nicht verbrauchbar**:

| Feld | Wert |
|---|---|
| Referenzname | Vollversion |
| Produkt-ID | `de.movingape.danach.vollversion` |
| Preis | 14,99 € |
| Anzeigename | Vollversion freischalten |

Der Kauf braucht ein eigenes Prüfbild. Verwenden Sie den Paywall-Screenshot.

### App-Datenschutz

*App-Datenschutz → Bearbeiten*:

> Erfasst Ihre App Daten? → **Nein**

Das ist zutreffend, nicht beschönigt. Die App hat kein Backend.

---

## 7 · Screenshots

Als Entwurf im richtigen Format, auf Ihrem Mac erzeugt:

```bash
cd Tools && npm install playwright-core && cd ..
python3 Tools/preview/build.py
node Tools/preview/appstore.mjs
```

Die Bilder liegen dann in `Tools/preview/appstore/` in den Formaten
1290 × 2796 und 1242 × 2688.

Diese Aufnahmen stammen aus der Browser-Vorschau, nicht aus der App. Für die
Einreichung sind sie brauchbar, weil sie dieselbe Gestaltung und dieselben
Inhalte zeigen – **ersetzen Sie sie trotzdem**, sobald der Build läuft:

1. Simulator *iPhone 16 Pro Max* starten
2. Bildschirm einrichten, dann **⌘S** – das Bild landet auf dem Schreibtisch
3. Fünf Aufnahmen: Phasenübersicht, Fristen, Aufgabendetail, Unterlagen,
   Onboarding

Echte Aufnahmen sind ehrlicher und rendern in SF Pro.

---

## 8 · Archivieren und hochladen

1. In Xcode oben als Ziel **Any iOS Device** wählen
2. *Product → Archive*
3. Im Organizer **Distribute App → App Store Connect → Upload**

Die Frage nach Exportbeschränkungen entfällt: `ITSAppUsesNonExemptEncryption`
steht bereits auf `NO`.

Nach dem Upload dauert die Verarbeitung 10 bis 60 Minuten. Danach lässt sich
der Build in App Store Connect auswählen.

---

## 9 · Einreichen

Vor dem Klick auf *Zur Prüfung freigeben*:

- [ ] Alle Pflichtfelder ausgefüllt
- [ ] Screenshots hochgeladen
- [ ] Datenschutz-URL und Support-URL erreichbar
- [ ] In-App-Kauf zur Prüfung mit eingereicht — **das wird oft vergessen.**
      Der Kauf muss beim ersten Mal zusammen mit der App eingereicht werden,
      sonst ist die App live und der Kauf funktioniert nicht.
- [ ] Prüfhinweise aus `metadaten.md` eingetragen

Die Prüfung dauert üblicherweise 24 bis 48 Stunden.

---

## Womit bei der Prüfung zu rechnen ist

**Guideline 3.1.1 – In-App-Kauf.** Unproblematisch: digitale Inhalte über
StoreKit, kein externer Zahlungsweg.

**Guideline 5.1.1 – Datenerhebung.** Unproblematisch: Es wird nichts erhoben,
das Datenschutz-Manifest sagt dasselbe.

**Guideline 1.4.1 – Medizinische oder rechtliche Inhalte.** Das ist der Punkt,
an dem eine Rückfrage kommen könnte. Die App gibt rechtsnahe Auskünfte. Sie
weist an vier Stellen ausdrücklich darauf hin, dass sie keine Rechtsberatung
ersetzt: im Onboarding, unter jeder Aufgabe, in der Fristenübersicht und in
einem eigenen Abschnitt unter *Mehr*. Der vorbereitete Prüfhinweis greift das
auf. Sollte trotzdem nachgefragt werden, verweisen Sie auf diese vier Stellen
und auf den Quellenabschnitt in der App.

**Metadaten.** Der Untertitel muss die App beschreiben, nicht bewerben. Das
tut er.

---

## Nach der Freigabe

- **Preis prüfen.** 14,99 € ist meine Empfehlung; die ursprüngliche Vorgabe
  waren 9,99 €. Der Preis lässt sich jederzeit ohne neue Version ändern.
- **Inhalte pflegen.** Gesetze ändern sich. Der gesamte Katalog liegt in
  `Danach/Content/tasks_de.json`; eine Änderung dort braucht keinen
  Code-Eingriff, nur eine neue Version. Vorher `node Tools/validate_content.mjs`
  laufen lassen.
- **Anwaltliche Durchsicht.** Wenn Sie eines nachholen: das. Fünfzehn harte
  Fristen mit Countdown sind ein Versprechen an Menschen in einer
  Ausnahmesituation.
