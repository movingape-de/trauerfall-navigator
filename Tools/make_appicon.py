#!/usr/bin/env python3
"""
Erzeugt das App-Icon aus der Farbwelt der App.

    python3 -m pip install Pillow
    python3 Tools/make_appicon.py

Motiv: ein Blatt in gedämpftem Salbeigrün auf warmem Off-White, um
fünfundvierzig Grad gestellt. Dasselbe Zeichen begrüßt die Nutzer im
Onboarding – Icon und App führen bewusst dieselbe Bildmarke.

Kein Kreuz, keine Kerze, kein Grabstein: Die App soll auf dem Homescreen
nicht wie eine Beerdigung aussehen, sondern wie etwas, das man ohne
Überwindung antippt.

Der Umriss entsteht aus einer Kurve, die an der Basis breit ansetzt und
zur Spitze ausläuft; die Mittelrippe ist ausgespart statt aufgemalt,
damit sie beim Verkleinern zuerst verschwindet und nicht verschmiert.
Ein reiner Umriss statt der Fläche wurde verworfen: Er franst an den
Rundungen aus und ist bei sechzig Pixeln nicht mehr zu lesen.

Nur Pillow als Abhängigkeit.
"""

from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # Supersampling für weiche Kanten

BG_TOP = (250, 248, 244)      # warmes Off-White
BG_BOTTOM = (241, 237, 230)
LEAF = (95, 127, 102)         # gedämpftes Salbeigrün, wie Palette.accent

# Alle Maße als Anteil der Bildkante.
BLATT_LAENGE = 0.80
BLATT_BREITE = 0.215
RIPPE_STAERKE = 0.036
NEIGUNG = 45                  # Grad gegen den Uhrzeigersinn

# Exponenten der Umrisskurve. Der kleinere Wert sitzt an der Basis und
# hält sie breit, der größere lässt die Spitze auslaufen. Vertauscht man
# beide, steht das Blatt auf dem Kopf.
E_BASIS = 0.62
E_SPITZE = 1.05

OUT = Path(__file__).resolve().parent.parent / \
    "Danach/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"


def umriss(mitte: float, laenge: float, breite: float, punkte: int = 500):
    """Halbe Kontur oben, halbe unten – zusammen ein geschlossenes Blatt."""
    oben, unten = [], []
    for i in range(punkte + 1):
        t = -1 + 2 * i / punkte          # -1 Basis, +1 Spitze
        w = (1 + t) ** E_BASIS * (1 - t) ** E_SPITZE
        y = breite * w / 1.05
        x = laenge * t / 2
        oben.append((mitte + x, mitte - y))
        unten.append((mitte + x, mitte + y))
    return oben + unten[::-1]


def build() -> Image.Image:
    w = SIZE * SS
    mitte = w / 2

    blatt = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw = ImageDraw.Draw(blatt)
    laenge = BLATT_LAENGE * w
    draw.polygon(umriss(mitte, laenge, BLATT_BREITE * w), fill=LEAF)

    # Mittelrippe: aus der Fläche geschnitten, nicht daraufgesetzt.
    draw.line(
        [(mitte - laenge / 2, mitte), (mitte + laenge / 2, mitte)],
        fill=(0, 0, 0, 0),
        width=round(RIPPE_STAERKE * w),
    )

    blatt = blatt.rotate(NEIGUNG, resample=Image.BICUBIC, center=(mitte, mitte))

    image = Image.new("RGB", (w, w), BG_TOP)
    grund = ImageDraw.Draw(image)
    for y in range(w):
        t = y / (w - 1)
        color = tuple(
            round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
        )
        grund.line([(0, y), (w, y)], fill=color)

    image.paste(blatt, (0, 0), blatt)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Ohne Alphakanal – Apple weist Icons mit Transparenz zurück.
    icon = build().convert("RGB")
    icon.save(OUT, "PNG", optimize=True)
    print(f"{OUT.relative_to(OUT.parents[4])}  {icon.size[0]}×{icon.size[1]}")
