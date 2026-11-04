// PR 127 (FN-112, second defaut) : l'eleve adulte qui recharge sa page
// d'accueil reste sur son accueil, jamais « Vous n'avez pas accès à cette
// page ». Usage : node tool/e2e/fn112_rechargement_adulte.mjs
// Prerequis : le parcours 3 a cree l'adulte et la famille
// (comptes_parcours3.json). Pile LOCALE seulement.
// Temoin : le tuteur qui recharge son Accueil y reste aussi.
import fs from 'node:fs';
import { parcours, connecterParLien, libelles, activerSemantique, trouverTexte,
  TRAVAIL } from './commun.mjs';

const { ADULTE, FAMILLE } = JSON.parse(fs.readFileSync(TRAVAIL + '/comptes_parcours3.json', 'utf8'));
const p = await parcours('FN-112 : l eleve adulte recharge sa page et reste sur son accueil',
  'fn112-rechargement-adulte');
const REFUS = /Vous n'avez pas accès à cette page/;
const manque = [];

const a = await p.contexte('adulte', { telephone: true });
await connecterParLien(a.page, ADULTE.courriel);
await a.page.waitForTimeout(4000); await activerSemantique(a.page);
await p.capture(a, 'adulte_avant_rechargement');
const avant = a.page.url();
p.dire(`adulte avant : ${avant} ; ${(await libelles(a.page)).slice(0, 3).join(' | ')}`);
if (!/#\/eleve\/adulte/.test(avant)) manque.push(`adulte pas sur son accueil avant le rechargement (${avant})`);
for (const n of [1, 2]) {
  await a.page.reload(); await a.page.waitForTimeout(9000); await activerSemantique(a.page);
  await p.capture(a, `adulte_apres_rechargement_${n}`);
  const url = a.page.url();
  const refus = await trouverTexte(a.page, REFUS, 1500);
  const bonjour = await trouverTexte(a.page, /^Bonjour/, 3000);
  p.dire(`adulte, rechargement ${n} : ${url} ; ${bonjour ?? (await libelles(a.page)).slice(0, 3).join(' | ')}`);
  if (refus || /acces-refuse/.test(url)) manque.push(`rechargement ${n} : « accès refusé »`);
  if (!/#\/eleve\/adulte/.test(url) || !bonjour) manque.push(`rechargement ${n} : pas sur l accueil adulte (${url})`);
}
await a.ctx.close();

const f = await p.contexte('tuteur', { telephone: true });
await connecterParLien(f.page, FAMILLE.courriel);
await f.page.waitForTimeout(4000);
const avantTuteur = f.page.url();
await f.page.reload(); await f.page.waitForTimeout(9000); await activerSemantique(f.page);
await p.capture(f, 'tuteur_apres_rechargement');
const urlTuteur = f.page.url();
p.dire(`tuteur : ${avantTuteur} puis rechargement : ${urlTuteur} ; ${(await libelles(f.page)).slice(0, 3).join(' | ')}`);
if (urlTuteur !== avantTuteur || (await trouverTexte(f.page, REFUS, 1500))) manque.push('tuteur : rechargement hors de son accueil');
await f.ctx.close();

process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'l adulte recharge deux fois et reste sur son accueil ; le tuteur aussi'));
