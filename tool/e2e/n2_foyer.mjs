// N2 (03/11/2026) : foyer et eleve adulte, dans la vraie application, sur la
// pile LOCALE seulement. Usage : node tool/e2e/n2_foyer.mjs
// Prerequis : amorcer.sh (un enseignant actif) ; migration 20261106700000.
// Les comptes et leurs situations sont amorces en SQL local (adresses
// example.com, prefixe E2E) ; chaque geste qui compte est fait dans
// l'interface, deux captures par geste (390 et 1440, clair et sombre), l'arabe
// une fois :
//   FA5 : le titulaire cree son profil eleve ;
//   FA1 : le titulaire voit « Inviter ma conjointe » et ouvre la page ;
//   FA3 : le titulaire voit la demande de reprise et ouvre la decision ; le
//         second adulte voit l'etat de sa demande ;
//   FA2 : l'adulte invite voit la carte de l'invitation et l'ouvre ;
//   E1  : l'eleve adulte ouvre Ma classe par « Voir ma classe ».
import { parcours, ouvrir, connecter, trouver, trouverTexte, activerSemantique, amenerEnVue,
  sql, MDP } from './commun.mjs';

const p = await parcours('N2 : foyer et eleve adulte', 'n2-foyer');
const tampon = new Date().toISOString().slice(5, 19).replace(/[-T:]/g, '');
const manque = [];
const un = (requete) => sql(requete).split('\n')[0].trim();
const LARGE = { width: 1440, height: 900 };

function compte(suffixe, { foyer = null, genre = 'female', prenom = 'E2E' } = {}) {
  const courriel = `e2e-n2-${tampon}-${suffixe}@example.com`;
  const id = un(`with u as (
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
        email_change_token_new, email_change)
      values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
        '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
      returning id),
    i as (insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
      select gen_random_uuid(), u.id, u.id::text, jsonb_build_object('sub', u.id::text, 'email', '${courriel}', 'email_verified', true),
             'email', now(), now(), now() from u returning user_id)
    select id from u`);
  const h = foyer ?? un(`insert into public.households (timezone) values ('Europe/Paris') returning id`);
  sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
       values ('${id}', 'E2E-N2-${suffixe}-${tampon}', 'guardian', '${h}', '${prenom}', 'N2', 'active',
       ${genre ? `'${genre}'` : 'null'})`);
  if (!foyer) sql(`update public.households set primary_guardian_id = '${id}' where id = '${h}'`);
  return { courriel, id, foyer: h };
}

// --- Amorce -----------------------------------------------------------------
// Titulaire Bilal (homme) et son enfant ; second adulte Maryam (femme) dans le
// meme foyer, qui a depose une demande de reprise ; Khadija, titulaire de son
// propre foyer, invitee par Bilal ; Ibrahim, eleve adulte dans une Classe.
const titulaire = compte('tit', { genre: 'male', prenom: 'Bilal' });
const enfant = un(`select gen_random_uuid()`);
sql(`insert into auth.users (id, email) values ('${enfant}', 'e2e-n2-${tampon}-enf@example.com')`);
sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
     values ('${enfant}', 'E2E-N2-ENF-${tampon}', 'student', '${titulaire.foyer}', 'Yusuf', 'N2', 'active', 'male')`);
sql(`insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${enfant}', 'minor', 'standard')`);
const second = compte('sec', { foyer: titulaire.foyer, genre: 'female', prenom: 'Maryam' });
sql(`insert into public.reprises_foyer (household_id, demandeur_profile_id, titulaire_profile_id, cle_depot)
     values ('${titulaire.foyer}', '${second.id}', '${titulaire.id}', gen_random_uuid())`);
const invitee = compte('inv', { genre: 'female', prenom: 'Khadija' });
sql(`insert into public.invitations_foyer (foyer_id, email_invite, invite_par, cle_envoi)
     values ('${titulaire.foyer}', lower('${invitee.courriel}'), '${titulaire.id}', gen_random_uuid())`);
const adulte = compte('adu', { genre: 'male', prenom: 'Ibrahim' });
sql(`insert into public.student_profiles (profile_id, titulaire_profile_id, student_type, interface_mode, camera_policy, cohorte)
     values ('${adulte.id}', '${adulte.id}', 'autonomous', 'standard', 'forbidden', 'adulte_18_plus')`);
