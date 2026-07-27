#!/usr/bin/env python3
"""
Erzeugt das App-Icon aus der Farbwelt der App.

    python3 Tools/make_appicon.py

Motiv: eine Sonne knapp über dem Horizont, in gedämpftem Salbeigrün auf
warmem Off-White. Kein Kreuz, kein Kerzenlicht, keine Trauerflor-Symbolik –
die App soll auf dem Homescreen nicht wie ein Grabstein aussehen, sondern
wie etwas, das man ohne Überwindung antippt.

Nur Pillow als Abhängigkeit:  python3 -m pip install Pillow
"""

from PIL import Image, ImageDraw
from pathlib import Path

SIZE = 1024
SS = 4  # Supersampling für weiche Kanten

BG_TOP = (250, 248, 244)      # warmes Off-White
BG_BOTTOM = (241, 237, 230)
HORIZON = (214, 207, 195)
SUN = (110, 139, 114)         # gedämpftes Salbeigrün
SUN_DARK = (95, 127, 102)

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

    horizon_y = int(w * 0.700)
    line_h = max(1, int(w * 0.009))
    margin = int(w * 0.170)

    # Sonne: sitzt auf der Linie auf, Radius so gewählt, dass das Motiv
    # auch bei 40 Punkten Kantenlänge noch als Form erkennbar bleibt.
    radius = int(w * 0.200)
    cx = w // 2
    cy = horizon_y - radius - int(line_h * 0.5)

    # Zarter Farbverlauf in der Sonne, damit sie nicht flach wirkt
    for i in range(radius, 0, -1):
        t = 1 - i / radius
        color = tuple(
            round(SUN[j] + (SUN_DARK[j] - SUN[j]) * t) for j in range(3)
        )
        draw.ellipse([cx - i, cy - i, cx + i, cy + i], fill=color)

    draw.rounded_rectangle(
        [margin, horizon_y, w - margin, horizon_y + line_h],
        radius=line_h // 2,
        fill=HORIZON,
    )

    return image.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    icon = build()
    icon.save(OUT, "PNG")
    print(f"{OUT.relative_to(OUT.parents[4])}  {icon.size[0]}×{icon.size[1]}")
