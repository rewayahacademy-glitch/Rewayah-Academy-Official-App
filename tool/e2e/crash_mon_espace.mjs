// CRASH-MON-ESPACE (12/11/2026) : sur la pile LOCALE (vraie session, vrais
// adaptateurs Supabase), l'enseignant amorce ouvre chaque ligne de son Compte,
// au format telephone, puis se deconnecte (lien de connexion recu dans Mailpit :
// le mot de passe est coupe en production). Releve toute erreur de page.
// Donnees de test seulement.
import { parcours, connecterParLien, ouvrir, trouver, amenerEnVue, libelles, COMPTES } from './commun.mjs';

const LIGNES = (process.env.LIGNES ?? 'Identité professionnelle|Publication|disponibilités|revenus|Contrats|Informations personnelles|connexion|Langue|Thème').split('|');
const COMPTE = process.env.COMPTE ?? COMPTES.enseignant;
const ROUTE = process.env.ROUTE ?? '/enseignant/profil';

const p = await parcours('crash-mon-espace', process.env.DOSSIER ?? 'CRASH-MON-ESPACE/pile');
const a = await p.contexte('compte', { telephone: true });
const erreurs = [];
a.page.on('pageerror', (e) => erreurs.push(String(e.stack || e)));
await connecterParLien(a.page, COMPTE);
await p.capture(a, 'connecte');
p.dire(`apres connexion : ${a.page.url()}`);
for (const ligne of LIGNES) {
  await ouvrir(a.page, ROUTE);
  await p.capture(a, 'compte');
  // « A>B » : toucher A, puis B dans la page ouverte.
  const avant = erreurs.length;
  let trouve = true;
  for (const etape of ligne.split('>')) {
    const e = await trouver(a.page, etape, { delai: 15000 });
    if (!e) { p.dire(`INTROUVABLE « ${etape} » ; visibles : ${(await libelles(a.page)).slice(0, 40).join(' | ')}`); trouve = false; break; }
    await amenerEnVue(a.page, e);
    await e.click({ noWaitAfter: true });
    await a.page.waitForTimeout(4000);
    const r = await Promise.race([a.page.evaluate(() => 'ok'), new Promise((res) => setTimeout(() => res('GEL'), 5000))]);
    if (r === 'GEL') { p.dire(`GEL apres « ${etape} » : la page ne repond plus`); erreurs.push(`gel apres ${etape}`); await p.fin('rouge', 'gel'); process.exit(1); }
  }
  if (!trouve) continue;
  await p.capture(a, ligne.replace(/[^A-Za-z]+/g, '_'));
  p.dire(`« ${ligne} » -> ${a.page.url()} ; erreurs nouvelles : ${erreurs.length - avant} ; visibles : ${(await libelles(a.page)).slice(0, 12).join(' | ')}`);
}
await ouvrir(a.page, ROUTE);
for (const nom of ['Se déconnecter', 'Me déconnecter']) {
  const e = await trouver(a.page, nom, { delai: 15000 });
  if (!e) { p.dire(`INTROUVABLE « ${nom} »`); break; }
  await amenerEnVue(a.page, e);
  await e.click();
  await a.page.waitForTimeout(5000);
  await p.capture(a, nom.replace(/[^A-Za-z]+/g, '_'));
  p.dire(`« ${nom} » -> ${a.page.url()} ; visibles : ${(await libelles(a.page)).slice(0, 12).join(' | ')}`);
}
for (const e of erreurs) p.dire(`ERREUR DE PAGE : ${e.slice(0, 1500)}`);
process.exit(await p.fin(erreurs.length ? 'rouge' : 'vert', `${erreurs.length} erreur(s) de page`));
