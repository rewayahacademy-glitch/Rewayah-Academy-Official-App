// Revue UX aux deux largeurs (telephone 390 x 780, ordinateur 1440 x 900) des
// ecrans des parcours, en commencant par la salle, la carte de classe et
// « Rejoindre ». Captures dans docs/current/captures/E2E/revue-ux/ ; le
// jugement (doublons, ecrans de telephone etires, deux volets a 840 et plus)
// est porte a la lecture des captures dans UX-CONSTATS.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, cliquer, trouver, allerOnglet, activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';

const p = await parcours('Revue UX aux deux largeurs', 'revue-ux');
const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const { FAMILLE, ADULTE } = lire('comptes_parcours3.json');
const LARGEURS = { telephone: { width: 390, height: 780 }, ordinateur: { width: 1440, height: 900 } };

/// Etendue horizontale du contenu (hors barre de navigation) : un ecran de
/// telephone etire se voit a une seule colonne tres large ou tres etroite.
async function etendue(page) {
  return page.evaluate(() => {
    const xs = [...document.querySelectorAll('flt-semantics[role=button], flt-semantics[role=heading], h2, a[aria-label]')]
      .map((e) => e.getBoundingClientRect()).filter((r) => r.width > 0 && r.x > 280);
    if (!xs.length) return null;
    const g = Math.min(...xs.map((r) => r.x)); const d = Math.max(...xs.map((r) => r.x + r.width));
    return { gauche: Math.round(g), droite: Math.round(d), largeur: Math.round(d - g) };
  });
}
async function vue(nom, role, largeur, aller) {
  try {
    const a = await p.contexte(`${role}-${largeur}`, { telephone: largeur === 'telephone' });
    await a.page.setViewportSize(LARGEURS[largeur]);
    await aller(a);
    await a.page.waitForTimeout(2500);
    await activerSemantique(a.page);
    await p.capture(a, `${nom}_${largeur}`);
    p.dire(`${nom} (${largeur}) : ${a.page.url()} ; etendue du contenu ${JSON.stringify(await etendue(a.page))}`);
    await a.ctx.close();
  } catch (e) { p.dire(`${nom} (${largeur}) : non capture (${String(e.message).slice(0, 160)})`); }
}

for (const l of ['ordinateur', 'telephone']) {
  await vue('famille_accueil', 'famille', l, async (a) => connecterParLien(a.page, FAMILLE.courriel));
  await vue('adulte_accueil', 'adulte', l, async (a) => connecterParLien(a.page, ADULTE.courriel));
  await vue('enseignant_aujourdhui', 'enseignant', l, async (a) => connecter(a.page, COMPTES.enseignant));
  await vue('enseignant_classes', 'enseignant', l, async (a) => { await connecter(a.page, COMPTES.enseignant); await allerOnglet(a.page, 'Classes', '/enseignant/classes', p.dire); });
  await vue('salle_enseignant', 'enseignant', l, async (a) => {
    await connecter(a.page, COMPTES.enseignant);
    const r = await trouver(a.page, /^Rejoindre la salle/, { delai: 8000 });
    if (r) { await r.click(); await a.page.waitForTimeout(7000); }
  });
  await vue('salle_tuteur', 'tuteur', l, async (a) => {
    await connecterParLien(a.page, FAMILLE.courriel);
    const r = await trouver(a.page, /^Rejoindre la salle avec/, { delai: 8000 });
    if (r) { await r.click(); await a.page.waitForTimeout(7000); }
  });
  await vue('direction_classes', 'direction', l, async (a) => {
    await connecter(a.page, COMPTES.direction);
    await a.page.evaluate(() => { location.hash = '#/admin/operations/classes'; });
  });
}
await p.fin('joué');
