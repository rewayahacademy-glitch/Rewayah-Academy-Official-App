// AUTRE-PROFIL-ELEVE (12/11/2026) : sur la pile LOCALE, le titulaire qui suit
// lui-meme des cours touche « Utiliser un autre appareil » sur l'accueil du
// tuteur. Releve la page ouverte et la reponse de creer_code_appairage.
// Donnees de test seulement.
import { parcours, connecterParLien, ouvrir, trouver, libelles } from './commun.mjs';
const COMPTE = process.env.COMPTE ?? 'e2e-adulte@example.com';
const p = await parcours('autre-profil-eleve', process.env.DOSSIER ?? 'AUTRE-PROFIL-ELEVE/avant');
const a = await p.contexte('titulaire', { telephone: true });
let appels = 0;
a.page.on('console', (m) => { if (m.text().includes('TRACE-APE')) p.dire(m.text()); });
a.page.on('response', async (r) => {
  if (r.url().includes('/rpc/creer_code_appairage')) {
    appels += 1;
    let corps = ''; try { corps = (await r.text()).slice(0, 300); } catch {}
    p.dire(`RPC creer_code_appairage : HTTP ${r.status()} ; corps ${corps.replace(/"code":"[A-Z0-9]{6}"/, '"code":"<masque>"')}`);
  }
});
await connecterParLien(a.page, COMPTE);
p.dire(`apres connexion : ${a.page.url()}`);
await ouvrir(a.page, process.env.ROUTE ?? '/tuteur');
await a.page.waitForTimeout(3000);
await p.capture(a, 'accueil');
p.dire(`accueil : ${a.page.url()} ; visibles : ${(await libelles(a.page)).slice(0, 30).join(' | ')}`);
if (process.env.DIRECT) {
  p.dire(`lien « Utiliser un autre appareil » visible : ${!!(await trouver(a.page, /Utiliser un autre appareil/, { delai: 4000 }))}`);
  await ouvrir(a.page, process.env.DIRECT);
} else {
  const lien = await trouver(a.page, /Utiliser un autre appareil/, { delai: 10000 });
  if (!lien) { p.dire('lien « Utiliser un autre appareil » absent'); process.exit(await p.fin('constat', 'lien absent')); }
  await lien.click();
}
await a.page.waitForTimeout(5000);
await p.capture(a, 'apres_lien');
p.dire(`apres le lien : ${a.page.url()} ; visibles : ${(await libelles(a.page)).slice(0, 20).join(' | ')}`);
p.dire(`appels a creer_code_appairage : ${appels}`);
process.exit(await p.fin('constat'));
