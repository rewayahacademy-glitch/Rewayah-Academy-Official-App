// Rend chaque .frame de explo.html en PNG à sa taille réelle.
const { chromium } = require('playwright');
const path = require('path');
const frames = require('./frames.json');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1400, height: 1000 }, deviceScaleFactor: 1 });
  await p.goto('file://' + path.join(__dirname, 'explo.html'));
  await p.evaluate(() => document.fonts.ready);
  await p.waitForTimeout(800);
  const only = process.argv[2];
  for (const [id] of frames) {
    if (only && !id.startsWith(only)) continue;
    await p.locator('#' + id).screenshot({ path: path.join(__dirname, 'out', id + '.png') });
  }
  await b.close();
})();
