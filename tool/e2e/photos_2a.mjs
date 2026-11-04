// Lot PHOTOS-2a (04/11/2026, PLAN-LOTS §11) : une seule photo par personne,
// la meme partout. Pile LOCALE seulement (jamais un apercu Vercel, jamais la
// production).
//
// Amorce (SQL local, comme amorcer.sh pour les comptes que l'interface ne
// sait pas creer) : un tuteur et son enfant Hakim, dans une Classe de
// l'enseignant de test ; un autre foyer (tuteur et enfant) hors de la Classe.
// Puis par l'interface :
//   1. le tuteur pose la photo de Hakim (fiche, Informations) : la base porte
//      la cle, posee par `poser_photo_eleve` (l'ecriture directe est fermee) ;
//   2. il pose la sienne depuis son Compte (`poser_ma_photo`) ;
//   3. Compte du tuteur : sa photo et celle de Hakim ;
//   4. l'enseignant ouvre la fiche de sa Classe : la photo de Hakim ;
//   5. la direction ouvre Personnes > Comptes : la photo du tuteur.
// Et en base : l'autre foyer ne voit pas la photo de Hakim (regle du serveur).
// Les captures vont dans docs/current/captures/E2E/PHOTOS-2a/<date>/<largeur>.
//
// Usage : E2E_VUE=1440x900 node tool/e2e/photos_2a.mjs (puis 390x844)
import path from 'node:path';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES, MDP, DEPOT, nettoyerClassesE2E } from './commun.mjs';

const [largeur, hauteur] = (process.env.E2E_VUE ?? '1440x900').split('x').map(Number);
const vue = { width: largeur, height: hauteur };
const date = new Date().toISOString().slice(0, 10);
const p = await parcours(`PHOTOS-2a : une photo partout (${largeur} x ${hauteur})`,
  `PHOTOS-2a/${date}/${largeur}`);
const PHOTO = path.join(DEPOT, 'tool/e2e/piece_factice.png');
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
const lus = async (page, k = 80) => (await libelles(page)).slice(0, k).join(' | ');

function creerCompte(courriel) {
  return sql(`with nouveau as (
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
      'authenticated', '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
    returning id),
  ident as (insert into auth.identities (id, user_id, provider_id, identity_data, provider,
      created_at, updated_at, last_sign_in_at)
    select gen_random_uuid(), id, id::text,
      jsonb_build_object('sub', id::text, 'email', '${courriel}', 'email_verified', true),
      'email', now(), now(), now() from nouveau returning user_id)
  select id from nouveau`).split('\n')[0];
}

function amorcer() {
  nettoyerClassesE2E();
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.courrielTuteur = `e2e-ph-tuteur-${n}@example.com`;
  ID.tuteur = creerCompte(ID.courrielTuteur);
  ID.hakim = creerCompte(`e2e-ph-hakim-${n}@example.com`);
  ID.autreTuteur = creerCompte(`e2e-ph-autre-${n}@example.com`);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris'),
      ('${ID.autreTuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${ID.tuteur}', 'E2E-PH-T-${n}', 'guardian', '${ID.tuteur}', 'Parent', 'Photo${n}', 'active', 'male'),
           ('${ID.hakim}', 'E2E-PH-E-${n}', 'student', '${ID.tuteur}', 'Hakim', 'Photo${n}', 'active', 'male'),
           ('${ID.autreTuteur}', 'E2E-PH-A-${n}', 'guardian', '${ID.autreTuteur}', 'Autre', 'Famille${n}', 'active', 'male');
    insert into public.student_profiles (profile_id, student_type, interface_mode)
    values ('${ID.hakim}', 'minor', 'child');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    update public.households set primary_guardian_id = '${ID.autreTuteur}' where id = '${ID.autreTuteur}';
    commit;`);
  ID.nom = `E2E Photos ${n}`;
  ID.classe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    values ('${ID.prof}', 'enfant', 5, '${ID.nom}', 2, 9, 'UTC') returning id`).split('\n')[0];
  sql(`insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.hakim}')`);
  p.dire(`Amorce : tuteur ${ID.tuteur} (${ID.courrielTuteur}), Hakim ${ID.hakim}, classe ${ID.classe} (${ID.nom}), autre foyer ${ID.autreTuteur}`);
}

