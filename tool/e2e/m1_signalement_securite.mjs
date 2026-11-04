// M1-SUPPR (03/11/2026) : les sept cas de protection des enfants portes sur
// la feuille branchee « Signaler un besoin » (`SignalerBesoin`), sur la pile
// LOCALE, par l'interface, a 1440 (clair) et a 390 (sombre).
//
// Avant la suppression de l'ancienne feuille (`tc_flux_academique`), ces cas
// n'etaient prouves que sur elle, que l'application n'atteignait pas
// (decision du directeur du 03/11/2026, docs/current/M1-MODULES-EN-DOUBLE-2026-11-03.md).
//
// Les sept cas, a l'ecran ET en base :
//   1. la categorie « Sécurité d'un enfant » est proposee ; avant elle, le
//      resume pour la famille est la ;
//   2. la choisir retire le resume et ses phrases, et pose la notice
//      (prioritaire, urgence) ;
//   3. responsable vide : « La direction reçoit votre signalement. » ;
//   4. responsable saisi par l'administration : son nom et son courriel ;
//   5. lecture du responsable en panne : la panne se dit (jamais « la
//      direction »), « Réessayer » relit ;
//   6. le depot part en « securite_enfant », sans message pour la famille,
//      meme si une phrase avait ete choisie avant ;
//   7. la direction l'ouvre : ni la famille ni l'enseignant ne le lisent,
//      aucun « Transmettre ».
//
// Prerequis : pile LOCALE (tool/e2e/pile.sh), comptes amorces
// (tool/e2e/amorcer.sh). Donnees : un foyer, une enfant et une Classe neufs ;
// le reglage du responsable est remis a vide en fin de passage.
// Usage : node tool/e2e/m1_signalement_securite.mjs
import { parcours, trouver, activerSemantique, amenerEnVue, taper,
  connecter, attendreTexte, cliquer, nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs';

const p = await parcours('M1-SUPPR : Signaler un besoin, securite d un enfant', 'M1-SUPPR');
const n = Date.now() % 1000000;
const VUES = [
  { nom: '1440_clair', vue: { width: 1440, height: 900 }, sombre: false },
  { nom: '390_sombre', vue: { width: 390, height: 844 }, sombre: true },
];
const ID = {};
const RESPONSABLE = 'Sayyid Yusuf';
const COURRIEL = 'protection@example.test';

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

function matriculeLibre() {
  for (;;) {
    const m = `RA-26-${1000 + Math.floor(Math.random() * 9000)}`;
    if (sql(`select count(*) from public.profiles where immutable_id = '${m}'`) === '0') return m;
  }
}

function responsable(nom, courriel) {
  sql(`update public.app_config set value = to_jsonb('${nom}'::text)
        where key = 'protection_enfants.responsable_nom';
       update public.app_config set value = to_jsonb('${courriel}'::text)
        where key = 'protection_enfants.responsable_courriel';`);
}

function amorcer() {
  nettoyerClassesE2E();
  sql(`update public.student_concern set statut = 'clos'
        where statut <> 'clos' and internal_details ~ '^M1-SUPPR '`);
  responsable('', '');
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.tuteur = creerCompte(`e2e-m1s-tuteur-${n}@example.com`);
  ID.eleve = sql('select gen_random_uuid()');
  ID.foyer = sql('select gen_random_uuid()');
  ID.classe = sql('select gen_random_uuid()');
  sql(`begin;
    insert into auth.users (id, email) values ('${ID.eleve}', 'e2e-m1s-eleve-${n}@example.com');
    insert into public.households (id, timezone) values ('${ID.foyer}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', '${matriculeLibre()}', 'guardian', '${ID.foyer}', 'Samira', 'Tuteur', 'active', 'female'),
      ('${ID.eleve}', '${matriculeLibre()}', 'student', '${ID.foyer}', 'Yasmine', 'Eleve', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.foyer}';
    insert into public.student_profiles (profile_id, student_type, interface_mode)
      values ('${ID.eleve}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, 'E2E M1-SUPPR Al-Fajr ${n}', 6, 21);
    insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.eleve}');
    commit;`);
  p.dire(`  amorce : classe ${ID.classe}`);
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

/// Recharge l'application (le responsable est relu au demarrage), puis
/// ouvre « Signaler un besoin » sur Yasmine.
async function ouvrirFeuille(prof) {
  await prof.page.reload();
  await prof.page.waitForTimeout(5000);
  await activerSemantique(prof.page);
  await vers(prof.page, `/enseignant/groupe/${ID.classe}`);
  await cliquer(prof.page, /^Yasmine/, { pause: 2500 });
  await cliquer(prof.page, /^Signaler un besoin$/, { pause: 2500 });
  verifier(await attendreTexte(prof.page, 'Sécurité d\'un enfant', 10000), 'feuille ouverte, categories visibles');
}

const securite = /Sécurité d.un enfant/;
const pedagogique = /^Problème pédagogique$/;

async function passage(vue) {
  p.dire(`-- ${vue.nom}`);
  responsable('', '');
  const prof = await p.contexte('enseignant', { vue: vue.vue, sombre: vue.sombre });
  await connecter(prof.page, COMPTES.enseignant);

  // 1. La categorie est proposee ; le resume est la avant elle.
  await ouvrirFeuille(prof);
  verifier(await attendreTexte(prof.page, 'Résumé partageable', 5000), '1 : le resume pour la famille est la avant le choix');
  await montrer(prof, securite, `${vue.nom}_1_categorie_proposee`);

  // 2. La choisir retire le resume et ses phrases, pose la notice.
  await cliquer(prof.page, pedagogique, { pause: 1200 });
  verifier(await attendreTexte(prof.page, 'Un renforcement est conseillé sur la leçon en cours.', 5000),
    '2 : la phrase-type pedagogique est proposee');
  await cliquer(prof.page, securite, { pause: 1500 });
  verifier(await attendreTexte(prof.page, 'Signalement prioritaire', 8000), '2 : la notice « Signalement prioritaire »');
  verifier(await attendreTexte(prof.page, /En cas de danger immédiat/, 3000), '2 : la phrase d urgence');
  verifier(!(await attendreTexte(prof.page, 'Résumé partageable', 1500)), '2 : plus de resume pour la famille');
  verifier(!(await attendreTexte(prof.page, 'Un renforcement est conseillé sur la leçon en cours.', 1500)),
    '2 : plus de phrase-type');
  await montrer(prof, 'Signalement prioritaire', `${vue.nom}_2_notice`);

  // 3. Responsable vide : la direction recoit.
  verifier(await attendreTexte(prof.page, 'La direction reçoit votre signalement.', 8000),
    '3 : responsable vide, « La direction reçoit votre signalement. »');
  await montrer(prof, 'La direction reçoit votre signalement.', `${vue.nom}_3_responsable_vide`);

  // 4. Responsable saisi : son nom et son courriel.
  responsable(RESPONSABLE, COURRIEL);
  await ouvrirFeuille(prof);
  await cliquer(prof.page, securite, { pause: 2000 });
  verifier(await attendreTexte(prof.page, `${RESPONSABLE} et la direction reçoivent votre signalement.`, 10000),
    '4 : le nom du responsable');
  verifier(await attendreTexte(prof.page, /protection@/, 3000), '4 : son courriel');
  await montrer(prof, RESPONSABLE, `${vue.nom}_4_responsable_saisi`);

  // 5. Lecture en panne : la panne se dit, « Réessayer » relit.
  await prof.page.route('**/rest/v1/rpc/responsable_protection_enfants*',
    (route) => route.fulfill({ status: 503, contentType: 'application/json', body: '{"message":"indisponible"}' }));
  await ouvrirFeuille(prof);
  await cliquer(prof.page, securite, { pause: 2500 });
  verifier(await attendreTexte(prof.page, /Le nom du responsable ne s.affiche pas pour l.instant/, 10000),
    '5 : la panne de lecture se dit');
  verifier(!(await attendreTexte(prof.page, 'La direction reçoit votre signalement.', 1500)),
    '5 : la panne ne passe pas pour un reglage vide');
  await montrer(prof, /Le nom du responsable ne s.affiche pas/, `${vue.nom}_5_panne`);
  await prof.page.unroute('**/rest/v1/rpc/responsable_protection_enfants*');
  await cliquer(prof.page, /^Réessayer$/, { pause: 3000 });
  verifier(await attendreTexte(prof.page, `${RESPONSABLE} et la direction reçoivent votre signalement.`, 10000),
    '5 : « Réessayer » relit le responsable');
  await montrer(prof, RESPONSABLE, `${vue.nom}_5_relu`);

  // 6. Le depot part prioritaire, sans message pour la famille.
  const note = `M1-SUPPR ${vue.nom} : Yasmine semble inquiète en arrivant (${n}).`;
  await ouvrirFeuille(prof);
  await cliquer(prof.page, pedagogique, { pause: 1200 });
  await cliquer(prof.page, /^Un renforcement est conseillé sur la leçon en cours\.$/, { pause: 1200 });
  await cliquer(prof.page, securite, { pause: 1500 });
  await taper(prof.page, 'textarea', note);
  await cliquer(prof.page, /^Envoyer le signalement$/, { pause: 3000 });
  verifier(await attendreTexte(prof.page, 'Signalement transmis à l\'administration.', 15000), '6 : envoi confirme');
  await p.capture(prof, `${vue.nom}_6_envoye`);
  const ligne = sql(`select id || '|' || categorie || '|' || coalesce(family_summary, '<nul>') || '|' || statut
    from public.student_concern where internal_details = '${note.replace(/'/g, "''")}'`);
  const [id, categorie, famille] = ligne.split('|');
  verifier(categorie === 'securite_enfant', '6 : base, categorie securite_enfant');
  verifier(famille === '<nul>', '6 : base, aucun message pour la famille malgre la phrase choisie avant');

  // 7. La direction l'ouvre : rien ne se transmet.
  const dir = await p.contexte('direction', { vue: vue.vue, sombre: vue.sombre });
  await connecter(dir.page, COMPTES.direction);
  await vers(dir.page, '/admin/alertes');
  verifier(await attendreTexte(dir.page, note, 30000), '7 : la direction le voit dans ses alertes');
  await cliquer(dir.page, new RegExp(note.slice(0, 40).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), { pause: 2000 });
  verifier(await attendreTexte(dir.page, /Ni la famille ni l.enseignant ne lisent ce signalement/, 10000),
    '7 : ni la famille ni l enseignant ne le lisent');
  verifier(!(await trouver(dir.page, /^Transmettre$/, { delai: 1500 })), '7 : aucun « Transmettre »');
  await p.capture(dir, `${vue.nom}_7_direction_sans_transmettre`);
  sql(`update public.student_concern set statut = 'clos' where id = '${id}'`);
  await prof.ctx.close();
  await dir.ctx.close();
}

let code = 1;
try {
  amorcer();
  for (const vue of VUES) await passage(vue);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
} finally {
  try { responsable('', ''); } catch { /* pile arretee */ }
}
process.exit(code);
