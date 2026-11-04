// V2-a-bis (04/11/2026) : la fiche candidature (ADM-21) dit le refus
// « personne_occupee » de V1-c (20261109800000) avec le nom et l'heure, dans
// le fuseau de l'appareil ; sur la pile LOCALE (V1-c y est appliquee).
//
// Ce que le parcours montre, connecte comme la direction (une femme), a 1440 x
// 900 puis 390 x 844, chaque fois sur une candidate neuve « Entretien a
// planifier » :
//   1. Hafsa (comptable fondatrice) est deja dans un entretien a l'heure
//      choisie (seance ecrite en SQL local, comme l'aurait fait un premier
//      geste) ;
//   2. planifier avec Hafsa a cette heure : le serveur refuse, la feuille dit
//      « Hafsa ... a deja une seance ou un entretien le ..., de HH:MM a HH:MM
//      (heure de cet appareil) » ; la base n'a aucun entretien pour la
//      candidate ;
//   3. la meme feuille, trois heures plus tard : l'entretien est planifie.
// Le navigateur est a l'heure de Paris (commun.mjs) : l'heure dite est celle
// de l'appareil, pas l'UTC du serveur. Les deux largeurs tournent dans ce meme
// fuseau, mais chacune choisit son propre moment (`moment(largeur)`) : deux
// candidates, deux seances, deux heures differentes, voulues, pour que le
// second passage ne tombe pas sur l'entretien planifie par le premier.
//
// Amorce (SQL local) : deux comptables actives, fondatrices, du meme cote que
// la direction (Hafsa, occupee, et Salma, libre) ; une candidate par largeur ; la
// seance qui occupe Hafsa. Rien n'est efface.
// Usage : node tool/e2e/v2a_personne_occupee.mjs
import { parcours, connecter, trouver, cliquer, attendreTexte, ouvrir,
  activerSemantique, amenerEnVue, sql, COMPTES, MDP } from './commun.mjs';

const JOUR = new Date().toISOString().slice(0, 10);
const p = await parcours('V2-a-bis (personne occupee, nom et heure)', 'v2a-personne-occupee');
const n = Date.now() % 1000000;
let direction;
let hafsa;
let salma;

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
  hafsa = creerCompte(`e2e-v2abis-hafsa-${n}@example.com`);
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${hafsa}', '${matricule()}', 'accountant', 'Hafsa', 'Occupee${n}', 'active', 'female')`);
  // Une seconde fondatrice neuve : la direction de test participe a des
  // entretiens laisses par d'autres passages, elle pourrait etre occupee.
  salma = creerCompte(`e2e-v2abis-salma-${n}@example.com`);
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${salma}', '${matricule()}', 'accountant', 'Salma', 'Libre${n}', 'active', 'female')`);
  for (const id of [hafsa, salma]) {
    sql(`insert into public.personnel_fondateurs (profile_id, fondateur, modifie_par)
         values ('${id}', true, '${direction}')
         on conflict (profile_id) do update set fondateur = true`);
  }
  verifier(sql(`select pg_get_constraintdef(oid) ~ 'session_type' from pg_constraint
                where conname = 'sessions_no_teacher_overlap'`) === 't',
    'amorce : V1-c est appliquee sur la pile locale');
}

// Le jour (dans le mois courant ou le suivant) et l'heure de ce passage.
function moment(decalage) {
  const jours = 4 + ((n + decalage) % 15);
  const dans = new Date(Date.now() + jours * 86400000);
  const minutes = 8 * 60 + 30 * ((n + decalage) % 16);
  const hh = String(Math.floor(minutes / 60)).padStart(2, '0');
  const mm = String(minutes % 60).padStart(2, '0');
  const ymd = `${dans.getFullYear()}-${String(dans.getMonth() + 1).padStart(2, '0')}-${String(dans.getDate()).padStart(2, '0')}`;
  return { dans, minutes, libelle: `${hh}:${mm}`, ymd };
}

function candidate(largeur) {
  const id = creerCompte(`e2e-v2abis-cand-${largeur}-${n}@example.com`);
  const nom = `Occ${largeur}x${n}`;
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${id}', '${matricule()}', 'teacher', 'Khadija', '${nom}', 'pending_kyc', 'female')`);
  const ref = sql(`insert into public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source, pays_residence)
       values ('enseignant', '${id}', 'female', 'Khadija ${nom}', 'verifications', 'entretien_a_planifier',
               'lien_public', 'FR') returning reference`).split('\n')[0];
  const cid = sql(`select id from public.candidatures where reference = '${ref}'`);
  p.dire(`Amorce ${largeur} : Khadija ${nom}, ${ref}`);
  return { ref, cid };
}

