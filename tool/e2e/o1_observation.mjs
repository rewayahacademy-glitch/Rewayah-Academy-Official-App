// Lot O1 (02/11/2026) : l'observation des parents, sur la pile LOCALE
// seulement (jamais un apercu Vercel, jamais la production : G5).
//
// Ce que le robot montre, a 1440 x 900 (VUE=390x844 pour le telephone) :
//   1. le parent ouvre la porte d'observation de la seance en cours de son
//      enfant, et entre (la visite s'ouvre en base) ;
//   2. la visite est coupee par le SERVEUR a la duree de la politique
//      (couper_visites_observation_echues, comme la tache planifiee) ;
//   3. une seconde visite ecourtee compte ; la troisieme est refusee ;
//   4. l'enseignant est prevenu (annonce) ; l'enfant concerne aussi, un autre
//      enfant non ;
//   5. la direction regarde, invisible, depuis le planning.
//
// LiveKit n'a pas pu etre lance sur ce banc (Docker Hub, 429) : la video
// n'est pas montree, et la sortie reelle d'un participant (removeParticipant)
// n'est pas prouvee ici. Donnees fictives (prefixe E2E), comptes neufs a chaque
// passage ; rien n'est efface. Usage : node tool/e2e/o1_observation.mjs
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, ouvrir,
  activerSemantique, taper, sql, nettoyerClassesE2E, COMPTES, MDP } from './commun.mjs';

const [largeur, hauteur] = (process.env.VUE ?? '1440x900').split('x').map(Number);
const p = await parcours(`O1 : observation des parents (${largeur} x ${hauteur})`,
  `o1-observation/${largeur}`);
let code = 1;
const n = Date.now() % 1000000;
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

const COMPTE = {
  tuteur: `e2e-o1-tuteur-${n}@example.com`,
  enfant: `e2e-o1-enfant-${n}@example.com`,
  autre: `e2e-o1-autre-${n}@example.com`,
};
const ID = {};

function amorcer() {
  nettoyerClassesE2E();
  // La politique de l'academie, comme en production (relue le 02/11).
  sql(`insert into public.app_config (key, value) values
         ('observation.activee', 'true'), ('observation.max_visits_per_session', '2'),
         ('observation.max_seconds_per_visit', '120'), ('observation.max_total_seconds', '240')
       on conflict (key) do update set value = excluded.value`);
  ID.tuteur = creerCompte(COMPTE.tuteur);
  ID.enfant = creerCompte(COMPTE.enfant);
  ID.autre = creerCompte(COMPTE.autre);
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris'), ('${ID.autre}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${ID.tuteur}', 'E2E-O1-T-${n}', 'guardian', '${ID.tuteur}', 'E2E Parent', 'O1', 'active', 'male'),
           ('${ID.enfant}', 'E2E-O1-E-${n}', 'student', '${ID.tuteur}', 'E2E Enfant', 'O1', 'active', 'male'),
           ('${ID.autre}', 'E2E-O1-X-${n}', 'student', '${ID.autre}', 'E2E Autre', 'O1', 'active', 'male');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    commit;`);
  ID.classe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    values ('${ID.prof}', 'enfant', 5, 'E2E O1 Classe ${n}',
            date_part('isodow', now() at time zone 'UTC' + interval '3 days')::smallint, 9, 'UTC')
    returning id`).split('\n')[0];
  sql(`insert into public.groupe_membres (groupe_id, student_id) values
         ('${ID.classe}', '${ID.enfant}'), ('${ID.classe}', '${ID.autre}')`);
  ID.seance = sql(`insert into public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at, status)
    values ('${ID.prof}', now() - interval '5 minutes', now() + interval '55 minutes', 'child',
            '${ID.classe}', now() - interval '25 minutes', 'planned')
    returning id`).split('\n')[0];
  sql(`insert into public.session_participants (session_id, profile_id, role)
       values ('${ID.seance}', '${ID.enfant}', 'student'), ('${ID.seance}', '${ID.autre}', 'student')
       on conflict do nothing`);
  // LiveKit absent du banc : la presence de l'enfant est posee comme le
  // webhook LiveKit l'ecrit (participant_joined), et c'est dit au journal.
  sql(`insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
       values ('${ID.seance}', '${ID.enfant}', 'joined', now() - interval '4 minutes', 'livekit_webhook')`);
  p.dire(`Amorce : classe ${ID.classe}, seance ${ID.seance} (en cours), tuteur ${ID.tuteur}, enfant ${ID.enfant}`);
}

/// Va a une route de l'application (routage par fragment), comme un lien.
async function aller(page, route) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, route);
  await page.waitForTimeout(3500);
  await activerSemantique(page);
}

