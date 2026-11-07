// SALLE-2-ENTRETIEN (07/11/2026) : « Faisons connaissance », sur la pile LOCALE,
// donnees de test seulement.
//
// En francais, a 1440 x 900 puis 390 x 844, chaque fois avec une candidate
// neuve (Salle de verification et d'entretien, « Entretien a planifier »,
// langue maternelle « francais ») :
//   D1. la direction ouvre « Creneaux d'entretien » ; D2. « Ouvrir un
//       creneau » : cote femmes, jour, heure, « Francais », deux fondatrices ;
//       la base porte le creneau « francais » (20261119200100) ;
//   C1. la candidate, sur /attente, voit « Choisir le moment de notre
//       entretien » ; C2. « Faisons connaissance » liste le creneau ; elle le
//       reserve ; la base porte l'entretien et l'etat « entretien_planifie » ;
//   A.  le passage des avis (private.entretien_avis_passer) pose la
//       notification et le courriel « entretien_reserve » de la candidate ;
//   C3. le debut ramene a dans 5 minutes : « Rejoindre l'entretien » ouvre
//       /salle (redirection de H) ;
//   D3. la direction voit « Rejoindre l'entretien » et « Ecrire mon compte
//       rendu » ; elle ecrit un compte rendu complet ; la base le porte.
// En arabe, aux deux largeurs : les ecrans (creneaux de la direction, lien du
// portail, page du candidat), le creneau pose en SQL local.
//
// Pile : la migration 20261119200000 exige PUSH-1 (PR 284), et « Rejoindre »
// la redirection /salle de SALLE-3-ACCUEIL (PR 300). Tant qu'ils ne sont pas
// dans main, la pile se monte sur cette branche fusionnee en local avec eux
// (passage vert du 07/11/2026 : 63 controles, captures ci-contre).
// Usage : node tool/e2e/salle2_entretien.mjs   (E2E_S2_VARIANTE=1440_fr ...)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, cliquer, attendreTexte, ouvrir,
  activerSemantique, amenerEnVue, sql, COMPTES, DEPOT, MDP } from './commun.mjs';

const VARIANTES = [
  { nom: '1440_fr', vue: { width: 1440, height: 900 }, langue: 'fr-FR', code: 'fr', complet: true },
  { nom: '390_fr', vue: { width: 390, height: 844 }, langue: 'fr-FR', code: 'fr', complet: true },
  { nom: '1440_ar', vue: { width: 1440, height: 900 }, langue: 'ar-SA', code: 'ar', complet: false },
  { nom: '390_ar', vue: { width: 390, height: 844 }, langue: 'ar-SA', code: 'ar', complet: false },
].filter((v) => !process.env.E2E_S2_VARIANTE || v.nom === process.env.E2E_S2_VARIANTE);

