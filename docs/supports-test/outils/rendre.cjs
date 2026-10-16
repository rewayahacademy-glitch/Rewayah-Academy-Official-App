// Rend les HTML prepares par generer.py en PDF (A4) et en PNG (une image par
// page), avec le Chromium deja installe (PLAYWRIGHT_BROWSERS_PATH). Refuse
// toute page dont le contenu deborde : une page logique = une page imprimee,
// sinon la numerotation « p.N / l.M » ne correspondrait plus au papier.
// ECHANTILLON DE TEST - a relire avant usage reel.
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const travaux = JSON.parse(process.argv[2]);
  const navigateur = await chromium.launch();
  try {
    for (const t of travaux) {
      const page = await navigateur.newPage({ deviceScaleFactor: 2 });
      await page.goto('file://' + t.html);
      await page.evaluate(() => document.fonts.ready);
      const debordements = await page.$$eval('section.page', (pages) =>
        pages
          .map((p, i) => ({ i: i + 1, haut: p.scrollHeight, dispo: p.clientHeight }))
          .filter((x) => x.haut > x.dispo + 1));
      if (debordements.length) {
        throw new Error(`${t.id} : contenu qui deborde ${JSON.stringify(debordements)}`);
      }
      const polices = await page.evaluate(() =>
        [...document.fonts].map((f) => `${f.family}:${f.status}`));
      // « unloaded » = police declaree mais non employee sur ce support.
      if (polices.some((p) => p.endsWith(':error') || p.endsWith(':loading'))) {
        throw new Error(`${t.id} : police non chargee ${polices}`);
      }
      const pdf = path.join(t.sortie, `${t.id}.pdf`);
      await page.pdf({ path: pdf, format: 'A4', printBackground: true, preferCSSPageSize: true });
      const sections = await page.$$('section.page');
      if (sections.length !== t.pages) throw new Error(`${t.id} : nombre de pages`);
      for (let i = 0; i < sections.length; i++) {
        await sections[i].screenshot({ path: path.join(t.sortie, `${t.id}-p${i + 1}.png`) });
      }
      console.log(`${t.id} : ${pdf} et ${sections.length} PNG`);
      await page.close();
    }
  } finally {
    await navigateur.close();
  }
})().catch((err) => { console.error(String(err)); process.exit(1); });