const prof = un(`select id from public.profiles where role = 'teacher' and account_status = 'active' order by created_at limit 1`);
let classe = null;
for (let essai = 0; essai < 20 && !classe; essai++) {
  try {
    classe = un(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
      values ('${prof}', 'adulte', 6, 'E2E N2 Al-Huda ${tampon}', ${1 + Math.floor(Math.random() * 7)},
      ${6 + Math.floor(Math.random() * 15)}, 'Europe/Paris') returning id`);
  } catch { /* creneau pris */ }
}
if (classe) sql(`insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${classe}', '${adulte.id}', now() - interval '10 days')`);
p.dire(`Amorce : titulaire ${titulaire.courriel}, second ${second.courriel}, invitee ${invitee.courriel}, adulte ${adulte.courriel}, classe ${classe ?? 'absente'}`);

async function acteur(role, options, courriel) {
  const a = await p.contexte(role, options);
  await connecter(a.page, courriel);
  if (await a.page.locator('input[type=password]').count()) await connecter(a.page, courriel);
  return a;
}
async function aller(a, chemin) {
  await ouvrir(a.page, `/#${chemin}`);
  await a.page.waitForTimeout(4000);
  await activerSemantique(a.page);
}
async function voir(a, motif, quoi, delai = 12000) {
  const t = await trouverTexte(a.page, motif, delai);
  p.dire(`[${a.role}] ${quoi} : ${t ?? 'ABSENT'}`);
  if (!t) manque.push(`${a.role} : ${quoi}`);
  return t;
}
async function toucher(a, motif, role = undefined) {
  const e = await trouver(a.page, motif, { delai: 10000, role });
  if (!e) { manque.push(`${a.role} : ${motif} introuvable`); return false; }
  await amenerEnVue(a.page, e);
  await e.click();
  await a.page.waitForTimeout(3000);
  await activerSemantique(a.page);
  return true;
}

// FA5 et FA1 : le titulaire.
{
  const tel = await acteur('titulaire', { telephone: true }, titulaire.courriel);
  await aller(tel, '/tuteur/foyer');
  await voir(tel, /Inviter ma conjointe/, 'ligne « Inviter ma conjointe »');
  await voir(tel, /Une demande de reprise de votre foyer a été déposée/, 'carte de la demande de reprise');
  await p.capture(tel, '390_clair_foyer_titulaire_reprise');
  await aller(tel, '/tuteur/foyer/ajouter?pour=moi');
  await voir(tel, /suivre vous-même des cours/, 'FA5 explication');
  await p.capture(tel, '390_clair_fa5_creer_mon_profil');
  await tel.ctx.close();

  const bureau = await acteur('titulaire', { vue: LARGE, sombre: true }, titulaire.courriel);
  await aller(bureau, '/tuteur/foyer/ajouter?pour=moi');
  if (await toucher(bureau, /^Créer mon profil élève/, 'button')) {
    await voir(bureau, /Votre profil élève est créé/, 'FA5 profil cree');
    const cree = un(`select count(*) from public.student_profiles where profile_id = '${titulaire.id}' and titulaire_profile_id = '${titulaire.id}'`);
    p.dire(`FA5 : profil eleve du titulaire en base : ${cree}`);
    if (cree !== '1') manque.push('FA5 : profil eleve du titulaire absent en base');
  }
  await p.capture(bureau, '1440_sombre_fa5_profil_cree');
  await aller(bureau, '/tuteur/foyer');
  await p.capture(bureau, '1440_sombre_foyer_titulaire');
  if (await toucher(bureau, /Voir la demande de reprise/)) {
    await voir(bureau, /Refuser la demande/, 'FA3 decision du titulaire');
    await p.capture(bureau, '1440_sombre_fa3_decision_titulaire');
  }
  await aller(bureau, '/tuteur/foyer');
  if (await toucher(bureau, /Inviter ma conjointe/)) {
    await voir(bureau, /Un compte personnel pour elle/, 'FA1 page d inviter');
    await p.capture(bureau, '1440_sombre_fa1_inviter');
  }
  await bureau.ctx.close();
}

// FA3 : le second adulte.
{
  const bureau = await acteur('second', { vue: LARGE }, second.courriel);
  await aller(bureau, '/tuteur/foyer');
  await voir(bureau, /Demander la reprise du foyer/, 'ligne « Demander la reprise du foyer »');
  await p.capture(bureau, '1440_clair_foyer_second_adulte');
  await bureau.ctx.close();
  const tel = await acteur('second', { telephone: true, sombre: true }, second.courriel);
  await aller(tel, '/tuteur/foyer');
  if (await toucher(tel, /Demander la reprise du foyer/)) {
    await voir(tel, /Déposée/, 'FA3 etat de la demande');
    await p.capture(tel, '390_sombre_fa3_etat_demande');
  }
  await tel.ctx.close();
}

// FA2 : l'adulte invite.
{
  const tel = await acteur('invitee', { telephone: true }, invitee.courriel);
  await aller(tel, '/tuteur/accueil');
  await voir(tel, /Bilal vous invite à rejoindre son forfait famille/, 'FA2 carte de l invitation (accueil)');
  await p.capture(tel, '390_clair_fa2_carte_accueil');
  await tel.ctx.close();
  const bureau = await acteur('invitee', { vue: LARGE }, invitee.courriel);
  await aller(bureau, '/tuteur/foyer');
  if (await toucher(bureau, /Voir l'invitation/)) {
    await voir(bureau, /Accepter l'invitation/, 'FA2 page de l invitation');
    await p.capture(bureau, '1440_clair_fa2_invitation');
  }
  await bureau.ctx.close();
  const ar = await acteur('invitee', { telephone: true, langue: 'ar-SA' }, invitee.courriel);
  await aller(ar, '/tuteur/foyer');
  await voir(ar, /عرض الدعوة/, 'FA2 carte en arabe');
  await p.capture(ar, '390_ar_fa2_carte_foyer');
  await ar.ctx.close();
}

// E1 : l'eleve adulte.
{
  const bureau = await acteur('adulte', { vue: LARGE }, adulte.courriel);
  await aller(bureau, '/eleve/adulte');
  await voir(bureau, /Voir ma classe/, 'E1 lien « Voir ma classe »');
  await p.capture(bureau, '1440_clair_e1_accueil_adulte');
  await bureau.ctx.close();
  const tel = await acteur('adulte', { telephone: true, sombre: true }, adulte.courriel);
  await aller(tel, '/eleve/adulte');
  if (await toucher(tel, /Voir ma classe/)) {
    const url = tel.page.url();
    p.dire(`E1 : adresse ${url}`);
    if (!url.includes('/eleve/adulte/classe')) manque.push(`E1 : adresse ${url}`);
    await voir(tel, /Ma classe/, 'E1 page Ma classe');
    await p.capture(tel, '390_sombre_e1_ma_classe');
  }
  await tel.ctx.close();
}

process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'FA5 cree le profil ; FA1, FA3 (titulaire et second adulte), FA2 et E1 ouverts depuis leurs entrees ; arabe une fois'));
