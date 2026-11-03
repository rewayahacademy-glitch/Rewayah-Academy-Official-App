// D1-bis (03/11/2026) : la direction traite un signalement d'enseignant,
// sur la pile LOCALE, par l'interface.
//
// Ce que le parcours prouve, a l'ecran ET en base :
//   1. (1440, clair) l'enseignant ecrit un signalement « Pedagogique » depuis
//      la fiche d'un eleve ; la direction l'ouvre dans ses alertes, l'examine,
//      ecrit le message pour la famille, le transmet (seconde confirmation),
//      le clot sans motif (facultatif hors securite), et il sort de la file ;
//   2. (390, sombre) un signalement « Securite d'un enfant » : ni message ni
//      transmission ; « Clore » sans motif dit ce qui manque et rien ne part ;
//      avec le motif, il est clos et sort de la file ;
//   3. (1440, sombre, arabe) un troisieme signalement examine puis clos.
// Chaque geste ecrit le journal (audit_logs) : verifie en base.
//
// Prerequis : la migration 20261106200000_d1bis_traiter_signalement.sql
// appliquee sur la pile LOCALE, comptes amorces (tool/e2e/amorcer.sh).
// Donnees : un foyer, un enfant et une Classe neufs a chaque passage ; rien
// n'est efface. Usage : node tool/e2e/d1bis_signalement.mjs
import { parcours, trouver, activerSemantique, amenerEnVue, taper,
  saisir, connecter, attendreTexte, cliquer, nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs';

const p = await parcours('D1-bis : traiter un signalement', 'd1-bis');
const n = Date.now() % 1000000;
const BUREAU = { vue: { width: 1440, height: 900 } };
const TEL = { vue: { width: 390, height: 844 } };
const courrielTuteur = `e2e-d1b-tuteur-${n}@example.com`;
const NOTE1 = `Yasmine ne suit plus la lecture depuis deux séances (${n}).`;
const NOTE2 = `Yasmine semble inquiète en arrivant en classe (${n}).`;
const NOTE3 = `Connexion coupée trois fois pendant la séance (${n}).`;
const MESSAGE = 'Nous reprendrons la lecture avec Yasmine cette semaine.';
const MOTIF = 'Pris en charge par la direction avec la famille.';
const ID = {};

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

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

/// Un matricule au format du 12/10 (RA-26-xxxx), libre sur la pile.
function matriculeLibre() {
  for (;;) {
    const m = `RA-26-${1000 + Math.floor(Math.random() * 9000)}`;
    if (sql(`select count(*) from public.profiles where immutable_id = '${m}'`) === '0') return m;
  }
}

/// Un foyer, son tuteur, une enfant (mineure) dans une Classe neuve de
/// l'enseignant amorce. SQL LOCAL : l'inscription n'est pas l'objet du lot.
function amorcer() {
  nettoyerClassesE2E();
  // Les signalements laisses ouverts par un passage interrompu de ce
  // parcours sont clos (pile LOCALE seulement) : la file ne montre que ceux
  // de ce passage. Rien n'est efface.
  sql(`update public.student_concern set statut = 'clos'
        where statut <> 'clos' and internal_details ~ '^(Yasmine ne suit plus la lecture|Yasmine semble inquiète|Connexion coupée trois fois)'`);
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.tuteur = creerCompte(courrielTuteur);
  ID.eleve = sql('select gen_random_uuid()');
  ID.foyer = sql('select gen_random_uuid()');
  ID.classe = sql('select gen_random_uuid()');
  ID.matricule = matriculeLibre();
  sql(`begin;
    insert into auth.users (id, email) values ('${ID.eleve}', 'e2e-d1b-eleve-${n}@example.com');
    insert into public.households (id, timezone) values ('${ID.foyer}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', '${matriculeLibre()}', 'guardian', '${ID.foyer}', 'Samira', 'Tuteur', 'active', 'female'),
      ('${ID.eleve}', '${ID.matricule}', 'student', '${ID.foyer}', 'Yasmine', 'Eleve', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.foyer}';
    insert into public.student_profiles (profile_id, student_type, interface_mode)
      values ('${ID.eleve}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, 'E2E D1-bis An-Nour ${n}', 6, 21);
    insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.eleve}');
    commit;`);
  p.dire(`  amorce : classe ${ID.classe}, eleve ${ID.matricule}`);
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(3500);
  await activerSemantique(page);
}

async function montrer(acteur, texte, etiquette) {
  const e = await trouver(acteur.page, texte, { delai: 15000 });
  if (e) await amenerEnVue(acteur.page, e);
  await acteur.page.waitForTimeout(600);
  return p.capture(acteur, etiquette);
}

const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/// L'enseignant depose un signalement depuis la fiche de l'eleve.
async function deposer(prof, categorie, note) {
  await vers(prof.page, `/enseignant/groupe/${ID.classe}`);
  await cliquer(prof.page, /Yasmine/, { pause: 2500 });
  await cliquer(prof.page, /^Signaler un besoin$/, { pause: 2500 });
  await cliquer(prof.page, categorie, { pause: 1000 });
  await taper(prof.page, 'textarea', note);
  await cliquer(prof.page, /^Envoyer le signalement$/, { pause: 3000 });
  verifier(await attendreTexte(prof.page, "Signalement transmis à l'administration.", 15000),
    `enseignant : signalement envoye (${note.slice(0, 30)}...)`);
  const id = sql(`select id from public.student_concern where internal_details = '${note.replace(/'/g, "''")}'`);
  verifier(/^[0-9a-f-]{36}$/.test(id), 'base : signalement enregistre (student_concern)');
  // La feuille de l'enseignant reste ouverte apres l'envoi : on la ferme,
  // puis la fiche de l'eleve, pour le signalement suivant.
  await cliquer(prof.page, /Fermer$/, { pause: 1500 });
  await prof.page.keyboard.press('Escape');
  await prof.page.waitForTimeout(1200);
  return id;
}

const statut = (id) => sql(`select statut from public.student_concern where id = '${id}'`);
const journal = (id, action) => sql(`select count(*) from public.audit_logs
  where table_name = 'student_concern' and row_id = '${id}' and action = '${action}'`);

let code = 1;
try {
  amorcer();
  const prof = await p.contexte('enseignant', BUREAU);
  await connecter(prof.page, COMPTES.enseignant);

  // --- 1. Pedagogique, 1440 clair : examiner, transmettre, clore ---------
  p.dire('-- 1. pedagogique, 1440 clair');
  ID.s1 = await deposer(prof, /^Problème pédagogique$/, NOTE1);
  const dir = await p.contexte('direction', BUREAU);
  await connecter(dir.page, COMPTES.direction);
  await vers(dir.page, '/admin/alertes');
  verifier(await attendreTexte(dir.page, NOTE1, 30000), 'direction : le signalement est dans les alertes');
  await montrer(dir, NOTE1, '1440_clair_1_file');
  await cliquer(dir.page, new RegExp(echapper(NOTE1.slice(0, 40))), { pause: 1800 });
  verifier(await attendreTexte(dir.page, 'Traiter le signalement', 10000), 'direction : la feuille s ouvre');
  verifier(await attendreTexte(dir.page, 'À examiner', 5000), 'feuille : « À examiner »');
  await p.capture(dir, '1440_clair_2_feuille');

  await cliquer(dir.page, /^Examiner$/, { pause: 2500 });
  verifier(await attendreTexte(dir.page, 'Signalement en examen', 10000), 'feuille : « Signalement en examen »');
  verifier(statut(ID.s1) === 'en_examen', 'base : statut en_examen');
  verifier(journal(ID.s1, 'student_concern_en_examen') === '1', 'base : journal de l examen');
  await p.capture(dir, '1440_clair_3_en_examen');

  await saisir(dir.page, 'Message pour la famille', MESSAGE);
  await cliquer(dir.page, /^Transmettre$/, { pause: 1500 });
  verifier(await attendreTexte(dir.page, /Transmettre ce message au tuteur de l.élève/, 8000), 'seconde confirmation de la transmission');
  await p.capture(dir, '1440_clair_4_confirmer_transmission');
  await cliquer(dir.page, /^Oui, transmettre$/, { pause: 3000 });
  verifier(await attendreTexte(dir.page, 'Message enregistré', 10000), 'feuille : « Message enregistré »');
  verifier(sql(`select statut || '|' || family_summary || '|' || transmis_a from public.student_concern where id = '${ID.s1}'`)
    === `transmis|${MESSAGE}|tuteur_du_mineur`, 'base : transmis au tuteur avec le message ecrit par la direction');
  verifier(journal(ID.s1, 'student_concern_resume_redige') === '1' && journal(ID.s1, 'student_concern_transmis') === '1',
    'base : journal du message et de la transmission');
  await p.capture(dir, '1440_clair_5_transmis');

  await cliquer(dir.page, /^Clore$/, { pause: 1500 });
  verifier(await attendreTexte(dir.page, 'Clore ce signalement', 8000), 'seconde confirmation de la cloture');
  await p.capture(dir, '1440_clair_6_confirmer_cloture');
  await cliquer(dir.page, /^Oui, clore$/, { pause: 3000 });
  verifier(await attendreTexte(dir.page, 'Signalement clos', 10000), 'feuille : « Signalement clos »');
  verifier(statut(ID.s1) === 'clos', 'base : statut clos');
  verifier(journal(ID.s1, 'student_concern_clos') === '1', 'base : journal de la cloture');
  await p.capture(dir, '1440_clair_7_clos');
  await cliquer(dir.page, /^Fermer$/, { pause: 2000 });
  verifier(!(await attendreTexte(dir.page, NOTE1, 3000)), 'direction : le signalement clos est sorti de la file');
  await p.capture(dir, '1440_clair_8_sorti_de_la_file');

  // --- 2. Securite d'un enfant, 390 sombre : motif exige ------------------
  p.dire('-- 2. securite d un enfant, 390 sombre');
  ID.s2 = await deposer(prof, /Sécurité d.un enfant/, NOTE2);
  const dirTel = await p.contexte('direction', { ...TEL, sombre: true });
  await connecter(dirTel.page, COMPTES.direction);
  await vers(dirTel.page, '/admin/alertes');
  verifier(await attendreTexte(dirTel.page, NOTE2, 30000), 'direction (390) : la securite d un enfant est dans les alertes');
  await montrer(dirTel, NOTE2, '390_sombre_1_file');
  await cliquer(dirTel.page, new RegExp(echapper(NOTE2.slice(0, 40))), { pause: 1800 });
  verifier(await attendreTexte(dirTel.page, /Ni la famille ni l.enseignant ne lisent ce signalement/, 10000),
    'feuille : la securite d un enfant ne se transmet pas');
  verifier(!(await trouver(dirTel.page, /^Transmettre$/, { delai: 1500 })), 'feuille : aucun « Transmettre »');
  await p.capture(dirTel, '390_sombre_2_feuille');
  await cliquer(dirTel.page, /^Clore$/, { pause: 1500 });
  verifier(await attendreTexte(dirTel.page, 'Écrivez le motif de la clôture.', 8000), 'feuille : le motif manque, il est dit');
  verifier(statut(ID.s2) === 'ouvert', 'base : rien n est parti sans motif');
  await montrer(dirTel, 'Écrivez le motif de la clôture.', '390_sombre_3_motif_manque');
  await saisir(dirTel.page, 'Motif de la clôture', MOTIF);
  await cliquer(dirTel.page, /^Clore$/, { pause: 1500 });
  await cliquer(dirTel.page, /^Oui, clore$/, { pause: 3000 });
  verifier(await attendreTexte(dirTel.page, 'Signalement clos', 10000), 'feuille (390) : « Signalement clos »');
  verifier(statut(ID.s2) === 'clos', 'base : securite d un enfant close');
  verifier(sql(`select payload ->> 'motif' from public.audit_logs where row_id = '${ID.s2}' and action = 'student_concern_clos'`) === MOTIF,
    'base : le motif est au journal');
  await p.capture(dirTel, '390_sombre_4_clos');
  await cliquer(dirTel.page, /^Fermer$/, { pause: 2000 });
  verifier(!(await attendreTexte(dirTel.page, NOTE2, 3000)), 'direction (390) : sortie de la file');
  await p.capture(dirTel, '390_sombre_5_sorti_de_la_file');

  // --- 3. Arabe, 1440 sombre : examiner puis clore --------------------------
  p.dire('-- 3. arabe, 1440 sombre');
  ID.s3 = await deposer(prof, /^Technique$/, NOTE3);
  const dirAr = await p.contexte('direction', { ...BUREAU, sombre: true, langue: 'ar-SA' });
  await connecter(dirAr.page, COMPTES.direction);
  await vers(dirAr.page, '/admin/alertes');
  verifier(await attendreTexte(dirAr.page, NOTE3, 30000), 'direction (ar) : la ligne est dans les alertes');
  await cliquer(dirAr.page, new RegExp(echapper(NOTE3.slice(0, 40))), { pause: 1800 });
  verifier(await attendreTexte(dirAr.page, 'معالجة البلاغ', 10000), 'feuille (ar) : « معالجة البلاغ »');
  await p.capture(dirAr, '1440_sombre_ar_1_feuille');
  await cliquer(dirAr.page, /^فحص$/, { pause: 2500 });
  verifier(await attendreTexte(dirAr.page, 'البلاغ قيد الفحص', 10000), 'feuille (ar) : « البلاغ قيد الفحص »');
  verifier(statut(ID.s3) === 'en_examen', 'base : examine en arabe');
  await p.capture(dirAr, '1440_sombre_ar_2_en_examen');
  await cliquer(dirAr.page, /^إغلاق البلاغ$/, { pause: 1500 });
  await cliquer(dirAr.page, /^نعم، إغلاق البلاغ$/, { pause: 3000 });
  verifier(statut(ID.s3) === 'clos', 'base : clos en arabe');
  await p.capture(dirAr, '1440_sombre_ar_3_clos');

  // --- 4. 390 clair : la file, sans les trois ------------------------------
  const dirClair = await p.contexte('direction', TEL);
  await connecter(dirClair.page, COMPTES.direction);
  await vers(dirClair.page, '/admin/alertes');
  for (const note of [NOTE1, NOTE2, NOTE3]) {
    verifier(!(await attendreTexte(dirClair.page, note, 2500)), `390 clair : « ${note.slice(0, 25)}... » hors de la file`);
  }
  await p.capture(dirClair, '390_clair_file_sans_les_clos');

  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
