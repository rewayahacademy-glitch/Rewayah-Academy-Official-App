// N1 (02/11/2026) : messages, annonces, alertes, sur la pile LOCALE.
//
// Ce que le parcours prouve, par l'interface, a 1440 x 900 et 390 x 844 :
//   1. un tuteur ecrit a l'enseignant depuis la Classe de son enfant, et
//      l'enseignant lui repond dans le meme fil (capacite « ecrire » ouverte
//      par com_mes_capacites, envoi par com_envoyer_message) ;
//   2. la direction publie une annonce pour toute l'academie (« Nouvelle
//      annonce », capacite « publier ») ; la matrice de portee est lue
//      (com_regles_audience), sans mention « Démonstration » ;
//   3. un signalement « Sécurité d'un enfant » depose par l'enseignant
//      apparait en tete des alertes de la direction, comme urgent
//      (signalements_ouverts_direction).
// Chaque etape verifie le texte attendu a l'ecran ET la ligne en base.
//
// Prerequis : la migration 20261105400000_n1_capacites_communication.sql
// appliquee sur la pile LOCALE (tool/e2e/pile.sh), comptes amorces
// (tool/e2e/amorcer.sh). Donnees : un foyer, un enfant et une Classe neufs a
// chaque passage ; rien n'est efface. Usage : node tool/e2e/n1_communications.mjs
import { parcours, trouver, libelles, ouvrir, activerSemantique, amenerEnVue,
  taper, connecter, attendreTexte, cliquer, nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs';

const p = await parcours('N1 : messages, annonces, alertes', 'n1-communications');
const n = Date.now() % 1000000;
const BUREAU = { vue: { width: 1440, height: 900 } };
const TEL = { vue: { width: 390, height: 844 } };
const courrielTuteur = `e2e-n1-tuteur-${n}@example.com`;
const MSG_TUTEUR = `Bonjour, Yasmine a une question sur la sourate ${n}.`;
const MSG_PROF = `Merci, nous la reverrons en classe ${n}.`;
const TITRE_ANNONCE = `Reprise des cours ${n}`;
const TEXTE_ANNONCE = 'Les séances reprennent lundi aux horaires habituels.';
const NOTE = `Inquiétude pour la sécurité de Yasmine ${n}`;
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

/// Un foyer, son tuteur, une enfant (mineure) dans une Classe neuve de
/// l'enseignant amorce. Insere en SQL LOCAL : l'inscription n'est pas l'objet
/// de ce lot (elle est prouvee par les parcours 2 a 4).
function amorcer() {
  nettoyerClassesE2E();
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  ID.tuteur = creerCompte(courrielTuteur);
  ID.eleve = sql('select gen_random_uuid()');
  ID.foyer = sql('select gen_random_uuid()');
  ID.classe = sql('select gen_random_uuid()');
  ID.matricule = `E2E-N1-${n}`;
  sql(`begin;
    insert into auth.users (id, email) values ('${ID.eleve}', 'e2e-n1-eleve-${n}@example.com');
    insert into public.households (id, timezone) values ('${ID.foyer}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', 'E2E-N1-T-${n}', 'guardian', '${ID.foyer}', 'Samira', 'Tuteur', 'active', 'female'),
      ('${ID.eleve}', '${ID.matricule}', 'student', '${ID.foyer}', 'Yasmine', 'Eleve', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.foyer}';
    insert into public.student_profiles (profile_id, student_type, interface_mode)
      values ('${ID.eleve}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, 'E2E N1 An-Nour ${n}', 6, 21);
    insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.eleve}');
    commit;`);
  p.dire(`  amorce : tuteur ${courrielTuteur}, classe ${ID.classe}, eleve ${ID.matricule}`);
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(3500);
  await activerSemantique(page);
}

/// Defile jusqu'au texte puis le capture : la capture montre la ligne.
async function montrer(acteur, texte, etiquette) {
  const e = await trouver(acteur.page, texte, { delai: 15000 });
  if (e) await amenerEnVue(acteur.page, e);
  await acteur.page.waitForTimeout(600);
  return p.capture(acteur, etiquette);
}

async function ecrireEtEnvoyer(page, texte) {
  await taper(page, 'textarea', texte);
  await cliquer(page, /^Envoyer$/, { pause: 2500 });
}

let code = 1;
try {
  amorcer();

  // --- 1. Le tuteur ecrit a l'enseignant (1440) --------------------------
  p.dire('-- 1. tuteur : ecrire a l enseignant depuis la Classe');
  const tuteur = await p.contexte('tuteur', BUREAU);
  await connecter(tuteur.page, courrielTuteur);
  await vers(tuteur.page, `/tuteur/classes/${ID.classe}`);
  verifier(await attendreTexte(tuteur.page, 'Échanger sur cette Classe', 30000),
    'tuteur : bloc « Échanger sur cette Classe » rendu (capacite ecrire ouverte)');
  await cliquer(tuteur.page, /^Écrire à (Sayyid|Sayyida|E2E)/, { pause: 3000 });
  await ecrireEtEnvoyer(tuteur.page, MSG_TUTEUR);
  verifier(await attendreTexte(tuteur.page, MSG_TUTEUR, 15000), 'tuteur : son message est affiche dans le fil');
  await p.capture(tuteur, 'fil_message_envoye_1440');
  ID.fil = sql(`select fil_id from public.com_messages where auteur_id = '${ID.tuteur}' and texte = '${MSG_TUTEUR}'`);
  verifier(/^[0-9a-f-]{36}$/.test(ID.fil), 'base : message du tuteur enregistre (com_messages)');

  // --- 2. L'enseignant repond (390 puis 1440) -----------------------------
  p.dire('-- 2. enseignant : repondre dans le meme fil');
  const prof = await p.contexte('enseignant', TEL);
  await connecter(prof.page, COMPTES.enseignant);
  await vers(prof.page, `/enseignant/messages/${ID.fil}`);
  verifier(await attendreTexte(prof.page, MSG_TUTEUR, 30000), 'enseignant : le message du tuteur est lu');
  await ecrireEtEnvoyer(prof.page, MSG_PROF);
  verifier(await attendreTexte(prof.page, MSG_PROF, 15000), 'enseignant : sa reponse est affichee');
  await montrer(prof, MSG_PROF, 'fil_reponse_390');
  verifier(sql(`select count(*) from public.com_messages where fil_id = '${ID.fil}'`) === '2',
    'base : deux messages dans le fil, un par partie');

  // Constat : un fil deja ouvert ne se met pas a jour tout seul (aucun temps
  // reel sur les Messages) ; la personne recharge, le robot aussi.
  p.dire('  CONSTAT : le fil ouvert du tuteur ne montre la reponse qu apres rechargement');
  await tuteur.page.reload();
  await tuteur.page.waitForTimeout(5000);
  await activerSemantique(tuteur.page);
  verifier(await attendreTexte(tuteur.page, MSG_PROF, 30000), 'tuteur : la reponse de l enseignant arrive dans son fil');
  await p.capture(tuteur, 'fil_deux_messages_1440');
  const tuteurTel = await p.contexte('tuteur', TEL);
  await connecter(tuteurTel.page, courrielTuteur);
  await vers(tuteurTel.page, `/tuteur/messages/${ID.fil}`);
  verifier(await attendreTexte(tuteurTel.page, MSG_PROF, 30000), 'tuteur (390) : les deux messages se lisent');
  await montrer(tuteurTel, MSG_PROF, 'fil_deux_messages_390');

  // --- 3. La direction publie une annonce (1440) --------------------------
  p.dire('-- 3. direction : publier une annonce pour toute l academie');
  const dir = await p.contexte('direction', BUREAU);
  await connecter(dir.page, COMPTES.direction);
  await vers(dir.page, '/admin/operations/communications/annonces');
  verifier(await attendreTexte(dir.page, 'Sa Classe seulement', 30000),
    'direction : la matrice de portee est lue du serveur');
  verifier(!(await attendreTexte(dir.page, 'Démonstration', 2000)), 'direction : aucune mention « Démonstration »');
  await montrer(dir, 'Sa Classe seulement', 'regles_portee_1440');
  await cliquer(dir.page, /^Nouvelle annonce$/, { pause: 2500 });
  await taper(dir.page, 'input[type=text]', TITRE_ANNONCE);
  await taper(dir.page, 'textarea', TEXTE_ANNONCE);
  await cliquer(dir.page, /^Continuer$/, { pause: 2000 });
  await cliquer(dir.page, /Toute l.académie/, { pause: 1200 });
  // Continuer jusqu'a la publication (destinataires, date, apercu).
  for (let i = 0; i < 4; i++) {
    const publier = await trouver(dir.page, /^Publier l.annonce$/, { delai: 2500 });
    if (publier) break;
    await cliquer(dir.page, /^Continuer$/, { pause: 2000 });
  }
  await cliquer(dir.page, /^Publier l.annonce$/, { pause: 3500 });
  verifier(await attendreTexte(dir.page, 'Annonce publiée', 20000), 'direction : « Annonce publiée » affiche');
  await p.capture(dir, 'annonce_publiee_1440');
  verifier(sql(`select audience from public.com_annonces where titre = '${TITRE_ANNONCE}' and auteur_id = '${ID.admin}'`) === 'toutes',
    'base : annonce enregistree pour toute l academie (com_annonces)');

  await vers(tuteurTel.page, `/tuteur/classes/${ID.classe}`);
  verifier(await attendreTexte(tuteurTel.page, TITRE_ANNONCE, 30000), 'tuteur (390) : l annonce de la direction arrive dans la Classe');
  await montrer(tuteurTel, TITRE_ANNONCE, 'annonce_recue_390');

  // --- 4. Signalement de l'enseignant, alerte de la direction ------------
  p.dire('-- 4. enseignant : signaler un besoin, securite d un enfant');
  const profBureau = await p.contexte('enseignant', BUREAU);
  await connecter(profBureau.page, COMPTES.enseignant);
  await vers(profBureau.page, `/enseignant/groupe/${ID.classe}`);
  await cliquer(profBureau.page, /Yasmine/, { pause: 2500 });
  await cliquer(profBureau.page, /^Signaler un besoin$/, { pause: 2500 });
  await cliquer(profBureau.page, /Sécurité d.un enfant/, { pause: 1000 });
  await taper(profBureau.page, 'textarea', NOTE);
  await p.capture(profBureau, 'signalement_avant_envoi_1440');
  await cliquer(profBureau.page, /^Envoyer le signalement$/, { pause: 3000 });
  // Apres un envoi reel, la feuille dit ce qui est vrai (correctif N1 du
  // 02/11, fiche_eleve_enseignant.dart) ; jamais le texte de demonstration.
  verifier(await attendreTexte(profBureau.page, "Signalement transmis à l'administration.", 15000),
    "enseignant : « Signalement transmis à l'administration. » affiche");
  verifier(!(await attendreTexte(profBureau.page, "rien n'a été envoyé", 2000)),
    "enseignant : aucun « Démonstration : rien n'a été envoyé » apres un envoi reel");
  await montrer(profBureau, "Signalement transmis à l'administration.", 'signalement_transmis_1440');
  verifier(sql(`select prioritaire from public.student_concern where internal_details = '${NOTE}'`) === 't',
    'base : signalement prioritaire enregistre (student_concern)');

  p.dire('-- 5. direction : alertes urgentes');
  // La page de la direction est ouverte depuis l'etape 3 : l'alerte arrive a
  // la relecture suivante (une par minute, AlertesSupabase), sans recharger.
  await vers(dir.page, '/admin/alertes');
  verifier(await attendreTexte(dir.page, NOTE, 80000), 'direction : la note du signalement arrive dans les alertes, sans recharger');
  verifier(await attendreTexte(dir.page, 'Urgente', 5000), 'direction : l alerte est marquee « Urgente »');
  await montrer(dir, NOTE, 'alertes_signalement_1440');
  const dirTel = await p.contexte('direction', TEL);
  await connecter(dirTel.page, COMPTES.direction);
  await vers(dirTel.page, '/admin/alertes');
  verifier(await attendreTexte(dirTel.page, NOTE, 30000), 'direction (390) : la note du signalement est dans les alertes');
  await montrer(dirTel, NOTE, 'alertes_signalement_390');
  await vers(dirTel.page, '/admin/operations/communications/annonces');
  verifier(await attendreTexte(dirTel.page, /alertes? urgentes?/i, 20000), 'direction (390) : bandeau d alerte urgente en tete d une autre page');
  await p.capture(dirTel, 'bandeau_alerte_390');

  code = await p.fin('vert');
} catch (e) {
  p.dire(`  ${String(e.stack ?? e).slice(0, 1500)}`);
  for (const ctx of p.navigateur.contexts()) {
    for (const pg of ctx.pages()) {
      p.dire(`  visibles : ${(await libelles(pg)).slice(0, 50).join(' | ')}`);
    }
  }
  code = await p.fin('rouge', String(e.message ?? e).slice(0, 300));
}
process.exit(code);
