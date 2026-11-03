// Lot O1 (02/11/2026) : la preuve VIDEO de l'observation des parents, sur la
// pile LOCALE seulement (jamais un apercu Vercel, jamais la production : G5).
//
// Ce que le robot montre :
//   1. l'enseignant entre dans la salle (camera factice de Chromium) ;
//   2. le parent ouvre l'observation et VOIT la salle ; LiveKit le compte parmi
//      les participants, invisible, sans aucune piste publiee ;
//   3. le parent ne parle plus au serveur (ses appels RPC sont coupes : un
//      client qui ne se fermerait pas tout seul), sa visite est vieillie
//      au-dela de la duree de la politique ; la VRAIE tache planifiee
//      `observation-coupure` (pg_cron, chaque minute) appelle la fonction Edge,
//      qui le fait sortir de la salle LiveKit (removeParticipant) ;
//   4. la liste des participants LiveKit avant et apres est ecrite au journal,
//      avec le journal du serveur LiveKit (RemoveParticipant, et aucun retour) ;
//   5. le bandeau de l'enseignant dit qu'un parent observe la seance.
//
// Prerequis du banc (tool/e2e/pile.sh, puis, sur le banc seulement, les
// secrets de la coupure generes localement : coffre observation_coupure_url et
// observation_coupure_secret, OBSERVATION_COUPURE_SECRET dans fonctions.env).
// Aucun secret n'est dans ce fichier. Donnees fictives (prefixe E2E).
// Usage : node tool/e2e/o1_livekit.mjs
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles,
  activerSemantique, sql, nettoyerClassesE2E, COMPTES, MDP } from './commun.mjs';

const p = await parcours('O1 : le parent voit la salle, la tache planifiee le fait sortir (LiveKit local)',
  'o1-observation/livekit');
let code = 1;
const n = Date.now() % 1000000;
const verdicts = {};
const lus = async (page, k = 60) => (await libelles(page)).slice(0, k).join(' | ');

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

/// Jeton LiveKit d'administration de la pile LOCALE (cle de dev de pile.sh).
/// Lister les participants exige un jeton qui nomme la salle.
function jetonAdminLivekit(salle) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const maintenant = Math.floor(Date.now() / 1000);
  const video = { roomCreate: true, roomAdmin: true, roomList: true, ...(salle ? { room: salle } : {}) };
  const corps = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ iss: 'devkey', nbf: maintenant - 10, exp: maintenant + 300, video })}`;
  const signature = crypto.createHmac('sha256', 'secret_e2e_local_livekit_0123456789abcdef').update(corps).digest('base64url');
  return `${corps}.${signature}`;
}
const livekit = async (methode, corps) => (await fetch(`http://127.0.0.1:7880/twirp/livekit.RoomService/${methode}`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${jetonAdminLivekit(corps.room)}`, 'Content-Type': 'application/json' },
  body: JSON.stringify(corps),
})).json();

/// Les participants LiveKit de toutes les salles : identite, cache, pistes.
async function participants() {
  const salles = ((await livekit('ListRooms', {})).rooms ?? []).map((x) => x.name);
  const tous = [];
  for (const salle of salles) {
    for (const x of (await livekit('ListParticipants', { room: salle })).participants ?? []) {
      // Le JSON de LiveKit garde les noms du protocole (can_publish).
      const droits = x.permission ?? {};
      tous.push({ salle, identite: x.identity, cache: !!droits.hidden,
        publie: !!(droits.can_publish ?? droits.canPublish),
        pistes: (x.tracks ?? []).map((t) => t.type ?? t.source).join('+') || 'aucune' });
    }
  }
  return tous;
}
const decrire = (liste) => liste.map((x) => `${x.identite} (${x.salle}, cache=${x.cache}, publie=${x.publie}, pistes=${x.pistes})`).join(' ; ') || 'personne';

const COMPTE = { tuteur: `e2e-o1lk-tuteur-${n}@example.com`, enfant: `e2e-o1lk-enfant-${n}@example.com` };
const ID = {};

