#!/usr/bin/env python3
"""
Erzeugt das App-Icon aus der Farbwelt der App.

    python3 -m pip install Pillow
    python3 Tools/make_appicon.py

Motiv: ein Blatt als Umriss in gedämpftem Salbeigrün auf warmem
Off-White – welliger Oberrand, Spitze nach rechts unten, geschwungene
Mittelrippe, auslaufender Stiel. Dasselbe Zeichen begrüßt die Nutzer im
Onboarding; Icon und App führen bewusst dieselbe Bildmarke.

Kein Kreuz, keine Kerze, kein Grabstein: Die App soll auf dem Homescreen
nicht wie eine Beerdigung aussehen, sondern wie etwas, das man ohne
Überwindung antippt.

Bewusst eine eigene Zeichnung und nicht das SF Symbol "leaf": Apples
Lizenz erlaubt die Symbole in der Oberfläche, nicht aber in App-Icons
und Logos. In der App selbst darf das Symbol bleiben.

Die Striche entstehen, indem Kreise dicht an dicht entlang der
Bézier-Kurven gesetzt werden. Pillows Linienzug mit `joint="curve"`
franst an den Rundungen sichtbar aus; gestempelte Kreise geben runde
Enden und saubere Kanten geschenkt.

Nur Pillow als Abhängigkeit.
"""

from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # Supersampling für weiche Kanten

BG_TOP = (250, 248, 244)      # warmes Off-White
BG_BOTTOM = (241, 237, 230)
LEAF = (95, 127, 102)         # gedämpftes Salbeigrün, wie Palette.accent

STRICH = 0.052                # Strichstärke als Anteil der Bildkante

# Alle Stützpunkte als Anteil der Bildkante, jede Zeile eine kubische
# Bézier-Kurve: Anfang, zwei Griffe, Ende.
KONTUR = [
    ((0.150, 0.200), (0.230, 0.330), (0.400, 0.330), (0.560, 0.285)),
    ((0.560, 0.285), (0.720, 0.240), (0.860, 0.330), (0.865, 0.520)),
    ((0.865, 0.520), (0.870, 0.640), (0.800, 0.700), (0.720, 0.720)),
    ((0.720, 0.720), (0.560, 0.775), (0.330, 0.720), (0.230, 0.560)),
    ((0.230, 0.560), (0.150, 0.430), (0.148, 0.300), (0.150, 0.200)),
]
RIPPE = [((0.330, 0.395), (0.430, 0.560), (0.620, 0.585), (0.800, 0.660))]
STIEL = [((0.800, 0.660), (0.845, 0.720), (0.870, 0.800), (0.878, 0.870))]

OUT = Path(__file__).resolve().parent.parent / \
    "Danach/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"


def bezier(p0, p1, p2, p3, schritte: int = 260):
    punkte = []
    for i in range(schritte + 1):
        t = i / schritte
        u = 1 - t
        punkte.append((
            u * u * u * p0[0] + 3 * u * u * t * p1[0]
            + 3 * u * t * t * p2[0] + t * t * t * p3[0],
            u * u * u * p0[1] + 3 * u * u * t * p1[1]
            + 3 * u * t * t * p2[1] + t * t * t * p3[1],
        ))
    return punkte


def build() -> Image.Image:
    w = SIZE * SS
    ebene = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw = ImageDraw.Draw(ebene)

    radius = STRICH * w / 2
    for gruppe in (KONTUR, RIPPE, STIEL):
        for segment in gruppe:
            for x, y in bezier(*segment):
                draw.ellipse(
                    [x * w - radius, y * w - radius,
                     x * w + radius, y * w + radius],
                    fill=LEAF,
                )

    image = Image.new("RGB", (w, w), BG_TOP)
    grund = ImageDraw.Draw(image)
    for y in range(w):
        t = y / (w - 1)
        color = tuple(
            round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
        )
        grund.line([(0, y), (w, y)], fill=color)

    image.paste(ebene, (0, 0), ebene)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Ohne Alphakanal – Apple weist Icons mit Transparenz zurück.
    icon = build().convert("RGB")
    icon.save(OUT, "PNG", optimize=True)
    print(f"{OUT.relative_to(OUT.parents[4])}  {icon.size[0]}×{icon.size[1]}")