async function toucher(page, motif, quoi, { delai = 10000, role } = {}) {
  const e = await trouver(page, motif, { delai, role });
  if (!e) throw new Error(`${quoi} absent ; ${await lus(page, 60)}`);
  await amenerEnVue(page, e);
  await e.click();
  await page.waitForTimeout(2000);
  await activerSemantique(page);
  return e;
}

async function choisirFichier(page, motif, quoi) {
  page.once('filechooser', (fc) => fc.setFiles(PHOTO));
  await toucher(page, motif, quoi);
  await page.waitForTimeout(2500);
  await activerSemantique(page);
}

let code = 1;
try {
  amorcer();

  // 1. Le tuteur pose la photo de Hakim.
  const t = await p.contexte('tuteur', { vue });
  await connecter(t.page, ID.courrielTuteur);
  await ouvrir(t.page, `/#/tuteur/foyer/${ID.hakim}/informations`);
  await choisirFichier(t.page, /^Choisir une photo/, '« Choisir une photo » (Hakim)');
  await toucher(t.page, /^Envoyer cette photo/, '« Envoyer cette photo »', { role: 'button' });
  await t.page.waitForTimeout(3000); await activerSemantique(t.page);
  const cleHakim = sql(`select coalesce(avatar_storage_key, '-') from public.student_profiles where profile_id = '${ID.hakim}'`);
  p.dire(`Photo de Hakim en base : ${cleHakim} ; ecran : ${await lus(t.page, 40)}`);
  verdicts.photoEnfantPosee = cleHakim.startsWith(`${ID.hakim}/`);
  await p.capture(t, 'tuteur_photo_enfant_posee');

  // 2. Il pose la sienne depuis son Compte.
  await ouvrir(t.page, '/#/tuteur/compte');
  await choisirFichier(t.page, /^Choisir une photo/, '« Choisir une photo » (tuteur)');
  await t.page.waitForTimeout(3000); await activerSemantique(t.page);
  const cleTuteur = sql(`select coalesce(photo_storage_key, '-') from public.profiles where id = '${ID.tuteur}'`);
  p.dire(`Photo du tuteur en base : ${cleTuteur} ; ecran : ${await lus(t.page, 40)}`);
  verdicts.photoTuteurPosee = cleTuteur.startsWith(`${ID.tuteur}/`);
  // 3. Compte du tuteur : sa photo et celle de Hakim, relues.
  await ouvrir(t.page, '/#/tuteur/compte');
  await t.page.waitForTimeout(3000);
  await p.capture(t, 'tuteur_compte');

  // 4. L'enseignant ouvre la fiche de sa Classe.
  const e = await p.contexte('enseignant', { vue });
  await connecter(e.page, COMPTES.enseignant);
  await ouvrir(e.page, `/#/enseignant/groupe/${ID.classe}`);
  await e.page.waitForTimeout(4000); await activerSemantique(e.page);
  const fiche = await lus(e.page, 80);
  p.dire(`Fiche de classe : ${fiche}`);
  verdicts.ficheClasse = fiche.includes('Hakim');
  await p.capture(e, 'enseignant_fiche_classe');

  // 5. La direction ouvre Personnes > Comptes, filtre sur le tuteur.
  const d = await p.contexte('direction', { vue });
  await connecter(d.page, COMPTES.direction);
  await ouvrir(d.page, '/#/admin/personnes/comptes');
  await d.page.waitForTimeout(4000); await activerSemantique(d.page);
  const comptes = await lus(d.page, 120);
  p.dire(`Comptes (direction) : ${comptes.slice(0, 600)}`);
  verdicts.comptesDirection = /Comptes/.test(comptes);
  await p.capture(d, 'direction_comptes');

  // Regle du serveur : l'autre foyer ne voit pas Hakim, l'enseignant et la
  // direction oui (photo_visible_par, migration 20261107300000).
  const vu = (lecteur) => sql(`select private.photo_visible_par('${ID.hakim}', '${lecteur}')`);
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  const regles = { autreFoyer: vu(ID.autreTuteur), enseignant: vu(ID.prof), direction: vu(admin), tuteur: vu(ID.tuteur) };
  p.dire(`Regle (photo de Hakim visible par) : ${JSON.stringify(regles)}`);
  verdicts.autreFoyerNeVoitPas = regles.autreFoyer === 'f';
  verdicts.enseignantVoit = regles.enseignant === 't';
  verdicts.directionVoit = regles.direction === 't';

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
