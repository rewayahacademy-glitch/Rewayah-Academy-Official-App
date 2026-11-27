const { chromium } = require('playwright'); const path = require('path');
const frames = require('./affiches.json');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1200, height: 2000 }, deviceScaleFactor: 1 });
  await p.goto('file://' + path.join(__dirname, 'affiches.html'));
  await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(500);
  for (const id of frames) await p.locator('#' + id).screenshot({ path: path.join(__dirname, 'out', id + '.png') });
  await b.close();
})();
