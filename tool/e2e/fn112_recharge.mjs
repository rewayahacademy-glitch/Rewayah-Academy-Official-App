// FN-112, troisieme essai : rechargement de /#/eleve/adulte juste apres la connexion,
// sans renouvellement de jeton. Puis meme essai pour le tuteur sur son Accueil.
import fs from 'node:fs';
import { parcours, connecterParLien, libelles, activerSemantique, TRAVAIL } from './commun.mjs';
const { ADULTE, FAMILLE } = JSON.parse(fs.readFileSync(TRAVAIL + '/comptes_parcours3.json', 'utf8'));
const p = await parcours('FN-112 : rechargement simple', 'constats/FN-112-rechargement');
for (const [nom, courriel] of [['adulte', ADULTE.courriel], ['tuteur', FAMILLE.courriel]]) {
  const a = await p.contexte(nom, { telephone: true });
  await connecterParLien(a.page, courriel);
  await a.page.waitForTimeout(3000);
  const avant = a.page.url();
  await a.page.reload(); await a.page.waitForTimeout(8000); await activerSemantique(a.page);
  await p.capture(a, `${nom}_apres_rechargement`);
  p.dire(`${nom} : ${avant} puis rechargement : ${a.page.url()} ; ${(await libelles(a.page)).slice(0, 2).join(' | ')}`);
  const retour = await (await import('./commun.mjs')).trouver(a.page, /^Retour à l'accueil/, { delai: 2000 });
  if (retour) { await retour.click(); await a.page.waitForTimeout(6000); await activerSemantique(a.page); await p.capture(a, `${nom}_apres_retour_accueil`); p.dire(`${nom} : apres « Retour à l'accueil » : ${a.page.url()} ; ${(await libelles(a.page)).slice(0, 2).join(' | ')}`); }
  await a.ctx.close();
}
await p.fin('joué');