const I18N = Object.fromEntries(['fr', 'ar'].map((c) => [c,
  JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${c}.i18n.json`), 'utf8'))]));
const cle = (code, chemin) => chemin.split('.').reduce((o, k) => o[k], I18N[code]);
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
// Les espaces (ordinaires ou insecables) se valent ; les isolants
// bidirectionnels sont retires.
const motif = (code, chemin) => new RegExp(echapper(cle(code, chemin)
  .replace(/[⁨⁩]/g, '')).replace(/[  ]/g, '[\\s\\u00a0]'));

const p = await parcours('SALLE-2 (Faisons connaissance)', 'salle2-entretien');
const n = Date.now() % 1000000;
const JOUR = new Date().toISOString().slice(0, 10);
let direction;
let hafsa;

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

const matricule = () => `RA-26-${String(1000 + Math.floor(Math.random() * 9000))}`;

function amorcer() {
  direction = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  hafsa = creerCompte(`e2e-s2-hafsa-${n}@example.com`);
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${hafsa}', '${matricule()}', 'accountant', 'Hafsa', 'Fondatrice${n}', 'active', 'female')`);
  for (const id of [direction, hafsa]) {
    sql(`insert into public.personnel_fondateurs (profile_id, fondateur, modifie_par)
         values ('${id}', true, '${direction}')
         on conflict (profile_id) do update set fondateur = true`);
  }
  sql(`update public.app_config set value = 'true'::jsonb where key = 'entretiens.regle_fondateurs_active'`);
  sql(`update public.app_config set value = '2'::jsonb where key = 'entretiens.fondateurs_minimum'`);
  verifier(sql(`select 'francais' = any (private.langues_entretien())`) === 't',
    'amorce : « francais » est une langue de creneau (20261119200100 installee)');
}

function candidate(v) {
  const courriel = `e2e-s2-cand-${v.nom}-${n}@example.com`;
  const id = creerCompte(courriel);
  const nom = `S2${v.nom.replace('_', '')}x${n}`;
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, langue_communication)
       values ('${id}', '${matricule()}', 'teacher', 'Khadija', '${nom}', 'pending_kyc', 'female', '${v.code}')`);
  sql(`insert into public.teacher_profiles (profile_id, country, languages, kyc_status, timezone_iana)
       values ('${id}', 'FR', '{fr}', 'pending', 'Europe/Paris')`);
  const ref = sql(`insert into public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source, pays_residence)
       values ('enseignant', '${id}', 'female', 'Khadija ${nom}', 'verifications', 'entretien_a_planifier',
               'lien_public', 'FR') returning reference`).split('\n')[0];
  const cid = sql(`select id from public.candidatures where reference = '${ref}'`);
  sql(`insert into public.candidature_reponses (candidature_id, questionnaire_version, reponses, source)
       values ('${cid}', 'salle-examen-2', '{"langueMaternelle": "francais", "languesExplication": []}', 'candidat')`);
  p.dire(`Amorce ${v.nom} : Khadija ${nom}, ${ref}`);
  return { id, ref, cid, courriel };
}

async function voir(c, texte, nom) {
  const e = texte ? await trouver(c.page, texte, { delai: 15000 }) : null;
  if (e) await amenerEnVue(c.page, e);
  await c.page.waitForTimeout(700);
  await p.capture(c, nom);
}

async function cocher(page, nom) {
  const o = await trouver(page, nom, { delai: 8000 });
  verifier(o !== null, `l'option ${nom}`);
  await amenerEnVue(page, o); await o.click(); await page.waitForTimeout(700);
}

