#!/usr/bin/env python3
"""
Baut die klickbare Browser-Vorschau, indem der echte Inhalt aus
Danach/Content in die Vorlage eingesetzt wird.

    python3 Tools/preview/build.py

Die Vorschau ist eine Einzeldatei ohne externe Abhängigkeiten und dient
dazu, Gestaltung, Tonfall und Ablauf zu beurteilen, ohne Xcode zu öffnen.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CONTENT = ROOT / "Danach" / "Content"
HERE = Path(__file__).resolve().parent

template = (HERE / "template.html").read_text(encoding="utf-8")

tasks = json.loads((CONTENT / "tasks_de.json").read_text(encoding="utf-8"))
docs = json.loads((CONTENT / "documents_de.json").read_text(encoding="utf-8"))

out = template.replace("/*__TASKS__*/", json.dumps(tasks, ensure_ascii=False))
out = out.replace("/*__DOCS__*/", json.dumps(docs, ensure_ascii=False))

target = HERE / "index.html"
target.write_text(out, encoding="utf-8")
print(f"{target.relative_to(ROOT)}  {len(out) // 1024} KB  "
      f"({len(tasks['tasks'])} Aufgaben, {len(docs['documents'])} Unterlagen)")
