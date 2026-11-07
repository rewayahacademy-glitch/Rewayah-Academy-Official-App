// FOYER-PARCOURS (directeur et garde-cap, 07/11/2026), banc LOCAL seulement.
// Une famille deja acceptee (la plus recente de parcours_3) :
//   1. le fuseau du foyer est pose a Africa/Dakar (SQL local) ;
//   2. le parcours de l'enfant s'ouvre ; la question du lieu montre « Dakar »
//      deja choisi, sans « Propose d'apres l'heure de votre appareil » ;
//   3. le parcours va jusqu'au bout (horaire choisi, ou demande enregistree) ;
//   4. Accueil, puis l'onglet Foyer : la LISTE des profils, jamais le
//      questionnaire ; la fiche de l'enfant s'ouvre ; un rechargement garde
//      la fiche ;
//   5. le parcours rouvert ne montre jamais la question 1.
// Usage : node tool/e2e/foyer_parcours.mjs [--bureau]   (pile.sh et parcours_3 d'abord)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, cliquer, libelles, attendreTexte, activerSemantique,
  amenerEnVue, connecterParLien, sql, DEPOT } from './commun.mjs';

const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const T = (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const souple = (s) => echapper(s).replace(/[\s  ]+/g, '\\s*');
const exact = (s) => new RegExp(`^\\s*${souple(s)}\\s*$`);
const bureau = process.argv.includes('--bureau');

const p = await parcours(`FOYER-PARCOURS : l'onglet Foyer, le parcours rouvert, le lieu du foyer (${bureau ? '1440' : '390'})`,
  `foyer-parcours/robot-${bureau ? '1440' : '390'}`);
const rouges = [];
function noter(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}${detail ? ` (${detail})` : ''}`);
  if (!ok) rouges.push(quoi);
}
const chemin = (page) => decodeURIComponent(new URL(page.url()).hash.replace(/^#/, ''));

let code = 1;
try {
  const ligne = sql(`select u.email || '|' || c.id || '|' || c.first_name || '|' || t.household_id
    from auth.users u join public.profiles t on t.id = u.id
    join public.profiles c on c.household_id = t.household_id and c.role = 'student'
    where u.email like 'e2e-famille-%' order by u.created_at desc limit 1`);
  if (!ligne) throw new Error('aucune famille de parcours_3 sur la pile : lancer parcours_3 d\'abord');
  const [courriel, eleveId, prenom, foyer] = ligne.split('|');
  sql(`update public.households set timezone = 'Africa/Dakar' where id = '${foyer}'`);
  p.dire(`Famille ${courriel}, enfant ${prenom} (${eleveId}), fuseau du foyer pose a Africa/Dakar`);

  const f = await p.contexte('famille', bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true });
  await connecterParLien(f.page, courriel);
  await ouvrir(f.page, `/#/tuteur/parcours/${eleveId}`);
  await f.page.waitForTimeout(2500); await activerSemantique(f.page);
  await p.capture(f, 'parcours_ouvert');
  // Un profil deja rempli s'ouvre sur les horaires : on revient au lieu par
  // « Retour », comme une famille qui veut corriger son lieu.
  for (let k = 0; k < 6 && !(await attendreTexte(f.page, new RegExp(souple(T('parcours.lieuQuestion'))), 800)); k++) {
    const r = await trouver(f.page, /^Retour$/, { delai: 1500 });
    p.dire(`  retour ${k} : ${r ? 'touche' : 'absent'} ; ${(await libelles(f.page)).slice(0, 4).join(' | ').slice(0, 160)}`);
    if (!r) break;
    await amenerEnVue(f.page, r); await r.click(); await f.page.waitForTimeout(1500); await activerSemantique(f.page);
  }

  // Le questionnaire, jusqu'au bout.
  let lieuVu = false;
  for (let k = 0; k < 12; k++) {
    await activerSemantique(f.page);
    const l = await libelles(f.page);
    const texte = l.join(' | ');
    if (/Préférence enregistrée|refusEnregistre/.test(texte) || await attendreTexte(f.page, new RegExp(souple(T('parcours.refusEnregistre'))), 500)) break;
    if (new RegExp(souple(T('parcours.lieuQuestion'))).test(texte)) {
      lieuVu = true;
      const dakar = f.page.getByRole('radio', { name: /Dakar/ });
      const choisi = (await dakar.count()) > 0 && (await dakar.first().getAttribute('aria-checked')) === 'true';
      noter(choisi, 'le lieu montre « Dakar » (fuseau du foyer) deja choisi', l.filter((x) => /radio:/.test(x)).slice(0, 3).join(' ; '));
      noter(!new RegExp(souple(T('parcours.lieuSuggere'))).test(texte), 'aucune valeur « proposee d\'apres l\'appareil » quand le foyer en a une');
      await p.capture(f, 'lieu_dakar_preselectionne');
      await cliquer(f.page, exact(T('commun.continuer')), { pause: 1500 });
      continue;
    }
    // Les horaires : un choix, sinon le signal.
    const choisir = await trouver(f.page, exact(T('parcours.offreChoisir')), { delai: 800 });
    const prevenir = await trouver(f.page, exact(T('parcours.refusPrevenir')), { delai: 800 });
    if (choisir || prevenir) {
      await p.capture(f, 'horaires');
      const e = choisir ?? prevenir;
      await amenerEnVue(f.page, e); await e.click(); await f.page.waitForTimeout(3000);
      await activerSemantique(f.page);
      p.dire(`  horaires : ${choisir ? 'un horaire choisi' : 'demande enregistree (aucun horaire ouvert)'}`);
      break;
    }
    // Une question a choix : la premiere reponse, puis Continuer.
    const cases = f.page.getByRole('radio');
    const coches = f.page.getByRole('checkbox');
    if (await cases.count()) { if (!(await f.page.locator('[role=radio][aria-checked=true]').count())) await cases.first().click(); }
    else if (await coches.count()) { if (!(await f.page.locator('[role=checkbox][aria-checked=true]').count())) await coches.first().click(); }
    await f.page.waitForTimeout(400);
    await cliquer(f.page, exact(T('commun.continuer')), { pause: 1500 });
  }
  noter(lieuVu, 'la question du lieu a ete posee');
  await p.capture(f, 'parcours_fini');

  // Accueil, puis l'onglet Foyer : la liste.
  await ouvrir(f.page, '/#/tuteur/accueil'); await f.page.waitForTimeout(2500); await activerSemantique(f.page);
  const onglet = await trouver(f.page, new RegExp(`^${souple(T('nav.tuteur.foyer'))}( Onglet.*)?$`), { delai: 6000 });
  noter(onglet !== null, 'l\'onglet Foyer est dans la barre');
  if (onglet) { await onglet.click(); await f.page.waitForTimeout(2500); await activerSemantique(f.page); }
  const surFoyer = chemin(f.page) === '/tuteur/foyer';
  const questionnaire = (await libelles(f.page)).some((x) => /\d+ sur \d+|Quel âge a/.test(x));
  noter(surFoyer && !questionnaire, 'l\'onglet Foyer ouvre la liste des profils, pas le questionnaire', chemin(f.page));
  await p.capture(f, 'onglet_foyer_liste');

  // La fiche de l'enfant, puis un rechargement.
  const carte = await trouver(f.page, new RegExp(`^${echapper(prenom)}`), { delai: 6000 });
  if (carte) { await amenerEnVue(f.page, carte); await carte.click(); await f.page.waitForTimeout(2500); }
  noter(chemin(f.page).startsWith(`/tuteur/foyer/${eleveId}`), 'la fiche de l\'enfant s\'ouvre', chemin(f.page));
  await p.capture(f, 'fiche');
  const avant = chemin(f.page);
  await f.page.reload(); await f.page.waitForTimeout(5000); await activerSemantique(f.page);
  noter(chemin(f.page) === avant, 'apres rechargement, la meme page', chemin(f.page));
  await p.capture(f, 'fiche_rechargee');

  // Le parcours rouvert : jamais la question 1.
  await ouvrir(f.page, `/#/tuteur/parcours/${eleveId}`); await f.page.waitForTimeout(3000); await activerSemantique(f.page);
  const rouvert = (await libelles(f.page)).join(' | ');
  noter(!/1 sur \d+/.test(rouvert) && !rouvert.includes('Quel âge a'), 'le parcours rouvert ne montre pas la question 1', rouvert.slice(0, 160));
  await p.capture(f, 'parcours_rouvert');

  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