function amorcer() {
  nettoyerClassesE2E();
  sql(`insert into public.app_config (key, value) values
         ('observation.activee', 'true'), ('observation.ouverture_parents', 'true'),
         ('observation.max_visits_per_session', '2'),
         ('observation.max_seconds_per_visit', '120'), ('observation.max_total_seconds', '240')
       on conflict (key) do update set value = excluded.value`);
  ID.tuteur = creerCompte(COMPTE.tuteur);
  ID.enfant = creerCompte(COMPTE.enfant);
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${ID.tuteur}', 'E2E-O1LK-T-${n}', 'guardian', '${ID.tuteur}', 'E2E Parent', 'Video', 'active', 'male'),
           ('${ID.enfant}', 'E2E-O1LK-E-${n}', 'student', '${ID.tuteur}', 'E2E Enfant', 'Video', 'active', 'male');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    commit;`);
  ID.nom = `E2E O1 Video ${n}`;
  ID.classe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    values ('${ID.prof}', 'enfant', 5, '${ID.nom}',
            date_part('isodow', now() at time zone 'UTC' + interval '3 days')::smallint, 9, 'UTC')
    returning id`).split('\n')[0];
  sql(`insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.enfant}')`);
  ID.seance = sql(`insert into public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at, status)
    values ('${ID.prof}', now() - interval '5 minutes', now() + interval '55 minutes', 'child',
            '${ID.classe}', now() - interval '25 minutes', 'planned')
    returning id`).split('\n')[0];
  sql(`insert into public.session_participants (session_id, profile_id, role)
       values ('${ID.seance}', '${ID.enfant}', 'student') on conflict do nothing`);
  // L'enfant n'entre pas dans ce robot : sa presence est posee comme le
  // webhook LiveKit l'ecrit (participant_joined), et c'est dit au journal.
  sql(`insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
       values ('${ID.seance}', '${ID.enfant}', 'joined', now() - interval '4 minutes', 'livekit_webhook')`);
  p.dire(`Amorce : classe ${ID.classe} (${ID.nom}), seance ${ID.seance} (en cours), enseignant ${ID.prof}, tuteur ${ID.tuteur}`);
}

const visite = () => sql(`select coalesce(string_agg(visit_number || ':' || coalesce(fin_de_visite, 'ouverte') || ':' || coalesce(duration_seconds::text, '-'), ','), '')
  from public.guardian_session_visit where session_id = '${ID.seance}' and observateur_profile_id = '${ID.tuteur}'`);

