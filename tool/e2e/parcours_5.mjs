// Parcours 5 : tenir la seance. L'enseignant (ordinateur) et le tuteur de
// l'enfant (telephone, « Rejoindre la salle avec … ») entrent dans la salle en
// meme temps ; chacun voit et entend l'autre (LiveKit local, camera et micro
// factices de Chromium) ; l'enseignant ouvre une page du Coran, l'eleve la voit,
// « Page suivante ».
// S'appuie sur la classe du parcours 2 et le compte famille du parcours 3, place
// au parcours 4. La salle s'ouvre 20 minutes avant l'heure : le script attend.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, cliquer, trouver, trouverTexte, libelles,
  sql, COMPTES, TRAVAIL } from './commun.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const p = await parcours('Parcours 5 : tenir la seance (Rejoindre, video, page du Coran)', 'parcours-5');

/// Les medias de la page, y compris dans les racines d'ombre (vues de plateforme).
async function medias(page) {
  return page.evaluate(() => {
    const vus = [];
    const parcourir = (racine) => {
      for (const e of racine.querySelectorAll('*')) {
        if (e.tagName === 'VIDEO' || e.tagName === 'AUDIO') {
          vus.push({ type: e.tagName.toLowerCase(), pret: e.readyState, l: e.videoWidth ?? 0,
            h: e.videoHeight ?? 0, pause: e.paused, local: !!e.muted });
        }
        if (e.shadowRoot) parcourir(e.shadowRoot);
      }
    };
    parcourir(document);
    return vus;
  });
}
const resume = (m) => m.map((x) => `${x.type}${x.l ? ` ${x.l}x${x.h}` : ''}${x.pause ? ' (pause)' : ''}`).join(', ') || 'aucun';

