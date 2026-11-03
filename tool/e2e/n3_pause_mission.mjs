// Lot N3 (03/11/2026) : la pause programmee vue par l'enseignant (S2), puis
// la mission du controleur demarree et son compte rendu envoye (D3), sur la
// pile LOCALE seulement (jamais un apercu Vercel, jamais la production).
//
// Amorce (SQL local, comme amorcer.sh pour les comptes que l'interface ne sait
// pas creer) : une classe de l'enseignant de test avec un enfant, sa seance
// du moment (pas encore ouverte), un compte de controleur avec sa capacite et
// la regle de tirage (5 missions par semaine). L'horloge n'est jamais avancee.
// Tout le reste passe par l'interface :
//   1. l'enseignant programme la pause dans la fiche de sa classe
//      (« Programmer une pause », 15 min, 5 min) ;
//   2. il entre dans la salle : la seance passe en direct, le serveur fige la
//      pause (« Pause dans N min ») et attribue la mission au controleur ;
//   3. il demarre la pause (« Pause, reprise a HH:MM »), puis la termine ;
//   4. le controleur active sa seconde etape de connexion (code TOTP calcule
//      a partir de la cle affichee), voit sa mission, « Commencer le
//      controle », entre dans la salle, la quitte ;
//   5. compte rendu : « Rien a signaler », « Envoyer le compte rendu ».
// Les captures vont dans docs/current/captures/E2E/N3/<date>/<largeur>.
//
// Usage : E2E_VUE=1440x900 node tool/e2e/n3_pause_mission.mjs (puis 390x844)
import crypto from 'node:crypto';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES, MDP, nettoyerClassesE2E } from './commun.mjs';

const [largeur, hauteur] = (process.env.E2E_VUE ?? '1440x900').split('x').map(Number);
const vue = { width: largeur, height: hauteur };
const date = new Date().toISOString().slice(0, 10);
const p = await parcours(`N3 : pause programmee et mission du controleur (${largeur} x ${hauteur})`,
  `N3/${date}/${largeur}`);
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

/// Code TOTP (RFC 6238, SHA-1, 30 s, 6 chiffres) d'une cle en base32.
function totp(cle) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const c of cle.replace(/[\s=]/g, '').toUpperCase()) {
    bits += alphabet.indexOf(c).toString(2).padStart(5, '0');
  }
  const octets = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
  const compteur = Buffer.alloc(8);
  compteur.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000)));
  const h = crypto.createHmac('sha1', octets).update(compteur).digest();
  const o = h[h.length - 1] & 0xf;
  const v = (h.readUInt32BE(o) & 0x7fffffff) % 1000000;
  return String(v).padStart(6, '0');
}

function amorcer() {
  nettoyerClassesE2E();
  ID.admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.tuteur = creerCompte(`e2e-n3-tuteur-${n}@example.com`);
  ID.enfant = creerCompte(`e2e-n3-enfant-${n}@example.com`);
  ID.courrielControleur = `e2e-n3-controleur-${n}@example.com`;
  ID.controleur = creerCompte(ID.courrielControleur);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${ID.tuteur}', 'E2E-N3-T-${n}', 'guardian', '${ID.tuteur}', 'E2E Parent', 'Pause', 'active', 'male'),
           ('${ID.enfant}', 'E2E-N3-E-${n}', 'student', '${ID.tuteur}', 'E2E Enfant', 'Pause', 'active', 'male'),
           ('${ID.controleur}', 'E2E-N3-C-${n}', 'controller', null, 'E2E Controleur', 'Visite', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    commit;`);
  // Un seul controleur capable : les capacites E2E d'un passage precedent
  // sont revoquees (jamais effacees).
  sql(`update private.controle_capacites set revoked_at = now(), revoked_by = '${ID.admin}',
         revoke_reason = 'E2E : passage suivant', revoke_idempotency_key = gen_random_uuid()
       where revoked_at is null`);
  sql(`insert into private.controle_capacites (profile_id, approved_by, active_from, expires_at,
         scope_all_groups, grant_idempotency_key)
       values ('${ID.controleur}', '${ID.admin}', now() - interval '1 hour', now() + interval '7 days',
         true, gen_random_uuid())`);
  sql(`do $r$ begin
    perform set_config('request.jwt.claim.sub', '${ID.admin}', true);
    perform set_config('request.jwt.claims', '{"sub":"${ID.admin}","aal":"aal2","app_metadata":{"role":"admin"}}', true);
    perform public.enregistrer_regles_tirage(
      '{"missions_par_semaine":5,"ponderations":{"enseignants_recents":"normal","classes_signalees":"normal","heures_de_pointe":"aucun"},"cibles":[]}'::jsonb,
      gen_random_uuid());
  end $r$;`);
  ID.nom = `E2E N3 Pause ${n}`;
  ID.classe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    values ('${ID.prof}', 'enfant', 5, '${ID.nom}',
            date_part('isodow', now() at time zone 'UTC' + interval '3 days')::smallint, 9, 'UTC')
    returning id`).split('\n')[0];
  sql(`insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.enfant}')`);
  ID.seance = sql(`insert into public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at, status)
    values ('${ID.prof}', now() - interval '2 minutes', now() + interval '58 minutes', 'child',
            '${ID.classe}', now() - interval '22 minutes', 'planned')
    returning id`).split('\n')[0];
  sql(`insert into public.session_participants (session_id, profile_id, role)
       values ('${ID.seance}', '${ID.enfant}', 'student') on conflict do nothing`);
  p.dire(`Amorce : classe ${ID.classe} (${ID.nom}), seance ${ID.seance} (planned), enseignant ${ID.prof}, controleur ${ID.controleur} (${ID.courrielControleur})`);
}

