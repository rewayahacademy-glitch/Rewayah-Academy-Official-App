// MESURE-FLUIDITE : temps d'image (intervalles requestAnimationFrame) pendant un
// defilement complet de Personnes > Comptes, 1440 x 900, release web, pile LOCALE.
// Usage : E2E_APP=http://127.0.0.1:8091 E2E_TRAVAIL=<dossier> node tool/e2e/mesure_fluidite.mjs [essais]
// Donnees de test seulement (comptes mesure-N@test.invalid).
import { parcours, connecter, ouvrir, activerSemantique, COMPTES } from './commun.mjs';

const essais = Number(process.argv[2] ?? 3);
const p = await parcours('MESURE-FLUIDITE', 'selection-texte/mesure-brut');
const sortie = [];
for (let e = 1; e <= essais; e++) {
  const a = await p.contexte('direction', { vue: { width: 1440, height: 900 } });
  const page = a.page;
  await connecter(page, COMPTES.direction);
  await ouvrir(page, '/admin/personnes/comptes');
  await page.waitForTimeout(4000);
  await activerSemantique(page);
  // La taille de page la plus grande proposee (100) si elle est atteignable.
  await page.mouse.move(720, 500);
  for (let i = 0; i < 40; i++) { await page.mouse.wheel(0, 400); await page.waitForTimeout(30); }
  await page.waitForTimeout(800);
  let cent = false;
  const t25 = page.getByRole('button', { name: /Lignes par page/ }).first();
  await t25.waitFor({ state: 'attached', timeout: 20000 }).catch(() => {});
  await t25.click({ force: true }).catch(() => {});
  const o = page.getByRole('menuitem', { name: /100 par page/ }).first();
  if (await o.waitFor({ state: 'attached', timeout: 8000 }).then(() => true).catch(() => false)) {
    await o.click({ force: true }).catch(() => {}); await page.waitForTimeout(3500); cent = true;
  }
  for (let i = 0; i < 400; i++) { await page.mouse.wheel(0, -400); if (i % 20 === 0) await page.waitForTimeout(20); }
  await page.waitForTimeout(1500);
  const rangees = await page.locator("flt-semantics").filter({ hasText: /Identifiant :/ }).count();
  await page.evaluate(() => {
    window.__ints = []; window.__long = 0; let last = performance.now();
    const f = (t) => { window.__ints.push(t - last); last = t; if (!window.__stop) requestAnimationFrame(f); };
    requestAnimationFrame(f);
    try { new PerformanceObserver((l) => { window.__long += l.getEntries().length; }).observe({ entryTypes: ['longtask'] }); } catch {}
  });
  await page.mouse.move(720, 500);
  const t0 = Date.now();
  for (let i = 0; i < 160; i++) { await page.mouse.wheel(0, 120); await page.waitForTimeout(16); }
  await page.waitForTimeout(500);
  for (let i = 0; i < 160; i++) { await page.mouse.wheel(0, -120); await page.waitForTimeout(16); }
  await page.waitForTimeout(500);
  const dur = Date.now() - t0;
  const r = await page.evaluate(() => {
    window.__stop = true;
    const a = window.__ints.slice(5).filter((x) => x < 200).sort((x, y) => x - y); const n = a.length;
    return { n, moy: +(a.reduce((s, x) => s + x, 0) / n).toFixed(2), p90: +a[Math.floor(n * .9)].toFixed(2),
      p99: +a[Math.floor(n * .99)].toFixed(2), max: +a[n - 1].toFixed(2), longues: window.__long,
      sup33: a.filter((x) => x > 33.4).length, sup50: a.filter((x) => x > 50).length };
  });
  const lignes = (await page.locator('flt-semantics').count());
  sortie.push({ essai: e, cent, rangees, noeudsSemantiques: lignes, dureeMs: dur, ...r });
  await a.ctx.close();
}
console.log('RESULTAT ' + JSON.stringify(sortie));
process.exit(await p.fin('vert'));