try {
  amorcer();
  const vue = { width: 1440, height: 900 };

  // 1. L'enseignant entre dans la salle (camera et micro factices).
  const e = await p.contexte('enseignant', { vue });
  await connecter(e.page, COMPTES.enseignant);
  await e.page.waitForTimeout(3000); await activerSemantique(e.page);
  const rejoindre = await trouver(e.page, new RegExp(`^Rejoindre la salle.*${ID.nom}`), { delai: 20000 });
  if (!rejoindre) throw new Error(`enseignant : pas de « Rejoindre la salle » ; ${await lus(e.page, 20)}`);
  await rejoindre.click();
  await e.page.waitForTimeout(10000); await activerSemantique(e.page);
  // Micro et camera sont fermes a l'entree : l'enseignant les ouvre.
  p.dire(`enseignant, commandes : ${(await libelles(e.page)).filter((x) => /améra|icro/.test(x)).join(' | ')}`);
  for (const outil of [/^Allumer la caméra/, /^Ouvrir le micro/]) {
    const b = await trouver(e.page, outil, { delai: 8000, role: 'button' });
    p.dire(`enseignant, bouton ${outil} : ${b ? await b.getAttribute('aria-label') : 'absent'}`);
    if (b) { await b.click(); await e.page.waitForTimeout(3000); }
  }
  await activerSemantique(e.page);
  await p.capture(e, 'salle');
  const avantParent = await participants();
  p.dire(`LiveKit, enseignant seul : ${decrire(avantParent)}`);
  const prof = avantParent.find((x) => x.identite === ID.prof);
  verdicts.enseignantEnSalle = !!prof && /VIDEO/.test(prof.pistes);

  // 2. Le parent ouvre l'observation et voit la salle.
  const f = await p.contexte('parent', { vue });
  await connecter(f.page, COMPTE.tuteur);
  await f.page.evaluate((r) => { location.hash = `#${r}`; },
    `/tc/observation/${ID.seance}?classe=${ID.classe}&eleve=${ID.enfant}`);
  await f.page.waitForTimeout(3500); await activerSemantique(f.page);
  await cliquer(f.page, /^Observer maintenant$/, { role: 'button', pause: 12000 });
  await activerSemantique(f.page);
  const ecran = await lus(f.page);
  p.dire(`Parent en visite : base=${visite()} ; ecran=${ecran}`);
  await p.capture(f, 'voit_la_salle');
  // Le bandeau de l'enseignant : annonces_observation, relues par la salle.
  await e.page.waitForTimeout(8000); await activerSemantique(e.page);
  const bandeau = (await libelles(e.page)).filter((x) => /observ|parent|visite|regard/i.test(x)).join(' | ');
  p.dire(`Enseignant, apres l'entree du parent : ${bandeau || 'aucun texte d observation'}`);
  await p.capture(e, 'annonce_du_parent');
  verdicts.bandeauEnseignant = /Un parent observe cette séance/.test(bandeau);
  const pendant = await participants();
  p.dire(`LiveKit, parent entre : ${decrire(pendant)}`);
  const parent = pendant.find((x) => x.identite === ID.tuteur);
  if (!parent) throw new Error('LiveKit ne compte pas le parent : rien a couper, preuve impossible');
  verdicts.parentDansLaSalle = !!parent && parent.cache && !parent.publie && parent.pistes === 'aucune';
  // L'image elle-meme ne se lit pas par l'accessibilite : la capture la
  // montre ; le texte dit seulement qu'aucune vignette n'est vide.
  verdicts.parentVoitLaSalle = !/Vidéo indisponible|Caméra fermée|Enseignant Pas encore dans la salle/.test(ecran)
    && /Son reçu/.test(ecran);

  // 3. Le parent ne parle plus au serveur (un client qui ne se fermerait pas
  // seul) ; sa visite est vieillie au-dela des 120 s de la politique. Seule la
  // tache planifiee peut le faire sortir.
  await f.page.route('**/rest/v1/rpc/**', (r) => r.abort());
  sql(`update public.guardian_session_visit set entered_at = now() - interval '125 seconds'
       where session_id = '${ID.seance}' and observateur_profile_id = '${ID.tuteur}' and left_at is null`);
  const depart = sql(`select coalesce(max(runid), 0) from cron.job_run_details d join cron.job j using (jobid) where j.jobname = 'observation-coupure'`);
  const departReponses = sql(`select coalesce(max(id), 0) from net._http_response`);
  const departLivekit = new Date().toISOString();
  p.dire(`Visite vieillie de 125 s ; appels RPC du parent coupes ; on attend la tache planifiee (derniere execution : ${depart})`);
  let apres = pendant;
  const limite = Date.now() + 150000;
  while (Date.now() < limite) {
    await f.page.waitForTimeout(5000);
    apres = await participants();
    if (!apres.some((x) => x.identite === ID.tuteur)) break;
  }
  const execs = sql(`select string_agg(d.status || ' ' || to_char(d.start_time at time zone 'utc', 'HH24:MI:SS'), ', ' order by d.runid)
    from cron.job_run_details d join cron.job j using (jobid) where j.jobname = 'observation-coupure' and d.runid > ${depart}`);
  const reponses = sql(`select string_agg(status_code || ' ' || left(content, 120), ' ; ' order by id) from net._http_response
    where id > ${departReponses} and content like '%coupures%'`);
  // Le journal du serveur LiveKit local : qui a fait sortir le parent, et
  // s'il est revenu ensuite (son jeton restait valide, la visite ayant ete
  // vieillie a la main).
  const brut = spawnSync('docker', ['logs', '--since', departLivekit, 'e2e-livekit'], { encoding: 'utf8' });
  const journalLivekit = `${brut.stdout}\n${brut.stderr}`.split('\n')
    .filter((l) => l.includes(ID.tuteur) && /RemoveParticipant|starting RTC session|participant closing/.test(l))
    .map((l) => l.split('\t').slice(0, 1).concat(l.match(/RemoveParticipant|starting RTC session|participant closing/)).join(' '));
  p.dire(`Journal LiveKit pour le parent : ${journalLivekit.join(' ; ') || 'rien'}`);
  p.dire(`Tache planifiee observation-coupure, executions : ${execs || 'aucune'}`);
  p.dire(`Reponses de la fonction Edge (pg_net) : ${reponses || 'aucune lue'}`);
  p.dire(`Base : ${visite()}`);
  p.dire(`LiveKit, apres la tache planifiee : ${decrire(apres)}`);
  await f.page.waitForTimeout(3000); await activerSemantique(f.page);
  p.dire(`Ecran du parent apres la sortie : ${await lus(f.page, 30)}`);
  await p.capture(f, 'sorti_par_la_tache');
  verdicts.sortiParLaTache = !apres.some((x) => x.identite === ID.tuteur)
    && apres.some((x) => x.identite === ID.prof)
    && /^1:quota_atteint:120$/.test(visite())
    && /succeeded/.test(execs ?? '') && /"sortis":1/.test(reponses ?? '')
    && journalLivekit.some((l) => /RemoveParticipant/.test(l))
    && !journalLivekit.some((l) => /starting RTC session/.test(l));

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = ['enseignantEnSalle', 'bandeauEnseignant', 'parentDansLaSalle', 'parentVoitLaSalle', 'sortiParLaTache'].every((k) => verdicts[k] === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
