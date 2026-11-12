import { parcours, connecterParLien, ouvrir, trouver, COMPTES } from './commun.mjs';
const LIGNE = process.env.LIGNE ?? 'Identité professionnelle';
const p = await parcours('crash-gel', 'CRASH-MON-ESPACE/gel-' + LIGNE.replace(/[^A-Za-z]+/g, '_'));
const a = await p.contexte('compte', { telephone: true });
a.page.on('console', (m) => p.dire(`console ${m.type()} : ${m.text().slice(0, 400)}`));
a.page.on('framenavigated', (f) => { if (f === a.page.mainFrame()) p.dire(`navigation : ${f.url()}`); });
a.page.on('crash', () => p.dire('PAGE CRASH (onglet mort)'));
await connecterParLien(a.page, COMPTES.enseignant);
await ouvrir(a.page, '/enseignant/profil');
const e = await trouver(a.page, LIGNE);
await e.click({ noWaitAfter: true, timeout: 5000 }).catch((x) => p.dire('clic : ' + x.message.split('\n')[0]));
for (let i = 0; i < 6; i++) {
  const t0 = Date.now();
  const r = await Promise.race([a.page.evaluate(() => 'repond ' + location.href), new Promise((r) => setTimeout(() => r('PAS DE REPONSE en 5 s'), 5000))]);
  p.dire(`t+${i * 5}s : ${r} (${Date.now() - t0} ms)`);
}
await Promise.race([p.capture(a, 'apres'), new Promise((r) => setTimeout(r, 8000))]).catch(() => {});
process.exit(await Promise.race([p.fin('constat'), new Promise((r) => setTimeout(() => r(0), 8000))]));
