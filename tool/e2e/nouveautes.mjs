// NOUVEAUTES (07/11/2026), banc LOCAL seulement (jamais un apercu, jamais la
// production). La preuve demandee par le garde-cap :
//   1. Le badge « Nouveau » est visible sur les points d'entree de chaque role
//      (tuteur : onglet Historique, ligne Couleur du profil, bouton Recharger ;
//      enseignant : Mes coordonnees de versement ; direction : Preparer le
//      fichier Wise du mois), lu « nouveau » par le lecteur d'ecran.
//   2. Il disparait a la premiere ouverture, et le serveur le retient
//      (public.nouveautes_vues).
//   3. Il reste absent sur un SECOND appareil (nouveau contexte de
//      navigateur, nouvelle session) pour ce qui a ete ouvert, et reste
//      present pour ce qui ne l'a pas ete.
// Usage : node tool/e2e/nouveautes.mjs [--bureau] [--arabe]
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, activerSemantique, amenerEnVue, connecter, libelles, sql,
  COMPTES, DEPOT } from './commun.mjs';

const bureau = process.argv.includes('--bureau');
const arabe = process.argv.includes('--arabe');
const fr = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const ar = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8'));
const lire = (o, cle) => cle.split('.').reduce((x, k) => x?.[k], o);
// Comme slang : une cle absente en arabe retombe sur le francais.
const T = (cle) => (arabe ? lire(ar, cle) : undefined) ?? lire(fr, cle);
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const souple = (s) => echapper(s).replace(/[\s  ]+/g, '\\s*');
const un = (q) => sql(q).split('\n')[0].trim();

const LU = T('nouveautes.lu');
const BADGE = T('nouveautes.badge');
const FAMILLE = JSON.parse(fs.readFileSync('/tmp/e2e-pile/comptes_parcours3.json', 'utf8')).FAMILLE.courriel;
const largeur = bureau ? '1440' : '390';
const p = await parcours(`NOUVEAUTES : le badge « Nouveau » (${largeur}, ${arabe ? 'AR' : 'FR'})`,
  `nouveautes/robot-${largeur}-${arabe ? 'ar' : 'fr'}`);