// Hafsa est deja dans un entretien a ce moment (heure de Paris), 45 min.
function occuper(m) {
  const s = sql(`insert into public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
       values ('${direction}',
               (timestamp '${m.ymd} ${m.libelle}' at time zone 'Europe/Paris'),
               (timestamp '${m.ymd} ${m.libelle}' at time zone 'Europe/Paris') + interval '45 minutes',
               'planned', 'entretien',
               (timestamp '${m.ymd} ${m.libelle}' at time zone 'Europe/Paris') - interval '10 minutes')
       returning id`).split('\n')[0];
  sql(`insert into public.session_participants (session_id, profile_id, role)
       values ('${s}', '${hafsa}', 'intervieweur')`);
  p.dire(`  Hafsa occupee le ${m.ymd} a ${m.libelle} (Paris), seance ${s}`);
}

async function choisirJour(page, dans) {
  const jour = await trouver(page, /^Jour\b/, { delai: 8000 });
  verifier(jour !== null, 'le champ « Jour »');
  await amenerEnVue(page, jour); await jour.click(); await page.waitForTimeout(1200);
  await activerSemantique(page);
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
}

async function choisirHeure(page, libelle) {
  const heure = await trouver(page, /^(Heure|\d\d:\d\d)\b/, { delai: 8000, role: 'button' });
  verifier(heure !== null, 'le menu de l\'heure');
  await amenerEnVue(page, heure); await heure.click(); await page.waitForTimeout(900);
  const h = await trouver(page, new RegExp(`^${libelle}$`), { delai: 6000, role: 'menuitem' })
    ?? await trouver(page, new RegExp(`^${libelle}$`), { delai: 3000 });
  verifier(h !== null, `menu : ${libelle}`);
  await amenerEnVue(page, h); await h.click(); await page.waitForTimeout(900);
}

async function cocher(page, nom) {
  const o = await trouver(page, nom, { delai: 8000 });
  verifier(o !== null, `l'option ${nom}`);
  await amenerEnVue(page, o); await o.click(); await page.waitForTimeout(700);
}

async function passage(largeur, hauteur) {
  const tag = `${JOUR}_${largeur}`;
  const cand = candidate(largeur);
  const m = moment(largeur);
  occuper(m);
  const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
  c.page.on('response', async (r) => {
    if (/rpc\/planifier_entretien/.test(r.url())) {
      p.dire(`  rpc ${r.status()} planifier_entretien ${(await r.text().catch(() => '')).slice(0, 300)}`);
    }
  });
  await connecter(c.page, COMPTES.direction);
  await ouvrir(c.page, `/#/admin/personnes/candidatures/${encodeURIComponent(cand.ref)}`);
  await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Aucun entretien planifié/, 30000),
    `${largeur} : « Aucun entretien planifié »`);

  await cliquer(c.page, /^Planifier l'entretien$/, { pause: 1500 });
  await activerSemantique(c.page);
  await choisirJour(c.page, m.dans);
  await choisirHeure(c.page, m.libelle);
  await cocher(c.page, new RegExp(`Salma Libre${n}`));
  await cocher(c.page, new RegExp(`Hafsa Occupee${n}`));
  await cliquer(c.page, /^Planifier$/, { pause: 2500 });
  await activerSemantique(c.page);
  const fin = `${String(Math.floor((m.minutes + 45) / 60)).padStart(2, '0')}:${String((m.minutes + 45) % 60).padStart(2, '0')}`;
  const attendu = new RegExp(`Hafsa Occupee${n}.{0,3} a déjà une séance ou un entretien le .*de\\s${m.libelle}\\sà\\s${fin}\\s\\(heure de cet appareil\\)`);
  verifier(await attendreTexte(c.page, attendu, 10000),
    `${largeur} : le refus dit le nom et l'heure de l'appareil (${m.libelle} à ${fin})`);
  // Le robot ne fait pas defiler : la feuille ramene elle-meme le bandeau en
  // vue (reserve de garde-cap du 04/11, coupe a 390).
  await c.page.waitForTimeout(900);
  await p.capture(c, `${tag}_1_refus_personne_occupee`);
  verifier(sql(`select count(*) from public.entretiens where candidature_id = '${cand.cid}'`) === '0',
    `${largeur} : la base n'a aucun entretien pour la candidate`);

  // Trois heures plus tard : libre.
  const plusTard = `${String(Math.floor(m.minutes / 60) + 3).padStart(2, '0')}:${String(m.minutes % 60).padStart(2, '0')}`;
  await choisirHeure(c.page, plusTard);
  await cliquer(c.page, /^Planifier$/, { pause: 400 });
  await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Entretien planifié\./, 6000),
    `${largeur} : trois heures plus tard, l'entretien est planifié`);
  await p.capture(c, `${tag}_2_planifie_plus_tard`);
  verifier(sql(`select count(*) from public.entretiens where candidature_id = '${cand.cid}' and issue is null`) === '1',
    `${largeur} : la base porte l'entretien`);
  await c.ctx.close();
}

let code = 1;
try {
  amorcer();
  await passage(1440, 900);
  await passage(390, 844);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
