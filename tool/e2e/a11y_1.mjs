// Lot A11Y-1 (rang 13 de PLAN-LOTS, 06/11/2026) : preuve dans l'arbre
// d'accessibilite du navigateur (Flutter web), sur la pile locale.
//
// - UX-021 : tuteur, « Connecter un appareil » quand un code est deja
//   valable : « Générer un nouveau code » a son propre noeud, role bouton.
// - UX-027 : appareil de l'enfant, « Choisis ton code personnel » puis
//   « Entre-le encore une fois » : chaque touche est un bouton nomme, et la
//   grille ne change pas de place entre les deux ecrans.
// - UX-004 (diagnostic seulement, composant du lot 3) : les onglets de la
//   barre de l'enseignant a 1440 sont-ils dans l'arbre ?
//
// Les mots viennent des fichiers de traduction : le meme script tourne en
// francais et en arabe. Prerequis : pile.sh, amorcer.sh, et une famille
// avec un enfant : celle du parcours 3 (comptes_parcours3.json), ou celle que
// nomment E2E_A11Y_TUTEUR et E2E_A11Y_ENFANT (comptes crees en SQL local).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, connecter, activerSemantique, libelles, taper,
  sql, COMPTES, TRAVAIL, DEPOT } from './commun.mjs';

const i18n = (l) => JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${l}.i18n.json`), 'utf8'));
const LANGUES = [['fr', 'fr-FR'], ['ar', 'ar-SA']];
const TELEPHONE = { width: 390, height: 844 };
const BUREAU = { width: 1440, height: 900 };
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const exact = (s) => new RegExp(`^\\s*${echapper(s)}\\s*$`);

const p = await parcours('A11Y-1 : noeuds d\'accessibilite (UX-021, UX-027, UX-004)', 'a11y-1');
const ecarts = [];
const constater = (ok, quoi) => { p.dire(`  ${ok ? 'OK' : 'ECART'} : ${quoi}`); if (!ok) ecarts.push(quoi); };
let code = 1;

/// Les boutons visibles qui portent exactement ce nom.
async function boutons(page, nom) {
  const l = page.getByRole('button', { name: exact(nom) });
  const vus = [];
  for (let i = 0; i < await l.count(); i++) if (await l.nth(i).isVisible().catch(() => false)) vus.push(l.nth(i));
  return vus;
}

async function attendreTexte(page, motif, delai = 15000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    await activerSemantique(page);
    const t = (await libelles(page)).find((x) => motif.test(x));
    if (t) return t;
    await page.waitForTimeout(800);
  }
  return null;
}

/// La session du tuteur (stockage local de l'origine de l'application),
/// posee avant le premier script de la page.
async function reprendreSession(ctx, fichier) {
  const etat = JSON.parse(fs.readFileSync(fichier, 'utf8'));
  await ctx.addCookies(etat.cookies ?? []);
  for (const o of etat.origins ?? []) {
    await ctx.addInitScript(({ origine, items }) => {
      if (location.origin !== origine) return;
      for (const { name, value } of items) if (localStorage.getItem(name) === null) localStorage.setItem(name, value);
    }, { origine: o.origin, items: o.localStorage });
  }
}

async function deuxTailles(acteur, etiquette) {
  await acteur.page.setViewportSize(TELEPHONE); await acteur.page.waitForTimeout(1500);
  await activerSemantique(acteur.page);
  await p.capture(acteur, `${etiquette}_390`);
  await acteur.page.setViewportSize(BUREAU); await acteur.page.waitForTimeout(1500);
  await activerSemantique(acteur.page);
  await p.capture(acteur, `${etiquette}_1440`);
  await acteur.page.setViewportSize(TELEPHONE); await acteur.page.waitForTimeout(1500);
  await activerSemantique(acteur.page);
}

try {
  const FAMILLE = process.env.E2E_A11Y_TUTEUR
    ? { courriel: process.env.E2E_A11Y_TUTEUR, enfant: process.env.E2E_A11Y_ENFANT }
    : JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8')).FAMILLE;
  const eleveId = sql(`select p.id from public.profiles p where p.first_name = '${FAMILLE.enfant}' and p.role = 'student' order by p.created_at desc limit 1`);
  if (!eleveId) throw new Error(`enfant ${FAMILLE.enfant} introuvable`);
  p.dire(`Famille ${FAMILLE.courriel}, enfant ${FAMILLE.enfant} (${eleveId})`);
  // Chaque langue relie un appareil : on part d'un enfant sans appareil actif
  // (base LOCALE), sinon le passage suivant bute sur la limite d'appareils.
  sql(`update public.devices set revoked_at = now() where profile_id = '${eleveId}' and revoked_at is null`);

  // Une connexion en francais, reprise par les contextes de chaque langue.
  const amorce = await p.contexte('amorce', { telephone: true });
  await connecter(amorce.page, FAMILLE.courriel);
  const etatTuteur = path.join(TRAVAIL, 'a11y1_tuteur.json');
  await amorce.ctx.storageState({ path: etatTuteur });
  await amorce.ctx.close();

  for (const [l, langue] of LANGUES) {
    const m = i18n(l);
    p.dire(`== ${l}`);
    // --- UX-021 : le tuteur. Deux passages : le second trouve le code du
    // premier encore valable.
    const t = await p.contexte(`tuteur_${l}`, { telephone: true, langue });
    const tCtx = t.ctx;
    await reprendreSession(tCtx, etatTuteur);
    await ouvrir(t.page, `/#/tuteur/foyer/appairer/${eleveId}`);
    await t.page.waitForTimeout(4000);
    await ouvrir(t.page, '/#/tuteur/foyer');
    await ouvrir(t.page, `/#/tuteur/foyer/appairer/${eleveId}`);
    const deja = await attendreTexte(t.page, new RegExp(echapper(m.appareils.emetteur.dejaActif.titre)));
    constater(!!deja, `${l} : l'ecran « ${m.appareils.emetteur.dejaActif.titre} » s'affiche au second passage`);
    if (deja) {
      const b = await boutons(t.page, m.appareils.regenerer);
      constater(b.length === 1, `${l} UX-021 : un noeud bouton nomme exactement « ${m.appareils.regenerer} » (${b.length} trouve)`);
      const fondu = (await libelles(t.page)).filter((x) => x.includes(m.appareils.regenerer) && x.includes(m.appareils.emetteur.dejaActif.titre));
      constater(fondu.length === 0, `${l} UX-021 : le bouton n'est plus fondu avec le titre (${fondu.length} noeud mele)`);
      await deuxTailles(t, 'code_deja_valable');
      if (b[0]) { await b[0].click(); await t.page.waitForTimeout(4000); }
    }
    await activerSemantique(t.page);
    const vu = (await libelles(t.page)).join(' | ').match(/\b([A-Z0-9](?: ?[A-Z0-9]){5})\b/);
    const codeAppareil = vu?.[1].replace(/\s/g, '');
    constater(!!codeAppareil, `${l} : un nouveau code est affiche (${codeAppareil ?? '-'})`);
    await deuxTailles(t, 'nouveau_code');

    // --- UX-027 : l'appareil de l'enfant.
    if (codeAppareil) {
      const e = await p.contexte(`enfant_${l}`, { telephone: true, langue });
      const eCtx = e.ctx;
      await ouvrir(e.page, '/#/connexion/eleve/code');
      await taper(e.page, 'input, textarea', codeAppareil);
      const valider = await boutons(e.page, m.eleveConnexion.saisie.valider);
      if (valider[0]) { await valider[0].click(); await e.page.waitForTimeout(6000); }
      const positions = [];
      for (const [cle, ecran] of [['creer', 'code_personnel_choisir'], ['confirmer', 'code_personnel_confirmer']]) {
        const titre = await attendreTexte(e.page, new RegExp(echapper(m.eleveConnexion.pin[cle])));
        constater(!!titre, `${l} : ecran « ${m.eleveConnexion.pin[cle]} »`);
        if (!titre) break;
        const noms = [];
        let uniques = 0;
        for (const c of '0123456789') {
          const b = e.page.getByRole('button', { name: new RegExp(`^\\s*${c}(\\s+${c})?\\s*$`) });
          if (!(await b.count())) continue;
          const nom = ((await b.first().getAttribute('aria-label')) ?? (await b.first().textContent()) ?? '').trim();
          noms.push(JSON.stringify(nom));
          if (nom === c) uniques += 1;
        }
        constater(noms.length === 10, `${l} UX-027 : ${noms.length} touches sur 10 sont des boutons nommes`);
        constater(uniques === 10, `${l} UX-027 : ${uniques} touches sur 10 lues une seule fois ; noms lus : ${noms.join(' ')}`);
        const deux = e.page.getByRole('button', { name: /^\s*2(\s+2)?\s*$/ }).first();
        positions.push((await deux.boundingBox())?.y ?? null);
        await deuxTailles(e, ecran);
        for (const c of '2580') { await e.page.getByRole('button', { name: new RegExp(`^\\s*${c}(\\s+${c})?\\s*$`) }).first().click(); await e.page.waitForTimeout(350); }
        await e.page.waitForTimeout(2500);
      }
      constater(positions.length === 2 && positions[0] === positions[1],
        `${l} UX-027 : la touche « 2 » reste a la meme hauteur entre les deux ecrans (${positions.join(' -> ')})`);
      await eCtx.close();
    }
    await tCtx.close();
  }

  // --- UX-004, diagnostic pour le lot 3 : la barre de l'enseignant a 1440.
  const ens = await p.contexte('enseignant', { vue: BUREAU });
  await connecter(ens.page, COMPTES.enseignant);
  await activerSemantique(ens.page);
  const nav = [];
  for (const nom of ["Aujourd'hui", 'Classes', 'Disponibilités', 'Profil']) {
    nav.push(`${nom}=${(await boutons(ens.page, nom)).length + await ens.page.getByRole('tab', { name: exact(nom) }).count()}`);
  }
  p.dire(`  DIAGNOSTIC UX-004 (lot 3, non corrige ici) : onglets de l'enseignant dans l'arbre a 1440 : ${nav.join(', ')}`);
  await p.capture(ens, 'enseignant_barre_1440');
  await ens.ctx.close();

  code = await p.fin(ecarts.length ? 'rouge' : 'vert', ecarts.join(' ; '));
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
