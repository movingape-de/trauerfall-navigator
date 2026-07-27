#!/usr/bin/env python3
"""
Prüft Danach.xcodeproj/project.pbxproj auf strukturelle Fehler, bevor Xcode
es zum ersten Mal öffnet: unbekannte Objekt-IDs, fehlende Pflichtabschnitte,
unausgeglichene Klammern.

    python3 Tools/check_project.py

Ersetzt keinen Xcode-Lauf, fängt aber alles ab, was Xcode mit
"The project file cannot be parsed" quittieren würde.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PBX = ROOT / "Danach.xcodeproj" / "project.pbxproj"
SCHEME = ROOT / "Danach.xcodeproj" / "xcshareddata" / "xcschemes" / "Danach.xcscheme"

errors = []
notes = []

text = PBX.read_text(encoding="utf-8")

# 1. Klammern
for opener, closer in [("{", "}"), ("(", ")")]:
    if text.count(opener) != text.count(closer):
        errors.append(
            f"Unausgeglichene Klammern {opener}{closer}: "
            f"{text.count(opener)} zu {text.count(closer)}"
        )

# 2. Definierte Objekte: 24-stellige Hex-ID am Zeilenanfang mit " = {"
defined = set(re.findall(r"^\t\t([0-9A-F]{24}) (?:/\*.*?\*/ )?= \{", text, re.M))

# 3. Alle referenzierten IDs
referenced = set(re.findall(r"\b([0-9A-F]{24})\b", text))

dangling = referenced - defined
if dangling:
    for oid in sorted(dangling):
        line = next((l.strip() for l in text.splitlines() if oid in l), "")
        errors.append(f"ID {oid} wird referenziert, aber nirgends definiert: {line[:70]}")

unused = defined - (referenced - defined)
# Jede Definition taucht mindestens einmal als Referenz auf (sich selbst),
# deshalb zählen wir Vorkommen statt Mengen.
for oid in sorted(defined):
    if text.count(oid) < 2:
        notes.append(f"Objekt {oid} wird nirgends referenziert")

# 4. Pflichtabschnitte
required = [
    "PBXProject",
    "PBXNativeTarget",
    "PBXFileReference",
    "PBXGroup",
    "PBXSourcesBuildPhase",
    "PBXResourcesBuildPhase",
    "PBXFrameworksBuildPhase",
    "XCBuildConfiguration",
    "XCConfigurationList",
    "PBXFileSystemSynchronizedRootGroup",
]
for section in required:
    if f"isa = {section};" not in text:
        errors.append(f"Abschnitt {section} fehlt")

# 5. rootObject muss definiert sein
root_match = re.search(r"rootObject = ([0-9A-F]{24})", text)
if not root_match:
    errors.append("rootObject fehlt")
elif root_match.group(1) not in defined:
    errors.append("rootObject verweist auf ein unbekanntes Objekt")

# 6. Der synchronisierte Ordner muss existieren
sync = re.search(r"isa = PBXFileSystemSynchronizedRootGroup; path = (\w+);", text)
if sync:
    folder = ROOT / sync.group(1)
    if not folder.is_dir():
        errors.append(f"Synchronisierter Ordner {sync.group(1)} existiert nicht")
    else:
        swift = list(folder.rglob("*.swift"))
        json_files = list(folder.rglob("*.json"))
        notes.append(f"Synchronisierter Ordner {sync.group(1)}: "
                     f"{len(swift)} Swift-Dateien, {len(json_files)} JSON-Dateien")

# 7. Schema
if not SCHEME.exists():
    errors.append("Geteiltes Schema fehlt")
else:
    scheme_text = SCHEME.read_text(encoding="utf-8")
    for oid in set(re.findall(r'BlueprintIdentifier = "([0-9A-F]{24})"', scheme_text)):
        if oid not in defined:
            errors.append(f"Schema verweist auf unbekanntes Target {oid}")
    ref = re.search(r'storeKitConfigurationFileReference = "([^"]+)"', scheme_text)
    if ref:
        # Pfad ist relativ zum Schema-Verzeichnis
        target = (SCHEME.parent / ref.group(1)).resolve()
        if not target.exists():
            errors.append(f"StoreKit-Konfiguration nicht gefunden: {target}")
        else:
            notes.append(f"StoreKit-Konfiguration verknüpft: {target.name}")

# 8. Content muss im synchronisierten Ordner liegen, sonst fehlt er im Bundle
for name in ("tasks_de.json", "documents_de.json"):
    if not (ROOT / "Danach" / "Content" / name).exists():
        errors.append(f"{name} liegt nicht in Danach/Content")

print("Danach – Projektdatei prüfen")
print("─" * 52)
print(f"Definierte Objekte: {len(defined)}")
for note in notes:
    print(f"  · {note}")

if errors:
    print(f"\nFehler ({len(errors)}):")
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)

print("\nStruktur in Ordnung.")
