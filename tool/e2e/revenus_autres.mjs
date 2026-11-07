// REVENUS-VERITE point 5 « Autres revenus » (pilote, 06/11/2026) sur la pile
// LOCALE : la direction attribue une prime a l'enseignant, l'enseignant la voit.
//
// Donnees : l'enseignant et la direction amorces (amorcer.sh) ; la seance de
// tool/e2e/revenus_verite.mjs si elle existe (sinon le releve n'a que la
// prime). Les autres revenus E2E d'un passage precedent sont annules en SQL
// local (jamais effaces).
//
// Ce que le parcours prouve :
//   * a 1440 en francais, la direction ouvre le detail de la paie de
//     l'enseignant (Finance > Paie des enseignants), touche « Attribuer une
//     prime, une mission ou l'aide Internet », saisit « Prime E2E d'accueil »
//     et 15, confirme ; la base lit une ligne `prime` de 1500 ; la carte et
//     les lignes du calcul la montrent ;
//   * a 390 et 1440, en francais et en arabe : la direction voit la prime
//     dans le detail de paie, l'enseignant la voit dans « Mes revenus »,
//     section « Autres revenus », avec son montant et le total.
// Usage : node tool/e2e/revenus_autres.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, activerSemantique, trouver, trouverTexte, taper, saisir, sql, DEPOT, COMPTES, MDP } from './commun.mjs';

const p = await parcours('REVENUS-VERITE point 5 : la direction attribue une prime, l enseignant la voit', 'revenus-autres');
let code = 1;
const LANGUES = {
  fr: JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8')),
  ar: JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8')),
};
const sansIsolats = (s) => s.replace(/[\u2066-\u2069]/g, '').replace(/\u00a0/g, ' ');
const motif = (s) => new RegExp(sansIsolats(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/ /g, '[\\s\\u00a0]'), 'i');
const LIBELLE = "Prime E2E d'accueil";

// La connexion de commun.mjs cherche « J'ai deja un compte » en francais et
// rouvre la page : on touche le bouton dans la langue, puis on saisit.
async function entrer(page, courriel, T) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    for (const libelle of [T.inscription.questionnaire.dejaUnCompte, T.connexion.modeConnexion]) {
      const e = await trouver(page, sansIsolats(libelle), { delai: 6000, exact: true });
      if (e) { await e.click(); await page.waitForTimeout(1200); break; }
    }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
}

async function descendre(page, fois = 4, pas = 1200) {
  for (let i = 0; i < fois; i++) { await page.mouse.wheel(0, pas); await page.waitForTimeout(350); }
}