async function toucher(page, motif, quoi, { delai = 10000, role } = {}) {
  const e = await trouver(page, motif, { delai, role });
  if (!e) throw new Error(`${quoi} absent ; ${await lus(page, 60)}`);
  await amenerEnVue(page, e);
  await e.click();
  await page.waitForTimeout(2500);
  await activerSemantique(page);
  return e;
}

/// Au telephone, la ligne d'etat de la salle (chrono, pause) vit dans la carte
/// « Informations de la seance », depliee depuis la capsule video.
async function voirEtat(page) {
  if (largeur >= 600) return;
  if (await trouver(page, /^Réduire/, { delai: 1500, role: 'button' })) return;
  const info = await trouver(page, /^Informations de la séance/, { delai: 5000, role: 'button' });
  if (info) { await info.click(); await page.waitForTimeout(2000); await activerSemantique(page); }
}

let code = 1;
try {
  amorcer();

  // 1. L'enseignant programme la pause dans la fiche de sa classe.
  const e = await p.contexte('enseignant', { vue });
  await connecter(e.page, COMPTES.enseignant);
  await ouvrir(e.page, `/#/enseignant/groupe/${ID.classe}`);
  await e.page.waitForTimeout(3000); await activerSemantique(e.page);
  await toucher(e.page, /^Programmer une pause/, '« Programmer une pause »');
  const quinze = await trouver(e.page, /^15( min)?$/, { delai: 4000 });
  if (quinze) { await amenerEnVue(e.page, quinze); await quinze.click(); await e.page.waitForTimeout(800); }
  await toucher(e.page, /^Enregistrer la pause/, '« Enregistrer la pause »');
  const reglage = sql(`select actif || ' ' || apres_minutes || ' ' || duree_minutes || ' v' || version from public.pause_reglages where groupe_id = '${ID.classe}'`);
  p.dire(`Reglage enregistre au serveur : ${reglage || 'aucun'}`);
  verdicts.reglageEnregistre = /^true 15 5 v1$/.test(reglage);
  await p.capture(e, 'pause_programmee_fiche');

  // 2. L'enseignant entre dans la salle.
  await ouvrir(e.page, '/');
  await e.page.waitForTimeout(3000); await activerSemantique(e.page);
  await toucher(e.page, new RegExp(`^Rejoindre la salle.*${ID.nom}`), '« Rejoindre la salle »', { delai: 20000 });
  await e.page.waitForTimeout(10000); await activerSemantique(e.page);
  const etatSeance = sql(`select status from public.sessions where id = '${ID.seance}'`);
  const pauseSeance = sql(`select statut || ' ' || duree_prevue_minutes from public.pause_seances where seance_id = '${ID.seance}'`);
  ID.mission = sql(`select id from private.controle_missions where session_id = '${ID.seance}'`);
  p.dire(`Seance : ${etatSeance} ; pause figee : ${pauseSeance || 'aucune'} ; mission : ${ID.mission || 'aucune'}`);
  await voirEtat(e.page);
  const salle = await lus(e.page, 200);
  p.dire(`Salle de l'enseignant : ${salle}`);
  verdicts.pauseProgrammeeVue = /Pause dans \d+ min/.test(salle);
  await p.capture(e, 'salle_pause_programmee');

  // 3. Il demarre la pause, puis la termine.
  await toucher(e.page, /^Démarrer la pause/, '« Démarrer la pause »');
  await voirEtat(e.page);
  const enCours = await lus(e.page, 200);
  p.dire(`Apres « Démarrer la pause » : ${(enCours.match(/[^|]*(Pause|pause)[^|]*/g) ?? []).join(' | ')}`);
  p.dire(`Apres « Démarrer la pause » : base ${sql(`select statut from public.pause_seances where seance_id = '${ID.seance}'`)}`);
  verdicts.pauseEnCoursVue = /reprise à \D?\d\d:\d\d/.test(enCours) && /Terminer la pause/.test(enCours);
  await p.capture(e, 'salle_pause_en_cours');
  await voirEtat(e.page);
  await toucher(e.page, /^Terminer la pause/, '« Terminer la pause »');
  await voirEtat(e.page);
  const prise = await lus(e.page, 200);
  p.dire(`Apres « Terminer la pause » : base ${sql(`select statut from public.pause_seances where seance_id = '${ID.seance}'`)}`);
  verdicts.pausePriseVue = /Pause prise/.test(prise);
  await p.capture(e, 'salle_pause_prise');

  // 4. Le controleur : seconde etape, mission, entree en salle.
  const c = await p.contexte('controleur', { vue });
  await connecter(c.page, ID.courrielControleur);
  await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  let cle = await c.page.evaluate(() => {
    // La cle affichee (SelectableText) : un champ en lecture seule.
    for (const x of document.querySelectorAll('textarea[disabled], input[disabled]')) {
      const v = (x.value ?? '').replace(/\s/g, '');
      if (/^[A-Z2-7]{16,}$/.test(v)) return v;
    }
    for (const x of document.querySelectorAll('flt-semantics, [aria-label]')) {
      const t = (x.getAttribute('aria-label') ?? x.textContent ?? '').trim();
      if (/^[A-Z2-7]{16,}$/.test(t)) return t;
    }
    return null;
  });
  if (!cle) {
    // Repli honnete : la cle lue dans la base locale, et c'est dit.
    cle = sql(`select secret from auth.mfa_factors where user_id = '${ID.controleur}' order by created_at desc limit 1`);
    p.dire(`ECART : cle de la seconde etape absente de l'arbre d'accessibilite ; lue dans la base locale`);
  }
  await p.capture(c, 'controleur_seconde_etape');
  // Le champ du code n'a pas d'etiquette propre (le libelle est un texte
  // au-dessus) : le seul champ de saisie de la page.
  const champ = c.page.locator('input:not([disabled]), textarea:not([disabled])').first();
  await champ.waitFor({ state: 'visible', timeout: 8000 });
  await amenerEnVue(c.page, champ);
  await champ.click(); await c.page.waitForTimeout(800);
  await c.page.keyboard.type(totp(cle), { delay: 60 });
  await toucher(c.page, /^(Activer la protection|Confirmer)$/, '« Activer la protection »');
  await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  const controle = await lus(c.page, 120);
  p.dire(`Controle du controleur : ${controle}`);
  verdicts.missionVue = controle.includes(ID.nom) && /Commencer le contrôle/.test(controle);
  await p.capture(c, 'controleur_mission');
  await toucher(c.page, /^Commencer le contrôle/, '« Commencer le contrôle »', { role: 'button' });
  await c.page.waitForTimeout(10000); await activerSemantique(c.page);
  const mission = sql(`select statut || ' ' || (commencee_le is not null) from private.controle_missions where id = '${ID.mission}'`);
  p.dire(`Mission apres « Commencer le contrôle » : ${mission} ; salle : ${await lus(c.page, 60)}`);
  verdicts.missionDemarree = /^en_cours true$/.test(mission);
  await p.capture(c, 'controleur_salle');

  // 5. Il quitte la salle : compte rendu, « Rien a signaler », envoi.
  await toucher(c.page, /^Quitter/, '« Quitter »', { role: 'button' });
  const confirmer = await trouver(c.page, /^Quitter (la salle|l'observation|la séance)/, { delai: 3000, role: 'button' });
  if (confirmer) { await confirmer.click(); await c.page.waitForTimeout(3000); await activerSemantique(c.page); }
  await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  const transmise = sql(`select (transmise_le is not null) || ' ' || coalesce(choix, '-') from private.controle_comptes_rendus where mission_id = '${ID.mission}'`);
  p.dire(`Compte rendu ouvert ; transmission au serveur : ${transmise || 'aucune'} ; ecran : ${await lus(c.page, 80)}`);
  verdicts.visiteTransmise = /^true -$/.test(transmise);
  await p.capture(c, 'compte_rendu_ouvert');
  await toucher(c.page, /^Rien à signaler/, '« Rien à signaler »');
  await toucher(c.page, /^Envoyer le compte rendu/, '« Envoyer le compte rendu »', { role: 'button' });
  await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  const envoye = sql(`select cr.choix || ' ' || m.rapport_envoye from private.controle_comptes_rendus cr
    join private.controle_missions m on m.id = cr.mission_id where cr.mission_id = '${ID.mission}'`);
  p.dire(`Apres l'envoi : base ${envoye} ; ecran : ${await lus(c.page, 80)}`);
  verdicts.compteRenduEnvoye = /^rien_a_signaler true$/.test(envoye);
  await p.capture(c, 'compte_rendu_envoye');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
