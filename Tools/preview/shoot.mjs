import { chromium } from 'playwright-core';
import { mkdirSync } from 'node:fs';
import { execSync } from 'node:child_process';

const PAGE = process.argv[2];
const OUT = process.argv[3];
mkdirSync(OUT, { recursive: true });

const exe = execSync("ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome 2>/dev/null | head -1",
  { encoding: 'utf8' }).trim();

const browser = await chromium.launch({
  executablePath: exe || undefined,
  args: ['--no-sandbox', '--force-color-profile=srgb', '--font-render-hinting=none'],
});

const SCREENS = [
  ['01-onboarding-willkommen', 0],
  ['02-onboarding-ort', 2],
  ['03-aufgaben', 1],
  ['04-phase', 2],
  ['05-aufgabe', 3],
  ['06-fristen', 4],
  ['07-unterlagen', 5],
  ['08-paywall', 6],
  ['09-mehr', 7],
];

for (const theme of ['light', 'dark']) {
  const context = await browser.newContext({
    viewport: { width: 1280, height: 1100 },
    deviceScaleFactor: 2,
    colorScheme: theme,
    locale: 'de-DE',
  });
  const page = await context.newPage();
  await page.goto('file://' + PAGE);
  await page.evaluate((t) => document.documentElement.setAttribute('data-theme', t), theme);
  await page.waitForTimeout(300);

  for (const [name, jumpIndex] of SCREENS) {
    await page.click(`[data-jump="${jumpIndex}"]`);
    await page.waitForTimeout(220);
    const screen = page.locator('.screen');
    await screen.screenshot({ path: `${OUT}/${theme}-${name}.png` });
  }

  // Dynamic Type auf Maximum, um das Layout unter Druck zu sehen
  await page.click('[data-jump="1"]');
  await page.evaluate(() => {
    const s = document.getElementById('scale');
    s.value = 170;
    s.dispatchEvent(new Event('input'));
  });
  await page.waitForTimeout(220);
  await page.locator('.screen').screenshot({ path: `${OUT}/${theme}-10-grossschrift.png` });

  await page.click('[data-jump="3"]');
  await page.waitForTimeout(220);
  await page.locator('.screen').screenshot({ path: `${OUT}/${theme}-11-grossschrift-detail.png` });

  await context.close();
}

await browser.close();
console.log('fertig');