const rouges = [];
function noter(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}${detail ? ` (${detail})` : ''}`);
  if (!ok) rouges.push(quoi);
}
const options = () => ({ ...(bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true }),
  langue: arabe ? 'ar-SA' : 'fr-FR' });
const vue = (courriel, cle) => un(`select count(*) from public.nouveautes_vues v join auth.users u on u.id = v.profile_id
                                    where u.email = '${courriel}' and v.cle = '${cle}'`) === '1';
async function arbre(page) { return (await libelles(page)).join(' | '); }
// Le point d'entree, lu avec « nouveau » (ou sans, si `avec` est faux).
async function pointEntree(page, libelle, avec, delai = 12000) {
  const motif = avec
    ? new RegExp(`${souple(libelle)}.*${echapper(LU)}|${echapper(LU)}.*${souple(libelle)}`, 's')
    : new RegExp(`^\\s*${souple(libelle)}`);
  const e = await trouver(page, motif, { delai });
  if (!e || avec) return e;
  // Sans badge : le nom ne doit pas porter « nouveau ».
  const nom = (await e.getAttribute('aria-label')) ?? (await e.textContent()) ?? '';
  return nom.includes(LU) ? null : e;
}

let code = 1;
try {
  if (un(`select to_regclass('public.nouveautes')`) !== 'nouveautes') throw new Error('migration 20261114000000 absente de la pile');
  // Etat de depart : sortie il y a une heure, rien de vu pour les trois comptes.
  sql(`update public.nouveautes set sortie_le = now() - interval '1 hour'`);
  sql(`delete from public.nouveautes_vues v using auth.users u where u.id = v.profile_id
        and u.email in ('${FAMILLE}', '${COMPTES.enseignant}', '${COMPTES.direction}')`);
  const eleve = un(`select s.id from public.profiles s join public.profiles g on g.household_id = s.household_id
                      join auth.users u on u.id = g.id where u.email = '${FAMILLE}' and s.role = 'student' limit 1`);
  p.dire(`Tuteur ${FAMILLE}, eleve ${eleve}`);

  // 1. Tuteur, premier appareil.
  const a = await p.contexte('tuteur-appareil1', options());
  await connecter(a.page, FAMILLE);
  await ouvrir(a.page, '/#/tuteur'); await a.page.waitForTimeout(5000); await activerSemantique(a.page);
  const historique = T('nav.tuteur.historique');
  const onglet = await pointEntree(a.page, historique, true);
  noter(onglet !== null, `onglet « ${historique} » lu avec « ${LU} »`);
  noter((await a.page.getByText(BADGE, { exact: true }).count()) > 0 || (await arbre(a.page)).includes(LU), 'badge visible');
  await p.capture(a, 'onglet_historique_nouveau');

  await ouvrir(a.page, `/#/tuteur/foyer/${eleve}`); await a.page.waitForTimeout(4000); await activerSemantique(a.page);
  const couleur = T('ficheEleve.lignes.couleur');
  const ligne = await pointEntree(a.page, couleur, true);
  noter(ligne !== null, `ligne « ${couleur} » avec le badge`, ligne ? '' : (await arbre(a.page)).slice(0, 400));
  if (ligne) await amenerEnVue(a.page, ligne);
  await p.capture(a, 'fiche_couleur_nouveau');

  await ouvrir(a.page, `/#/tuteur/foyer/${eleve}/finances`); await a.page.waitForTimeout(4000); await activerSemantique(a.page);
  const recharger = T('foyer.finances.rechargerPour').split('{')[0].trim();
  const bouton = await pointEntree(a.page, recharger, true);
  noter(bouton !== null, `bouton « ${recharger}… » lu avec « ${LU} »`, bouton ? '' : (await arbre(a.page)).slice(0, 400));
  if (bouton) await amenerEnVue(a.page, bouton);
  await p.capture(a, 'finances_recharger_nouveau');

  // 2. Premiere ouverture de l'Historique : le badge part, le serveur retient.
  await ouvrir(a.page, '/#/tuteur'); await a.page.waitForTimeout(4000); await activerSemantique(a.page);
  const o2 = await pointEntree(a.page, historique, true);
  if (o2) { await o2.click(); await a.page.waitForTimeout(3000); }
  await activerSemantique(a.page);
  noter(vue(FAMILLE, 'historique_classe'), 'Historique marque vu par le serveur');
  noter(await pointEntree(a.page, historique, false, 6000) !== null, 'onglet sans badge apres ouverture');
  await p.capture(a, 'onglet_historique_ouvert');

  // 3. Second appareil : Historique sans badge ; Couleur, jamais ouverte, l'a encore.
  const b = await p.contexte('tuteur-appareil2', options());
  await connecter(b.page, FAMILLE);
  await ouvrir(b.page, '/#/tuteur'); await b.page.waitForTimeout(5000); await activerSemantique(b.page);
  noter(await pointEntree(b.page, historique, false) !== null, 'second appareil : onglet Historique sans badge');
  noter(await pointEntree(b.page, historique, true, 3000) === null, 'second appareil : aucun « nouveau » sur Historique');
  await p.capture(b, 'second_appareil_historique');
  await ouvrir(b.page, `/#/tuteur/foyer/${eleve}`); await b.page.waitForTimeout(4000); await activerSemantique(b.page);
  const ligneB = await pointEntree(b.page, couleur, true);
  noter(ligneB !== null, 'second appareil : Couleur, jamais ouverte, garde son badge');
  if (ligneB) { await amenerEnVue(b.page, ligneB); await ligneB.click(); await b.page.waitForTimeout(2500); }
  noter(vue(FAMILLE, 'couleur_profil'), 'Couleur marquee vue apres ouverture');
  // Retour au premier appareil, relu : plus de badge Couleur.
  await ouvrir(a.page, `/#/tuteur/foyer/${eleve}`); await a.page.reload(); await a.page.waitForTimeout(6000); await activerSemantique(a.page);
  noter(await pointEntree(a.page, couleur, true, 4000) === null, 'premier appareil relu : plus de badge sur Couleur');
  await p.capture(a, 'premier_appareil_couleur_relu');

  // 4. Enseignant.
  const e = await p.contexte('enseignant', options());
  await connecter(e.page, COMPTES.enseignant);
  await ouvrir(e.page, '/#/enseignant/profil'); await e.page.waitForTimeout(5000); await activerSemantique(e.page);
  const coord = T('comptable.beneficiaires.recevoir.titre');
  const le = await pointEntree(e.page, coord, true);
  noter(le !== null, `enseignant : « ${coord} » avec le badge`, le ? '' : (await arbre(e.page)).slice(0, 400));
  if (le) await amenerEnVue(e.page, le);
  await p.capture(e, 'profil_versement_nouveau');
  if (le) { await le.click(); await e.page.waitForTimeout(2500); }
  noter(vue(COMPTES.enseignant, 'recevoir_paiements'), 'enseignant : marque vu a l\'ouverture');

  // 5. Direction.
  const d = await p.contexte('direction', options());
  await connecter(d.page, COMPTES.direction);
  await ouvrir(d.page, '/#/admin/finance/paiements'); await d.page.waitForTimeout(5000); await activerSemantique(d.page);
  const wise = T('admin.finance.paieWise.exporter');
  const ld = await pointEntree(d.page, wise, true);
  noter(ld !== null, `direction : « ${wise} » avec le badge`, ld ? '' : (await arbre(d.page)).slice(0, 400));
  if (ld) await amenerEnVue(d.page, ld);
  await p.capture(d, 'paie_wise_nouveau');
  if (ld) { await ld.click(); await d.page.waitForTimeout(2500); }
  noter(vue(COMPTES.direction, 'export_wise'), 'direction : marque vu a l\'ouverture');
  // Une cle d'un autre role n'est jamais signalee a la direction.
  noter(!(await arbre(d.page)).includes(historique + ', ' + LU), 'direction : aucun badge du tuteur');

  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (err) {
  p.dire(String(err?.stack ?? err));
  code = await p.fin('rouge', String(err?.message ?? err).slice(0, 300));
}
process.exit(code);