try {
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  if (!prof) throw new Error('comptes amorces absents : lancer tool/e2e/amorcer.sh');
  if (!sql(`select to_regclass('public.revenus_enseignant_autres')`)) {
    throw new Error('migration 20261110210000 absente de la pile locale');
  }
  sql(`update public.revenus_enseignant_autres set annule_le = now(),
         annule_par = (select id from auth.users where email = '${COMPTES.direction}')
       where enseignant_id = '${prof}' and libelle like '%E2E%' and annule_le is null`);
  const mois = sql(`select to_char(date_trunc('month', now() at time zone private.bf1_fuseau_comptable()), 'YYYY-MM-DD')`);
  const obligation = `${prof}_${mois}`;
  p.dire(`Enseignant ${prof} ; mois ${mois} ; obligation ${obligation}`);
  const verdicts = {};

  // 1. La direction attribue, a 1440 en francais.
  {
    const T = LANGUES.fr; const A = T.admin.finance.autres;
    const dir = await p.contexte('direction', { vue: { width: 1440, height: 1800 }, langue: 'fr-FR' });
    await entrer(dir.page, COMPTES.direction, T);
    await ouvrir(dir.page, `/#/admin/finance/paie/obligation/${obligation}`);
    await dir.page.waitForTimeout(2500); await activerSemantique(dir.page);
    const v = {};
    v.carte = Boolean(await trouverTexte(dir.page, motif(A.intro), 20000));
    await p.capture(dir, '1440_fr_1_detail_avant');
    const lien = await trouver(dir.page, motif(A.attribuer), { delai: 10000 });
    if (!lien) throw new Error('« Attribuer » absent du detail de paie');
    await lien.click(); await dir.page.waitForTimeout(1500);
    await saisir(dir.page, A.libelle, LIBELLE);
    await saisir(dir.page, sansIsolats(A.montant).replace('{devise}', 'USD'), '15');
    await dir.page.waitForTimeout(600);
    await p.capture(dir, '1440_fr_2_feuille');
    const confirmer = await trouver(dir.page, /Attribuer\s+15/, { delai: 8000 });
    if (!confirmer) throw new Error('bouton « Attribuer 15,00 $ » absent');
    await confirmer.click(); await dir.page.waitForTimeout(3500);
    v.base = sql(`select nature || ':' || montant_minor from public.revenus_enseignant_autres
                   where enseignant_id = '${prof}' and libelle = '${LIBELLE.replace("'", "''")}' and annule_le is null`);
    v.ligneDetail = Boolean(await trouverTexte(dir.page, motif(LIBELLE), 10000));
    await p.capture(dir, '1440_fr_3_detail_apres');
    await dir.ctx.close();
    p.dire(`attribution : ${JSON.stringify(v)}`);
    verdicts.attribution = v;
  }

  // 2. Ce que chacun voit, a 390 et 1440, en francais et en arabe.
  for (const langue of ['fr', 'ar']) {
    const T = LANGUES[langue];
    const locale = langue === 'ar' ? 'ar-SA' : 'fr-FR';
    for (const [largeur, hauteur] of [[390, 2600], [1440, 1800]]) {
      const cle = `${largeur}_${langue}`;
      const v = {};
      const dir = await p.contexte('direction', { vue: { width: largeur, height: hauteur }, langue: locale });
      await entrer(dir.page, COMPTES.direction, T);
      await ouvrir(dir.page, `/#/admin/finance/paie/obligation/${obligation}`);
      await dir.page.waitForTimeout(2500); await activerSemantique(dir.page);
      if (largeur === 390) await descendre(dir.page, 2);
      v.directionVoit = Boolean(await trouverTexte(dir.page, motif(LIBELLE), 15000));
      await p.capture(dir, `${cle}_4_detail_paie`);
      await dir.ctx.close();

      const ens = await p.contexte('enseignant', { vue: { width: largeur, height: hauteur }, langue: locale });
      await entrer(ens.page, COMPTES.enseignant, T);
      await ouvrir(ens.page, '/#/enseignant/revenus');
      await activerSemantique(ens.page);
      v.section = Boolean(await trouverTexte(ens.page, motif(T.enseignant.revenus.autresSection), 20000));
      await p.capture(ens, `${cle}_5_mes_revenus`);
      await descendre(ens.page, 3, largeur === 390 ? 1500 : 900);
      v.enseignantVoit = Boolean(await trouverTexte(ens.page, motif(LIBELLE), 10000));
      v.nature = Boolean(await trouverTexte(ens.page, motif(T.commun.autresRevenus.prime), 5000));
      v.montant = Boolean(await trouverTexte(ens.page, /(^|[^0-9,.])15([,.٫]00)?\s*\$|\$\s*15([,.٫]00)?([^0-9,.]|$)/, 5000));
      await p.capture(ens, `${cle}_6_autres_revenus`);
      await ens.ctx.close();
      p.dire(`${cle} : ${JSON.stringify(v)}`);
      verdicts[cle] = v;
    }
  }
  fs.writeFileSync(path.join(p.sortie, 'constats.json'), JSON.stringify(verdicts, null, 2));
  const a = verdicts.attribution;
  const rouges = [];
  if (!a.carte || a.base !== 'prime:1500' || !a.ligneDetail) rouges.push('attribution');
  for (const [k, v] of Object.entries(verdicts)) {
    if (k === 'attribution') continue;
    if (!v.directionVoit || !v.section || !v.enseignantVoit || !v.nature || !v.montant) rouges.push(k);
  }
  if (rouges.length) throw new Error(`rouge a ${rouges.join(', ')}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