let code = 1;
try {
  const classe = lire('classe_parcours2.json');
  const { FAMILLE } = lire('comptes_parcours3.json');
  const debut = new Date(classe.debut);
  const seance = sql(`select s.id || '|' || s.started_at || '|' || s.ended_at from public.sessions s join public.groupes g on g.id = s.groupe_id
    where g.libelle = '${classe.nom}' and s.deleted_at is null and s.ended_at > now() order by s.started_at limit 1`);
  p.dire(`Classe « ${classe.nom} » ; seance ${seance}`);
  const [seanceId, , fin] = seance.split('|');
  if (Date.parse(fin) < Date.now() + 5 * 60000) throw new Error('la seance du parcours 2 se termine dans moins de 5 minutes : relancer les parcours 2 a 4');
  const ouverture = debut.getTime() - 20 * 60000;
  if (Date.now() < ouverture) {
    p.dire(`Attente de l'ouverture de la salle (${new Date(ouverture).toISOString()})`);
    await new Promise((r) => setTimeout(r, ouverture - Date.now() + 15000));
  }

  // 2. Enseignant : « Aujourd'hui », « Rejoindre la salle ».
  const e = await p.contexte('enseignant');
  await connecter(e.page, COMPTES.enseignant);
  await p.capture(e, 'aujourdhui');
  await cliquer(e.page, /^Rejoindre la salle/, { pause: 6000 });
  await p.capture(e, 'salle_entree');
  if (!e.page.url().includes('/salle')) throw new Error(`enseignant : « Rejoindre la salle » n'ouvre pas la salle (${e.page.url()}) ; ecran : ${(await libelles(e.page)).slice(0, 15).join(' | ')}`);
  await cliquer(e.page, /^Allumer la caméra/, { pause: 1500 });
  await cliquer(e.page, /^Ouvrir le micro/, { pause: 1500 });

  // 3. Tuteur, sur son propre Accueil : « Rejoindre la salle avec … ».
  const t = await p.contexte('tuteur', { telephone: true });
  await connecterParLien(t.page, FAMILLE.courriel);
  await p.capture(t, 'accueil');
  await cliquer(t.page, new RegExp(`^Rejoindre la salle avec ${FAMILLE.enfant}`), { pause: 6000 });
  await p.capture(t, 'salle_entree');
  const microTuteur = await trouver(t.page, /^Ouvrir le micro/, { delai: 5000 });
  if (microTuteur) { await microTuteur.click(); await t.page.waitForTimeout(1500); }

  // 4. Chacun voit et entend l'autre.
  await e.page.waitForTimeout(6000);
  const vuParEns = await trouverTexte(e.page, new RegExp(`fiche de ${FAMILLE.enfant}[^|]*`), 15000);
  const vuParTut = await trouverTexte(t.page, /Sayyid E2E Enseignant[^|]*/, 5000);
  const mEns = await medias(e.page);
  const mTut = await medias(t.page);
  p.dire(`Enseignant voit : « ${vuParEns} » ; medias : ${resume(mEns)}`);
  p.dire(`Tuteur voit : « ${vuParTut} » ; medias : ${resume(mTut)}`);
  await p.capture(e, 'salle_eleve_arrive');
  await p.capture(t, 'salle_enseignant_visible');
  const participants = sql(`select count(distinct profile_id) from public.session_participants where session_id = '${seanceId}'`);
  p.dire(`Base locale : ${participants} participant(s) enregistre(s) pour la seance`);
  const pasArrive = !vuParEns || /Pas encore connecté/.test(vuParEns);
  const sansImage = !vuParTut || /Sans image/.test(vuParTut);
  const videoTuteur = mTut.some((x) => x.type === 'video' && x.l > 0 && !x.local);
  if (pasArrive) throw new Error(`salle, enseignant : l'eleve n'apparait pas (« ${vuParEns} »)`);
  if (sansImage && !videoTuteur) throw new Error(`salle, tuteur : l'image de l'enseignant n'arrive pas (« ${vuParTut} » ; medias ${resume(mTut)})`);
  if (/Micro coupé/.test(vuParTut ?? '')) throw new Error(`salle, tuteur : le micro de l'enseignant apparait coupe (« ${vuParTut} »)`);

  // 5. Enseignant : la page du Coran ; l'eleve la voit ; « Page suivante ».
  const coran = await trouver(e.page, /^Ouvrir le Coran$/, { delai: 3000 })
    ?? await trouver(e.page, /^Coran, Mushaf de Médine/, { delai: 3000 });
  if (!coran) throw new Error(`enseignant : ni « Ouvrir le Coran » ni le Mushaf dans la Bibliothèque ; ecran : ${(await libelles(e.page)).slice(0, 25).join(' | ')}`);
  await coran.click();
  await e.page.waitForTimeout(4000);
  await p.capture(e, 'coran_ouvert');
  p.dire(`Enseignant apres Coran : ${(await libelles(e.page)).filter((x) => /page|sourate|présent/i.test(x)).slice(0, 8).join(' | ')}`);
  // Une sourate avant la derniere page : a la fin du Mushaf, la fleche
  // « suivante » disparait (regle NAV-FLECHES-1).
  const choisir = await trouver(e.page, /^Présenter le début d.Al-Kaafiroon/, { delai: 3000, role: 'button' })
    ?? await trouver(e.page, /^Présenter/, { delai: 3000, role: 'button' });
  if (choisir) { p.dire(`  geste : ${(await choisir.getAttribute('aria-label')) ?? ''}`); await choisir.click(); await e.page.waitForTimeout(3000); }
  await t.page.waitForTimeout(3000);
  await p.capture(t, 'coran_vu_par_eleve');
  const pageTut = await trouverTexte(t.page, /(Page \d+|Sourate|Al-Fatiha|Al-Baqara|page du Coran)[^|]*/i, 10000);
  p.dire(`Tuteur voit : « ${pageTut ?? '-'} »`);
  // « Page suivante » : les grandes fleches ne s'affichent que si elles tiennent
  // a cote de la page ; sinon la pagination est dans les commandes (« Plus »),
  // ou en mode Focus.
  const SUIV = /^(Page suivante|Présenter la page suivante)/;
  let suivante = await trouver(e.page, SUIV, { delai: 3000 });
  if (!suivante) {
    const plus = await trouver(e.page, /^Ouvrir les commandes de la bibliothèque/, { delai: 2000 });
    if (plus) { await plus.click(); await e.page.waitForTimeout(1500); await p.capture(e, 'commandes_plus'); }
    suivante = await trouver(e.page, SUIV, { delai: 3000 });
    if (suivante) p.dire('  ECART : sur ordinateur (1200 x 760), « Page suivante » n\'est pas a cote de la page : elle est dans « Plus »');
  }
  if (!suivante) {
    await e.page.keyboard.press('Escape');
    const focus = await trouver(e.page, /^Focus/, { delai: 2000 });
    if (focus) { await focus.click(); await e.page.waitForTimeout(1500); await p.capture(e, 'mode_focus'); }
    suivante = await trouver(e.page, SUIV, { delai: 3000 });
    if (suivante) p.dire('  ECART : sur ordinateur (1200 x 760), « Page suivante » n\'apparait qu\'en mode Focus');
  }
  if (!suivante) throw new Error(`enseignant : pas de « Page suivante » apres l'ouverture du Coran ; ecran : ${(await libelles(e.page)).slice(0, 30).join(' | ')}`);
  await suivante.click();
  await e.page.waitForTimeout(3000);
  await p.capture(e, 'page_suivante');
  await p.capture(t, 'page_suivante_vue');
  const pageTut2 = await trouverTexte(t.page, /(Page \d+|Sourate)[^|]*/i, 8000);
  p.dire(`Tuteur apres « Page suivante » : « ${pageTut2 ?? '-'} »`);
  if (!pageTut) throw new Error('eleve (tuteur) : la page du Coran ouverte par l\'enseignant ne s\'affiche pas (aucun libelle de page lu ; voir captures coran_vu_par_eleve)');
  if (pageTut2 === pageTut) throw new Error(`eleve (tuteur) : « Page suivante » ne change pas la page vue (« ${pageTut2} »)`);
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