// Le jour et l'heure du creneau : un jour propre a chaque variante, pour que
// les personnes qui menent l'entretien ne soient jamais occupees deux fois.
async function choisirJourEtHeure(page, decalage) {
  const jour = await trouver(page, /^Jour\b/, { delai: 8000 });
  verifier(jour !== null, 'le champ « Jour »');
  await amenerEnVue(page, jour); await jour.click(); await page.waitForTimeout(1200);
  await activerSemantique(page);
  const dans = new Date(Date.now() + (3 + ((n + decalage) % 20)) * 86400000);
  if (dans.getMonth() !== new Date().getMonth()) {
    const suivant = await trouver(page, /mois suivant|Next month/i, { delai: 4000 });
    if (suivant) { await suivant.click(); await page.waitForTimeout(800); }
  }
  const jourNum = await trouver(page, new RegExp(`^${dans.getDate()}\\b`), { delai: 6000 });
  verifier(jourNum !== null, `calendrier : le jour ${dans.getDate()}`);
  await jourNum.click(); await page.waitForTimeout(600);
  const ok = await trouver(page, /^OK$/i, { delai: 4000 });
  if (ok) { await ok.click(); await page.waitForTimeout(1000); }
  await activerSemantique(page);
  const heure = await trouver(page, /^Heure\b/, { delai: 8000, role: 'button' });
  verifier(heure !== null, 'le menu « Heure »');
  await amenerEnVue(page, heure); await heure.click(); await page.waitForTimeout(900);
  const minutes = 6 * 60 + 30 * ((n + decalage) % 32);
  const libelle = `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;
  const h = await trouver(page, new RegExp(`^${libelle}$`), { delai: 6000, role: 'menuitem' })
    ?? await trouver(page, new RegExp(`^${libelle}$`), { delai: 3000 });
  verifier(h !== null, `menu : ${libelle}`);
  await amenerEnVue(page, h); await h.click(); await page.waitForTimeout(900);
}

// Un creneau pose en SQL local (variantes arabes) : cote femmes, francais,
// direction et Hafsa, dans 5 a 25 jours.
function creneauSql(decalage) {
  const id = sql(`insert into public.entretien_creneaux (cote, debut, duree_minutes, langues, ouvert_par)
    values ('female', date_trunc('hour', now()) + interval '${5 + (decalage % 20)} days 9 hours', 45,
            '{francais}', '${direction}') returning id`).split('\n')[0];
  sql(`insert into public.entretien_creneau_participants (creneau_id, profile_id)
       values ('${id}', '${direction}'), ('${id}', '${hafsa}')`);
  return id;
}

async function variante(v, rang) {
  const tag = `${JOUR}_${v.nom}`;
  const cand = candidate(v);
  const d = await p.contexte(`direction_${v.nom}`, { vue: v.vue, langue: v.langue });
  d.page.on('response', async (r) => {
    if (/rpc\/(ouvrir_creneau|annuler_creneau|langues_creneaux|lister_creneaux|ecrire_compte_rendu)/.test(r.url())) {
      p.dire(`  rpc ${r.status()} ${r.url().replace(/^.*rpc\//, '')} ${(await r.text().catch(() => '')).slice(0, 240)}`);
    }
  });
  await connecter(d.page, COMPTES.direction);
  await ouvrir(d.page, '/#/admin/personnes/candidatures/creneaux');
  await d.page.waitForTimeout(4000); await activerSemantique(d.page);
  verifier(await attendreTexte(d.page, motif(v.code, 'admin.candidatures.creneaux.titre'), 30000),
    `${v.nom} : la page « Creneaux d'entretien »`);
  await voir(d, null, `${tag}_D1_creneaux`);

  if (v.complet) {
    await cliquer(d.page, /^Ouvrir un créneau$/, { pause: 1800 });
    await activerSemantique(d.page);
    verifier(await attendreTexte(d.page, /Langues de l'entretien/, 15000), `${v.nom} : la feuille, ses langues`);
    await p.capture(d, `${tag}_D2a_feuille`);
    await cocher(d.page, /^Femmes$/);
    await choisirJourEtHeure(d.page, rang * 7 + (v.vue.width === 390 ? 3 : 0));
    await cocher(d.page, /^Français$/);
    await cocher(d.page, /E2E Direction Locale/);
    await cocher(d.page, new RegExp(`Hafsa Fondatrice${n}`));
    await cliquer(d.page, /^Ouvrir ce créneau$/, { pause: 400 });
    await activerSemantique(d.page);
    verifier(await attendreTexte(d.page, /Créneau ouvert\./, 8000), `${v.nom} : « Creneau ouvert »`);
    await p.capture(d, `${tag}_D2b_ouvert`);
    verifier(sql(`select count(*) from public.entretien_creneaux
                  where ouvert_par = '${direction}' and langues = '{francais}' and annule_le is null
                    and session_id is null and ouvert_le > now() - interval '5 minutes'`) >= '1',
      `${v.nom} : la base porte un creneau « francais » libre`);
  } else {
    creneauSql(rang * 7);
    await d.page.reload(); await d.page.waitForTimeout(4000); await activerSemantique(d.page);
    await voir(d, null, `${tag}_D2_liste`);
  }

  // La candidate.
  const c = await p.contexte(`candidate_${v.nom}`, { vue: v.vue, langue: v.langue });
  c.page.on('response', async (r) => {
    if (/rpc\/(creneaux_entretien_disponibles|reserver_creneau|mon_entretien|autoriser_jeton)/.test(r.url())) {
      p.dire(`  rpc ${r.status()} ${r.url().replace(/^.*rpc\//, '')} ${(await r.text().catch(() => '')).slice(0, 240)}`);
    }
  });
  await connecter(c.page, cand.courriel);
  await ouvrir(c.page, '/#/attente');
  await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, motif(v.code, 'recrutement.entretien.portailChoisir'), 30000),
    `${v.nom} : le portail propose « Choisir le moment de notre entretien »`);
  await voir(c, motif(v.code, 'recrutement.entretien.portailChoisir'), `${tag}_C1_portail`);
  await cliquer(c.page, motif(v.code, 'recrutement.entretien.portailChoisir'), { pause: 3000 });
  await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, motif(v.code, 'recrutement.entretien.reserver'), 30000),
    `${v.nom} : « Faisons connaissance » propose de reserver`);
  verifier(!(await attendreTexte(c.page, /Salle d'examen|Salle de vérification|قاعة/, 1500)),
    `${v.nom} : aucun nom de salle sur « Faisons connaissance »`);
  await p.capture(c, `${tag}_C2a_moments`);
  if (!v.complet) { await d.ctx.close(); await c.ctx.close(); return; }

  // Reserver le premier moment propose.
  const moment = await trouver(c.page, /à \d{2}:\d{2}|\d{2}:\d{2} [–-] \d{2}:\d{2}|\d{2}:\d{2}/, { delai: 8000 });
  verifier(moment !== null, `${v.nom} : un moment ouvert est liste`);
  await amenerEnVue(c.page, moment); await moment.click(); await c.page.waitForTimeout(700);
  await cliquer(c.page, motif('fr', 'recrutement.entretien.reserver'), { pause: 3500 });
  await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, motif('fr', 'recrutement.entretien.votreEntretien'), 20000),
    `${v.nom} : « Votre entretien » apres la reservation`);
  await p.capture(c, `${tag}_C2b_reserve`);
  const session = sql(`select session_id from public.entretiens where candidature_id = '${cand.cid}' and issue is null`);
  verifier(session !== '', `${v.nom} : la base porte l'entretien`);
  verifier(sql(`select etat from public.candidatures where id = '${cand.cid}'`) === 'entretien_planifie',
    `${v.nom} : la candidature passe a « entretien_planifie »`);

  // Les avis (la tache planifiee les envoie chaque minute ; on la joue).
  sql(`select private.entretien_avis_passer(clock_timestamp())`);
  verifier(sql(`select count(*) from public.notifications where destinataire = '${cand.id}'
                  and evenement = 'entretien_reserve' and destination = '/attente/entretien'`) === '1',
    `${v.nom} : la notification « entretien_reserve » de la candidate`);
  verifier(sql(`select count(*) from public.courriels_sortants where destinataire_profil = '${cand.id}'
                  and modele = 'entretien_reserve' and donnees ->> 'fuseau' = 'Europe/Paris'`) === '1',
    `${v.nom} : le courriel « entretien_reserve », a l'heure de Paris`);
  verifier(sql(`select count(*) from public.notifications where destinataire = '${direction}'
                  and evenement = 'entretien_reserve' and params ->> 'portee' = 'direction'
                  and params ->> 'session_id' = '${session}'`) === '1',
    `${v.nom} : la direction est avisee`);

  // Rejoindre : le debut ramene a dans 5 minutes.
  // L'ouverture de la salle (join_opens_at) suit le debut, comme a la
  // planification (10 minutes avant).
  sql(`update public.sessions set started_at = now() + interval '5 minutes',
         ended_at = now() + interval '50 minutes', join_opens_at = now() - interval '5 minutes'
       where id = '${session}'`);
  await c.page.reload(); await c.page.waitForTimeout(5000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, motif('fr', 'recrutement.entretien.rejoindre'), 30000),
    `${v.nom} : « Rejoindre l'entretien » 5 minutes avant`);
  await voir(c, motif('fr', 'recrutement.entretien.rejoindre'), `${tag}_C3a_rejoindre`);
  await cliquer(c.page, motif('fr', 'recrutement.entretien.rejoindre'), { pause: 6000 });
  verifier(/#\/salle/.test(c.page.url()), `${v.nom} : la candidate arrive dans /salle (${c.page.url()})`);
  await activerSemantique(c.page);
  await p.capture(c, `${tag}_C3b_salle`);

  // La direction : rejoindre, puis le compte rendu (apres le debut).
  sql(`update public.sessions set started_at = now() - interval '1 minute',
         ended_at = now() + interval '44 minutes', join_opens_at = now() - interval '11 minutes'
       where id = '${session}'`);
  await ouvrir(d.page, `/#/admin/personnes/candidatures/${encodeURIComponent(cand.ref)}`);
  await d.page.waitForTimeout(5000); await activerSemantique(d.page);
  verifier(await attendreTexte(d.page, /^Rejoindre l'entretien$/, 30000),
    `${v.nom} : la direction voit « Rejoindre l'entretien »`);
  await voir(d, /^Écrire mon compte rendu$/, `${tag}_D3a_entretien`);
  await cliquer(d.page, /^Écrire mon compte rendu$/, { pause: 1800 });
  await activerSemantique(d.page);
  const champ = d.page.locator('textarea, input[type="text"]').first();
  await champ.fill('Lecture soignée, tajwid appliqué, échange clair.');
  await cocher(d.page, /^Avis favorable$/);
  await p.capture(d, `${tag}_D3b_feuille_compte_rendu`);
  await cliquer(d.page, /^Enregistrer mon compte rendu$/, { pause: 2500 });
  verifier(sql(`select count(*) from public.entretien_comptes_rendus
                where session_id = '${session}' and avis = 'favorable'`) === '1',
    `${v.nom} : la base porte le compte rendu (avis favorable)`);
  await voir(d, /Lecture soignée/, `${tag}_D3c_compte_rendu`);
  await d.ctx.close(); await c.ctx.close();
}

let code = 1;
try {
  amorcer();
  let rang = 0;
  for (const v of VARIANTES) await variante(v, rang++);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
