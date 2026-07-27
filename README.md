# Danach – Der Trauerfall-Navigator

Eine native iOS-App, die Hinterbliebene in Deutschland nach einem Todesfall
Schritt für Schritt durch die Formalitäten begleitet.

Die App ist ein ruhiger Begleiter in einer Ausnahmesituation – kein
Produktivitätstool. Keine Gamification, keine Badges, keine Feier bei
100 Prozent. Nur: Was ist jetzt zu tun, warum, bis wann, und was brauche ich
dafür.

**Die App ersetzt keine Rechtsberatung.** Alle Angaben sind allgemeine
Orientierung.

## Grundsätze

- **Komplett lokal.** Kein Backend, kein Account, kein Tracking, keine
  iCloud-Synchronisierung. Alle Daten bleiben auf dem Gerät. Bei diesem Thema
  ist das keine Nebensache, sondern die Voraussetzung für Vertrauen.
- **Barrierefrei.** Dynamic Type bis zu den größten Stufen, VoiceOver-Labels,
  hohe Kontraste, Tippziele ab 52 pt. Ein großer Teil der Nutzer ist über 60.
- **Inhalte ohne Code pflegbar.** Der gesamte Aufgaben- und Dokumentenkatalog
  liegt als JSON im Bundle.

## Technik

| | |
|---|---|
| Sprache | Swift 5, SwiftUI |
| Mindestversion | iOS 17 |
| Persistenz | SwiftData |
| Erinnerungen | UNUserNotificationCenter, rein lokal |
| Kauf | StoreKit 2, Einmalkauf, kein Abo |

## Projektstruktur

```
Danach.xcodeproj/          Xcode-Projekt (synchronisierte Ordner, Xcode 16+)
project.yml                XcodeGen-Beschreibung als Ersatzweg
Danach/
  App/                     Einstieg, Wurzelansicht, Tab-Navigation
  Models/
    Enums.swift            Phase, Sterbeort, Verhältnis, Status
    ContentModels.swift    Codable-Modelle für den JSON-Katalog
    PersistentModels.swift SwiftData: Profil, Aufgaben-, Dokumentenzustand
  Content/
    tasks_de.json          Aufgabenkatalog
    documents_de.json      Dokumentenkatalog
    ContentStore.swift     Laden und Filtern
  Services/                Fristen-Engine, Benachrichtigungen, Kauf
  DesignSystem/Theme.swift Farben, Abstände, Bausteine
  Views/                   Onboarding, Phasen, Fristen, Dokumente, …
  Resources/               Asset-Katalog
Tools/validate_content.mjs Prüft den JSON-Katalog
Configuration/             StoreKit-Testkonfiguration
```

## Datenmodell: warum getrennt

Der Inhalt einer Aufgabe (Titel, Erklärtext, Frist, Bedingungen) steht **nur**
im JSON. SwiftData speichert **nur** den Nutzerzustand – Status, Notiz,
angepasste Frist – referenziert über die `taskID`.

Damit lassen sich Inhalte per App-Update korrigieren und erweitern, ohne dass
Notizen oder Häkchen der Nutzer angefasst werden. Der umgekehrte Weg – Aufgaben
beim ersten Start in die Datenbank kopieren – wäre einfacher gewesen, hätte aber
jede Content-Korrektur zu einer Migration gemacht.

## Content-Schema

Eine Aufgabe in `tasks_de.json`:

```json
{
  "id": "sterbeurkunde_standesamt",
  "phase": 2,
  "title": "Sterbefall beim Standesamt anzeigen",
  "summary": "Ein Satz für die Liste.",
  "details": "Ausklappbarer Text: was, warum, worauf achten.",
  "documents": ["Todesbescheinigung", "Stammbuch"],
  "contacts": ["Standesamt des Sterbeortes"],
  "tips": ["Fünf bis zehn Ausfertigungen bestellen."],
  "deadline": {
    "type": "relative",
    "unit": "business_days",
    "amount": 3,
    "label": "spätestens am dritten Werktag",
    "strict": true,
    "note": "§ 28 Personenstandsgesetz"
  },
  "conditions": { "placeOfDeath": ["home"] },
  "priority": 1
}
```

| Feld | Bedeutung |
|---|---|
| `id` | eindeutig, nur `a–z`, `0–9`, `_`; wird als Schlüssel gespeichert und darf sich nie ändern |
| `phase` | 1 bis 4 |
| `deadline.type` | `relative` (ab Sterbedatum) oder `from_knowledge` (ab Kenntnis, wird behelfsweise ab Sterbedatum gerechnet) |
| `deadline.unit` | `hours`, `days`, `business_days`, `months` |
| `deadline.amount` | Zahl; `days` wird als Kurzschreibweise akzeptiert |
| `deadline.strict` | `true` = gesetzliche oder vertragliche Frist, `false` = Empfehlung |
| `conditions` | innerhalb eines Feldes ODER, zwischen den Feldern UND; fehlt ein Feld, passt die Aufgabe immer |
| `priority` | Reihenfolge in der Phase, kleiner steht oben |

Mögliche Bedingungswerte: `placeOfDeath` = `home`, `hospital`, `care_home`,
`elsewhere` · `relationship` = `spouse`, `partner`, `child`, `parent`, `other` ·
`hasWill` und `hasFuneralProvision` = `yes`, `no`, `unknown`.

## Content prüfen

```bash
node Tools/validate_content.mjs
```

Das Skript prüft Schema, doppelte IDs, unbekannte Bedingungswerte und spielt
alle 180 Onboarding-Kombinationen durch, um leere Phasen zu finden. Ohne
Abhängigkeiten, läuft mit jedem Node ab Version 18.

## Bauen

Xcode 16 oder neuer, `Danach.xcodeproj` öffnen, Schema `Danach`, Simulator ab
iOS 17. Das Projekt nutzt synchronisierte Ordner: neue Dateien im Ordner
`Danach/` werden automatisch Teil des Targets.

## Rechtliches

Die Inhalte beruhen auf öffentlich zugänglichen Checklisten von Stiftung
Warentest, dem Bundesverband Deutscher Bestatter und den Verbraucherzentralen
sowie auf den einschlägigen Gesetzen (BGB, PStG, ErbStG, SGB VI). Bestattungs-
und Friedhofsrecht ist Landesrecht und unterscheidet sich je nach Bundesland;
die App weist an den betroffenen Stellen darauf hin.
