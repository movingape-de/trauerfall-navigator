// Erzeugt Screenshots im Format, das App Store Connect verlangt.
//
//   cd Tools && npm install playwright-core && cd ..
//   node Tools/preview/appstore.mjs
//
// Wichtig: Auf einem Mac ausführen. Dort rendert die Vorschau in SF Pro,
// also in derselben Schrift wie die App. Unter Linux springt eine
// Ersatzschrift ein, die etwas breiter läuft – brauchbar zum Beurteilen,
// aber nicht zum Hochladen.
//
// Diese Bilder stammen aus der Browser-Vorschau, nicht aus dem Simulator.
// Sobald der Build in Xcode läuft, gehören echte Simulator-Aufnahmen in den
// Store. Bis dahin sind das saubere Entwürfe im richtigen Format.

import { chromium } from 'playwright-core';
import { mkdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const PAGE = resolve(HERE, 'index.html');
const OUT = resolve(HERE, 'appstore');
mkdirSync(OUT, { recursive: true });

// Apple verlangt mindestens eine Größe; 6.9 Zoll deckt die aktuellen
// iPhone-Modelle ab. Die 6.5-Zoll-Größe bleibt für ältere Geräte nützlich.
const SIZES = [
  { name: '6.9-zoll', width: 1290, height: 2796 },
  { name: '6.5-zoll', width: 1242, height: 2688 },
];

// Bildunterschriften über dem Gerät. Apple erlaubt sie, und sie helfen:
// Die meisten Menschen lesen im Store nur die Screenshots.
const SHOTS = [
  { jump: 1, titel: 'Schritt für Schritt\ndurch die Formalitäten' },
  { jump: 4, titel: 'Fristen, die\nmitgerechnet werden' },
  { jump: 3, titel: 'Was zu tun ist,\nund welche Unterlagen' },
  { jump: 5, titel: 'Die Unterlagen-Mappe,\nzum Abhaken' },
  { jump: 0, titel: 'Alles bleibt\nauf Ihrem Gerät' },
];

const exe = (() => {
  try {
    return execSync("ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome 2>/dev/null | head -1",
      { encoding: 'utf8' }).trim() || undefined;
  } catch { return undefined; }
})();

const browser = await chromium.launch({
  executablePath: exe,
  args: ['--no-sandbox', '--force-color-profile=srgb'],
});

for (const size of SIZES) {
  // Das Gerät wird in einer Bühne montiert, die exakt der geforderten
  // Pixelgröße entspricht. Faktor 3 entspricht dem Raster des iPhone.
  const scale = 3;
  const css = { width: size.width / scale, height: size.height / scale };

  const context = await browser.newContext({
    viewport: { width: Math.round(css.width), height: Math.round(css.height) },
    deviceScaleFactor: scale,
    colorScheme: 'light',
    locale: 'de-DE',
  });
  const page = await context.newPage();
  await page.goto('file://' + PAGE);

  // Das Gerät behält seine echte Metrik von 392 Punkten Breite und wird
  // nur optisch skaliert. Würde man es stattdessen schmaler rechnen, bräche
  // das App-Layout um – die Screenshots zeigten dann etwas, das es so auf
  // keinem iPhone gibt.
  const deviceWidth = 392;
  const factor = (css.width * 0.76) / deviceWidth;

  await page.addStyleTag({ content: `
    body { background: #EFEBE4 !important; }
    .page, .intro, .rail, .legend { display: none !important; }
    #store {
      position: fixed; inset: 0;
      display: flex; flex-direction: column; align-items: center;
      padding: 5% 0 0;
      background: linear-gradient(180deg, #F6F3EE 0%, #E7E2D9 100%);
      font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
    }
    #store h2 {
      margin: 0 0 4%;
      font-size: 3.1vh;
      line-height: 1.22;
      font-weight: 600;
      letter-spacing: -0.02em;
      color: #2B333C;
      text-align: center;
      white-space: pre-line;
      max-width: 92%;
    }
    #store .buehne {
      width: 100%;
      display: flex;
      justify-content: center;
      overflow: hidden;
    }
    #store .device {
      width: ${deviceWidth}px;
      flex: 0 0 auto;
      border-radius: 54px;
      padding: 11px;
      transform: scale(${factor});
      transform-origin: top center;
      box-shadow: 0 40px 80px -30px rgba(43,51,60,0.45);
    }
    #store .screen { height: 806px; max-height: none; border-radius: 44px; }
  `});

  // Für die Aufnahmen wird das Produkt gezeigt, nicht die Bezahlschranke:
  // Vollversion aktiv, und ein paar Aufgaben sind abgehakt, damit der
  // Fortschrittsbalken nicht bei null steht.
  await page.evaluate(() => {
    document.getElementById('toggle-unlock').click();
    document.querySelector('[data-jump="2"]').click();
  });
  await page.waitForTimeout(200);
  // Jeweils frisch abfragen: Nach jedem Klick rendert die Liste neu.
  for (let i = 0; i < 3; i++) {
    await page.evaluate((n) => document.querySelectorAll('.check')[n]?.click(), i);
    await page.waitForTimeout(120);
  }

  for (const shot of SHOTS) {
    // Direkt im DOM auslösen: Die Bedienleiste ist für die Aufnahme
    // ausgeblendet und ließe sich nicht anklicken.
    await page.evaluate((i) => document.querySelector(`[data-jump="${i}"]`).click(), shot.jump);
    await page.waitForTimeout(260);

    await page.evaluate((titel) => {
      let wrap = document.getElementById('store');
      if (!wrap) {
        wrap = document.createElement('div');
        wrap.id = 'store';
        wrap.innerHTML = '<h2></h2><div class="buehne"></div>';
        wrap.querySelector('.buehne').appendChild(document.querySelector('.device'));
        document.body.appendChild(wrap);
      }
      wrap.querySelector('h2').textContent = titel;
    }, shot.titel);

    await page.waitForTimeout(160);
    const file = `${OUT}/${size.name}-${shot.jump}.png`;
    await page.screenshot({ path: file });
  }

  await context.close();
  console.log(`${size.name}: ${SHOTS.length} Bilder à ${size.width}×${size.height}`);
}

await browser.close();
