#!/usr/bin/env python3
"""
Erzeugt das App-Icon aus der Farbwelt der App.

    python3 -m pip install Pillow
    python3 Tools/make_appicon.py

Motiv: ein offener Ring in gedämpftem Salbeigrün auf warmem Off-White.
Die Öffnung zeigt nach oben – etwas, das nicht abgeschlossen ist, aber
auch nicht zerbrochen. Kein Kreuz, keine Kerze, kein Grabstein: Die App
soll auf dem Homescreen nicht wie eine Beerdigung aussehen, sondern wie
etwas, das man ohne Überwindung antippt.

Der Ring trägt bis hinunter zu 40 Pixeln Kantenlänge, wo eine gefüllte
Scheibe – das frühere Motiv – nur noch ein Punkt war.

Eine Horizontlinie ist vorgesehen, aber abgeschaltet: Sie verschwindet
beim Verkleinern lange bevor das Icon seine tatsächliche Größe erreicht,
und in voller Größe schneidet sie den Ring, statt ihn zu tragen. Wer sie
zurückholen will, setzt HORIZONT_Y auf einen Anteil der Bildhöhe –
0.635 schneidet den Ring, 0.782 legt sie knapp unter ihn.

Nur Pillow als Abhängigkeit.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # Supersampling für weiche Kanten

BG_TOP = (250, 248, 244)      # warmes Off-White
BG_BOTTOM = (241, 237, 230)
HORIZON = (214, 207, 195)
RING = (95, 127, 102)         # gedämpftes Salbeigrün, wie Palette.accent
# Auf dem Homescreen steht das Icon neben Watch und Fitness, die beide
# ebenfalls Ringe zeigen. Wem es dort zu leise ist: (72, 99, 79) mit
# RING_RADIUS 0.330 und RING_STRICH 0.068 trägt bei 60 Pixeln deutlich
# weiter, weicht dafür von der Akzentfarbe ins Dunklere ab.

HORIZONT_Y = None             # None = keine Linie, sonst Anteil der Höhe

# Lage und Stärke des Rings, jeweils als Anteil der Bildkante.
RING_MITTE_X = 0.485          # eine Spur nach links, das wirkt weniger starr
RING_MITTE_Y = 0.500
RING_RADIUS = 0.310
RING_STRICH = 0.062

# Pillow zählt Winkel im Uhrzeigersinn ab der Drei-Uhr-Position.
# Diese beiden lassen oben eine Lücke von gut achtzig Grad offen.
BOGEN_START = 313
BOGEN_ENDE = 591

OUT = Path(__file__).resolve().parent.parent / \
    "Danach/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"


def build() -> Image.Image:
    w = SIZE * SS
    image = Image.new("RGB", (w, w), BG_TOP)
    draw = ImageDraw.Draw(image)

    # Sehr sanfter senkrechter Verlauf
    for y in range(w):
        t = y / (w - 1)
        color = tuple(
            round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
        )
        draw.line([(0, y), (w, y)], fill=color)

    if HORIZONT_Y is not None:
        y = round(HORIZONT_Y * w)
        draw.line([(0, y), (w, y)], fill=HORIZON, width=max(1, round(0.006 * w)))

    mitte_x = round(RING_MITTE_X * w)
    mitte_y = round(RING_MITTE_Y * w)
    radius = round(RING_RADIUS * w)
    strich = round(RING_STRICH * w)

    draw.arc(
        [mitte_x - radius, mitte_y - radius,
         mitte_x + radius, mitte_y + radius],
        start=BOGEN_START,
        end=BOGEN_ENDE,
        fill=RING,
        width=strich,
    )

    # Pillow zeichnet Bögen stumpf ab. Die runden Enden setzen wir selbst.
    mittlerer_radius = radius - strich / 2
    ende_radius = strich / 2
    for winkel in (BOGEN_START, BOGEN_ENDE):
        bogen = math.radians(winkel)
        x = mitte_x + mittlerer_radius * math.cos(bogen)
        y = mitte_y + mittlerer_radius * math.sin(bogen)
        draw.ellipse(
            [x - ende_radius, y - ende_radius,
             x + ende_radius, y + ende_radius],
            fill=RING,
        )

    return image.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Ohne Alphakanal – Apple weist Icons mit Transparenz zurück.
    icon = build().convert("RGB")
    icon.save(OUT, "PNG", optimize=True)
    print(f"{OUT.relative_to(OUT.parents[4])}  {icon.size[0]}×{icon.size[1]}")