const visites = () => sql(`select coalesce(string_agg(visit_number || ':' || coalesce(fin_de_visite, 'ouverte') || ':' || coalesce(duration_seconds::text, '-'), ',' order by visit_number), '')
  from public.guardian_session_visit where session_id = '${ID.seance}' and observateur_profile_id = '${ID.tuteur}'`);

try {
  amorcer();
  const vue = { width: largeur, height: hauteur };

  // 0. Interrupteur de l'academie ferme (app_config.observation.activee =
  // false) : la porte dit « pas encore ouverte » et ne propose rien ; le
  // serveur refuse l'entree. Puis on l'ouvre (la ligne que posera le pilote).
  const f = await p.contexte('parent', { vue });
  await connecter(f.page, COMPTE.tuteur);
  sql(`update public.app_config set value = 'false'::jsonb, updated_at = now() where key = 'observation.activee'`);
  await aller(f.page, `/tc/observation/${ID.seance}?classe=${ID.classe}&eleve=${ID.enfant}`);
  const ferme = await lus(f.page);
  p.dire(`Interrupteur ferme : ${ferme}`);
  await p.capture(f, 'interrupteur_ferme');
  verdicts.interrupteurFerme = /Observation pas encore ouverte/.test(ferme) && !/Observer maintenant/.test(ferme)
    && visites() === '';
  sql(`update public.app_config set value = 'true'::jsonb, updated_at = now() where key = 'observation.activee'`);
  await f.page.reload();
  await f.page.waitForTimeout(3500);
  await activerSemantique(f.page);

  // 1. Le parent ouvre la porte d'observation et entre.
  p.dire(`Porte : ${await lus(f.page)}`);
  await p.capture(f, 'porte_observation');
  await cliquer(f.page, /^Observer maintenant$/, { role: 'button', pause: 5000 });
  await activerSemantique(f.page);
  p.dire(`Apres l'entree : base=${visites()} ; ecran=${await lus(f.page)}`);
  await p.capture(f, 'visite_en_cours');
  verdicts.entree = /^1:ouverte/.test(visites());

  // 2. La coupure serveur : la visite a commence il y a 125 s (au-dela des
  // 120 s de la politique) ; on appelle la fonction de la tache planifiee.
  sql(`update public.guardian_session_visit set entered_at = now() - interval '125 seconds'
       where session_id = '${ID.seance}' and observateur_profile_id = '${ID.tuteur}' and left_at is null`);
  const sorties = sql(`select public.couper_visites_observation_echues('ws://livekit.local', 'ws://livekit.local')`);
  p.dire(`Coupure serveur : sorties rendues = ${sorties} ; base=${visites()}`);
  verdicts.coupeeServeur = /^1:quota_atteint:120$/.test(visites()) && sorties.includes(ID.tuteur);
  // Le client relit le budget toutes les 5 s : il voit que le serveur a clos
  // sa visite et la termine.
  const fin = await trouverTexte(f.page, /Durée de visite atteinte/, 25000);
  await activerSemantique(f.page);
  const ecranFin = await lus(f.page);
  p.dire(`Ecran apres la coupure : ${ecranFin}`);
  verdicts.ecranFinDeVisite = !!fin && !/Temps restant/.test(ecranFin)
    && /Il vous reste une visite de 2 minutes/.test(ecranFin);
  await p.capture(f, 'visite_coupee_par_le_serveur');

  // 3. Une seconde visite, quittee tout de suite : elle compte. La troisieme
  // est refusee.
  await cliquer(f.page, /^Retour à la classe$/, { role: 'button', pause: 2500 });
  await aller(f.page, `/tc/observation/${ID.seance}?classe=${ID.classe}&eleve=${ID.enfant}`);
  p.dire(`Porte, seconde visite : ${await lus(f.page)}`);
  await cliquer(f.page, /^Observer maintenant$/, { role: 'button', pause: 5000 });
  await activerSemantique(f.page);
  await p.capture(f, 'seconde_visite');
  await cliquer(f.page, /^Quitter$/, { role: 'button', pause: 2500 });
  await activerSemantique(f.page);
  const confirmer = await trouver(f.page, /^Quitter (la visite|l.observation)|^Quitter$/, { role: 'button', delai: 3000 });
  if (confirmer) { await confirmer.click(); await f.page.waitForTimeout(2500); }
  p.dire(`Apres la seconde visite : base=${visites()} ; ecran=${await lus(f.page, 40)}`);
  verdicts.secondeEcourteeComptee = /^1:quota_atteint:120,2:sortie_volontaire/.test(visites());

  await aller(f.page, '/tuteur');
  await aller(f.page, `/tc/observation/${ID.seance}?classe=${ID.classe}&eleve=${ID.enfant}`);
  const porte3 = await lus(f.page);
  p.dire(`Porte, troisieme visite : ${porte3}`);
  const observer3 = await trouver(f.page, /^Observer maintenant$/, { role: 'button', delai: 2000 });
  verdicts.troisiemeRefusee = !observer3 && /0\/2|aucune visite|déjà utilisé|plus de visite/i.test(porte3);
  await p.capture(f, 'troisieme_visite_refusee');

  // 4. Les annonces : prouvees par le scenario SQL (controles 2 a 5).
  p.dire('(annonces : voir le scenario SQL, controles 2 a 5)');

  // 5. La direction regarde, invisible, depuis le planning.
  const d = await p.contexte('direction', { vue });
  await connecter(d.page, COMPTES.direction);
  await aller(d.page, '/admin/operations/planning');
  const nomClasse = `E2E O1 Classe ${n}`;
  // La ligne de la seance (son libelle accessible porte toute la ligne, jusqu'a
  // « Actions : <classe> ») ; elle peut etre plus bas : on defile.
  let ligne = null;
  await d.page.mouse.move(largeur * 0.6, hauteur / 2);
  for (let i = 0; i < 40 && !ligne; i++) {
    ligne = await trouver(d.page, new RegExp(`En direct Actions : ${nomClasse}$|Prévue Actions : ${nomClasse}$`), { delai: 800 });
    if (!ligne) { await d.page.mouse.wheel(0, 400); await d.page.waitForTimeout(400); await activerSemantique(d.page); }
  }
  if (!ligne) {
    await p.capture(d, 'planning_debug');
    const tout = (await libelles(d.page)).filter((x) => /E2E|Actions/i.test(x));
    throw new Error(`ligne de la seance absente ; lignes : ${tout.join(' | ')}`);
  }
  // Flutter defile a la molette, pas par le DOM : on amene la ligne au milieu.
  for (let i = 0; i < 30; i++) {
    const b = await ligne.boundingBox();
    if (b && b.y > 140 && b.y + b.height < hauteur - 60) break;
    await d.page.mouse.wheel(0, b && b.y < 140 ? -250 : 250);
    await d.page.waitForTimeout(350);
  }
  await d.page.waitForTimeout(500);
  // La ligne fusionne son menu dans un seul noeud accessible, qui capte le
  // clic (constat du robot, a dire au pilote) : on le rend transparent au
  // pointeur et on touche le « ... » dessine dessous, comme un doigt.
  const boite = await ligne.boundingBox();
  await ligne.evaluate((e) => { e.style.pointerEvents = 'none'; });
  await d.page.mouse.click(boite.x + boite.width - 40, boite.y + boite.height / 2);
  await d.page.waitForTimeout(1500);
  const regarder = await trouver(d.page, new RegExp(`^Regarder la salle (de |d.)${nomClasse}`), { delai: 5000 });
  verdicts.boutonDirection = !!regarder;
  await p.capture(d, 'planning_regarder_la_salle');
  if (!regarder) throw new Error(`« Regarder la salle » absent ; ecran : ${await lus(d.page, 120)}`);
  await regarder.click(); await d.page.waitForTimeout(3500); await activerSemantique(d.page);
  p.dire(`Porte de la direction : ${await lus(d.page)}`);
  await p.capture(d, 'porte_direction');
  const discret = await trouver(d.page, /discr/i, { delai: 3000 });
  if (discret) { await discret.click(); await d.page.waitForTimeout(800); }
  const entrer = await trouver(d.page, /^(Entrer|Observer|Observer maintenant|Entrer discrètement)/, { role: 'button', delai: 5000 });
  if (entrer) { await entrer.click(); await d.page.waitForTimeout(5000); await activerSemantique(d.page); }
  const visiteDirection = sql(`select role || ':' || coalesce(fin_de_visite, 'ouverte') from public.guardian_session_visit
    where session_id = '${ID.seance}' and observateur_profile_id = (select id from auth.users where email = '${COMPTES.direction}')
    order by entered_at desc limit 1`);
  const jeton = sql(`select (public.autoriser_jeton_video('${ID.seance}', (select id from auth.users where email = '${COMPTES.direction}'),
    'ws://livekit.local', 'ws://livekit.local') -> 'capabilities')::text`);
  const ecranDirection = await lus(d.page, 40);
  p.dire(`Direction : visite=${visiteDirection} ; capacites du jeton=${jeton} ; ecran=${ecranDirection}`);
  verdicts.directionInvisible = /^admin_masked:ouverte$/.test(visiteDirection) && /"hidden": true/.test(jeton)
    && /"can_publish": false/.test(jeton) && /Vous regardez sans être vu/.test(ecranDirection)
    && !/Votre enfant|Temps restant/.test(ecranDirection);
  await p.capture(d, 'direction_regarde_invisible');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const attendus = ['interrupteurFerme', 'entree', 'coupeeServeur', 'ecranFinDeVisite', 'secondeEcourteeComptee', 'troisiemeRefusee',
    'boutonDirection', 'directionInvisible'];
  const ok = attendus.every((k) => verdicts[k] === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(e).slice(0, 400));
}
process.exit(code);
