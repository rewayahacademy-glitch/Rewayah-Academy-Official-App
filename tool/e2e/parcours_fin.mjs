// Parcours « fin de seance » (demande du directeur, 01/11) : la seance de la classe
// d'adultes a atteint ended_at. Usage : node tool/e2e/parcours_fin.mjs <etiquette>
// (ex. « fin+2 », « fin+15 », « close »). Observe, pour l'adulte et l'enseignant :
// la carte de classe sur l'Accueil, « Rejoindre » et ce qu'il ouvre (salle, ecran de fin,
// motif de refus de re-entree), le temps restant affiche en salle, les notifications.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { parcours, connecter, connecterParLien, trouver, trouverTexte, libelles, sql,
  activerSemantique, APP, COMPTES, TRAVAIL } from './commun.mjs';
const etiquette = process.argv[2] ?? 'fin';
const classe = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'classe_adultes.json'), 'utf8'));
const { ADULTE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
if (etiquette === 'chrono') {
  // FN-023 (lot « Fin de seance », etape 1) : le chrono du temps restant dans la
  // salle, pour l'enseignant et l'eleve adulte, puis son passage a « Temps prevu
  // ecoule » a la fin prevue. Pile LOCALE : la prochaine seance materialisee de la
  // classe d'adultes est avancee en SQL pour finir dans 3 minutes (sans cela, il
  // faudrait attendre une heure et demie) ; aucun texte n'est lu ailleurs que
  // dans l'application.
  process.exit(await chrono());
}
if (etiquette === 'avis') {
  // FN-028 (etape 3) : meme debut que « chrono », puis la seance est close et
  // le cahier depose (SQL local : le geste du cahier est joue par le parcours
  // 6) ; l'enseignant et l'eleve adulte lisent leur avis dans l'application.
  process.exit(await chrono({ avis: true }));
}
if (etiquette === 'refus') {
  // FN-024 et FN-025 (etape 2) : meme debut que « chrono », puis la seance est
  // close en SQL (comme la cloture automatique ou « Quitter et ouvrir le
  // cahier ») et la salle LiveKit locale supprimee : la connexion tombe. Le
  // client redemande le jeton ; le serveur repond avec son motif. Puis l'eleve
  // tente de rentrer (rechargement) : le refus dit pourquoi, avec l'heure.
  process.exit(await chrono({ refus: true }));
}
const p = await parcours(`Fin de seance (${etiquette})`, `parcours-fin/${etiquette}`);
const etat = sql(`select s.status || ' ; prevue ' || to_char(s.started_at,'HH24:MI') || '-' || to_char(s.ended_at,'HH24:MI') || ' UTC ; maintenant ' || to_char(now() at time zone 'utc','HH24:MI') from public.sessions s join public.groupes g on g.id = s.groupe_id
  where g.libelle = '${classe.nom}' and s.deleted_at is null and s.started_at < now() order by s.started_at desc limit 1`);
p.dire(`Seance : ${etat}`);
const resume = async (page) => (await libelles(page)).filter((x) => !/^(input|a:)/.test(x)).slice(0, 18).join(' | ').slice(0, 900);

async function role(nom, entrer, reRejoindre) {
  const c = await p.contexte(nom, { telephone: nom === 'adulte' });
  await entrer(c.page);
  await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  await p.capture(c, `${nom}_accueil`);
  p.dire(`${nom}, Accueil : ${await resume(c.page)}`);
  const r = await trouver(c.page, reRejoindre, { delai: 5000 });
  p.dire(`${nom}, « Rejoindre » : ${r ? (await r.getAttribute('aria-label')) : 'absent'}`);
  if (r) {
    await r.click(); await c.page.waitForTimeout(8000); await activerSemantique(c.page);
    await p.capture(c, `${nom}_apres_rejoindre`);
    p.dire(`${nom}, apres « Rejoindre » : ${c.page.url()} ; ${await resume(c.page)}`);
    const temps = await trouverTexte(c.page, /(restant|reste|minutes?|dépass|terminée|fin)[^|]*/i, 2000);
    p.dire(`${nom}, temps ou fin affiche : ${temps ?? 'rien'}`);
  }
  const n = await trouver(c.page, /^Notifications/, { delai: 3000 });
  if (n) { await n.click(); await c.page.waitForTimeout(3000); await activerSemantique(c.page); await p.capture(c, `${nom}_notifications`); p.dire(`${nom}, notifications : ${await resume(c.page)}`); }
  await c.ctx.close();
}
await role('adulte', (pg) => connecterParLien(pg, ADULTE.courriel), /^Rejoindre/);
await role('enseignant', (pg) => connecter(pg, COMPTES.enseignant), new RegExp(`^Rejoindre la salle`));
p.dire(`Seance (fin du script) : ${sql(`select s.status from public.sessions s join public.groupes g on g.id = s.groupe_id where g.libelle = '${classe.nom}' and s.deleted_at is null and s.started_at < now() order by s.started_at desc limit 1`)}`);
await p.fin('joué');

async function chrono({ refus = false, avis = false } = {}) {
  const q = avis
    ? await parcours('Fin de seance, etape 3 : avis de fin de seance dans l application', 'fin-seance-avis')
    : refus
    ? await parcours('Fin de seance, etape 2 : seance terminee annoncee, refus motive', 'fin-seance-refus')
    : await parcours('Fin de seance, etape 1 : chrono du temps restant en salle', 'fin-seance-chrono');
  const groupe = `(select id from public.groupes where libelle = '${classe.nom}' and ended_at is null limit 1)`;
  const seance = sql(`select id from public.sessions where groupe_id = ${groupe} and deleted_at is null
    and status in ('planned','preflight','in_progress') order by abs(extract(epoch from started_at - now())) limit 1`);
  if (!seance) return q.fin('rouge', `aucune seance materialisee pour ${classe.nom}`);
  sql(`update public.sessions set started_at = now() - interval '7 minutes', ended_at = now() + interval '3 minutes',
    join_opens_at = now() - interval '27 minutes' where id = '${seance}'`);
  const fin = Date.parse(sql(`select to_char(ended_at at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"') from public.sessions where id = '${seance}'`));
  q.dire(`Seance ${seance} : ${sql(`select status || ' ; ' || to_char(started_at at time zone 'utc','HH24:MI:SS') || '-' || to_char(ended_at at time zone 'utc','HH24:MI:SS') || ' UTC' from public.sessions where id = '${seance}'`)}`);
  const MOTIF_RESTANT = /min restantes|restant/;
  const MOTIF_ECOULE = /Temps prévu écoulé/;
  const acteurs = [];
  const e = await q.contexte('enseignant');
  await connecter(e.page, COMPTES.enseignant);
  let r = await trouver(e.page, new RegExp(`^Rejoindre la salle de la Classe ${classe.nom}`), { delai: 15000 });
  if (!r) { await q.capture(e, 'aujourdhui'); return q.fin('rouge', `enseignant : pas de « Rejoindre la salle » ; ${(await libelles(e.page)).slice(0, 15).join(' | ')}`); }
  await r.click(); await e.page.waitForTimeout(8000); await activerSemantique(e.page);
  acteurs.push(e);
  const a = await q.contexte('adulte', { telephone: true });
  await connecterParLien(a.page, ADULTE.courriel);
  await a.page.waitForTimeout(3000); await activerSemantique(a.page);
  r = await trouver(a.page, /^Rejoindre/, { delai: 15000, role: 'button' });
  if (!r) { await q.capture(a, 'accueil'); return q.fin('rouge', `adulte : pas de « Rejoindre » ; ${(await libelles(a.page)).slice(0, 15).join(' | ')}`); }
  await r.click(); await a.page.waitForTimeout(8000); await activerSemantique(a.page);
  acteurs.push(a);
  const avant = {};
  for (const x of acteurs) {
    await activerSemantique(x.page);
    avant[x.role] = await trouverTexte(x.page, MOTIF_RESTANT, 10000);
    await q.capture(x, 'salle_temps_restant');
    q.dire(`${x.role}, ${new Date().toISOString()}, avant la fin prevue : ${avant[x.role] ?? 'aucun temps restant affiche'}`);
  }
  const attente = fin + 10000 - Date.now();
  q.dire(`Attente de la fin prevue (${Math.max(0, Math.round(attente / 1000))} s)`);
  // A moins d'une minute de la fin : le temps restant se compte en secondes.
  if (attente > 70000) {
    await e.page.waitForTimeout(attente - 60000);
    for (const x of acteurs) {
      await activerSemantique(x.page);
      const t = await trouverTexte(x.page, MOTIF_RESTANT, 5000);
      await q.capture(x, 'salle_derniere_minute');
      q.dire(`${x.role}, ${new Date().toISOString()}, derniere minute : ${t ?? 'rien'}`);
    }
  }
  await e.page.waitForTimeout(Math.max(0, fin + 10000 - Date.now()));
  const apres = {};
  for (const x of acteurs) {
    await activerSemantique(x.page);
    apres[x.role] = await trouverTexte(x.page, MOTIF_ECOULE, 10000);
    await q.capture(x, 'salle_temps_prevu_ecoule');
    q.dire(`${x.role}, ${new Date().toISOString()}, apres la fin prevue : ${apres[x.role] ?? 'rien'}`);
  }
  const manque = acteurs.filter((x) => !avant[x.role] || !apres[x.role]).map((x) => x.role);
  if (avis && !manque.length) return finAvis(q, seance, e, a);
  if (!refus || manque.length) {
    return q.fin(manque.length ? 'rouge' : 'vert', manque.length ? `chrono absent ou fige pour : ${manque.join(', ')}` : '');
  }
  return finAnnoncee(q, seance, e, a);
}

/// Jeton LiveKit d'administration de la pile LOCALE (cle de dev de pile.sh).
function jetonAdminLivekit() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const maintenant = Math.floor(Date.now() / 1000);
  const corps = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ iss: 'devkey', nbf: maintenant - 10, exp: maintenant + 300, video: { roomCreate: true, roomAdmin: true, roomList: true } })}`;
  const signature = crypto.createHmac('sha256', 'secret_e2e_local_livekit_0123456789abcdef').update(corps).digest('base64url');
  return `${corps}.${signature}`;
}

async function finAnnoncee(q, seance, e, a) {
  // La seance se clot (statut serveur), puis la salle LiveKit disparait.
  sql(`update public.sessions set status = 'ended' where id = '${seance}' and status = 'in_progress'`);
  // Le nom de salle n'est pas en base : la pile locale n'a que cette salle
  // ouverte ; on la lit chez LiveKit.
  const livekit = (methode, corps) => fetch(`http://127.0.0.1:7880/twirp/livekit.RoomService/${methode}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${jetonAdminLivekit()}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(corps),
  });
  const salles = ((await (await livekit('ListRooms', {})).json()).rooms ?? []).map((x) => x.name);
  const salle = salles.join(', ');
  const heureFin = sql(`select to_char(ended_at at time zone 'Europe/Paris','HH24:MI') from public.sessions where id = '${seance}'`);
  q.dire(`Seance close en base (${sql(`select status from public.sessions where id = '${seance}'`)}), fin ${heureFin} (Europe/Paris) ; salle LiveKit « ${salle} » supprimee`);
  for (const nom of salles) {
    const r = await livekit('DeleteRoom', { room: nom });
    q.dire(`DeleteRoom ${nom} : HTTP ${r.status}`);
  }
  await e.page.waitForTimeout(10000);
  // FN-024 : l'ecran de fin, annonce par le serveur, avec l'heure de fin.
  await activerSemantique(a.page);
  const finEleve = await trouverTexte(a.page, new RegExp(`terminée à ${heureFin}`), 15000);
  await q.capture(a, 'seance_terminee_annoncee');
  q.dire(`adulte, ${new Date().toISOString()}, apres la fermeture : ${finEleve ?? (await libelles(a.page)).slice(0, 12).join(' | ')}`);
  await activerSemantique(e.page);
  const finEns = await trouverTexte(e.page, /cahier de transmission/i, 15000);
  await q.capture(e, 'fin_de_seance_cahier');
  q.dire(`enseignant, ${new Date().toISOString()}, apres la fermeture : ${finEns ?? (await libelles(e.page)).slice(0, 12).join(' | ')}`);
  // FN-025 : l'enseignant tente de retourner dans la salle (le chemin reel
  // apres la fin ; la salle s'ouvre par un billet en memoire, pas par son
  // adresse) ; le refus dit pourquoi, avec l'heure du serveur.
  const retourner = await trouver(e.page, /^Retourner dans la salle/, { delai: 8000 });
  if (retourner) { await retourner.click(); await e.page.waitForTimeout(9000); await activerSemantique(e.page); }
  const refusEns = await trouverTexte(e.page, new RegExp(`terminée à ${heureFin}\\. La salle a fermé peu après`), 20000);
  await q.capture(e, 'reentree_refusee_motif');
  q.dire(`enseignant, ${new Date().toISOString()}, « Retourner dans la salle » ${retourner ? 'touche' : 'absent'} : ${refusEns ?? (await libelles(e.page)).slice(0, 12).join(' | ')}`);
  const manque = [!finEleve && 'ecran de fin de l eleve', !finEns && 'ecran de fin de l enseignant', !refusEns && 'motif du refus'].filter(Boolean);
  return q.fin(manque.length ? 'rouge' : 'vert', manque.join(', '));
}

async function finAvis(q, seance, e, a) {
  const prof = sql(`select coalesce(private.c29_enseignant_effectif_session(id), teacher_id) from public.sessions where id = '${seance}'`);
  const eleve = sql(`select profile_id from public.session_participants where session_id = '${seance}' and role = 'student' and deleted_at is null limit 1`);
  // La cloture (comme la tache automatique ou « Quitter et ouvrir le cahier »).
  sql(`update public.sessions set status = 'ended' where id = '${seance}' and status = 'in_progress'`);
  q.dire(`Seance close : ${sql(`select status from public.sessions where id = '${seance}'`)}`);
  // Le cahier, avec un Travail a preparer pour l'eleve adulte.
  sql(`insert into public.lesson_reports (session_id, idempotency_key, content, author_profile_id)
       values ('${seance}', 'e2e-fn028-${Date.now()}',
               jsonb_build_object('eleves', jsonb_build_array(jsonb_build_object(
                 'student_id', '${eleve}', 'confirme', true, 'travail_maison', 'Réviser la page 5'))),
               '${prof}')`);
  q.dire(`Avis en base : ${sql(`select string_agg(n.params ->> 'portee' || '=' || coalesce(n.params ->> 'travail_etat', 'presents ' || (n.params ->> 'presents') || '/' || (n.params ->> 'inscrits')), ' ; ') from public.notifications n where n.evenement = 'seance_terminee' and n.params ->> 'session_id' = '${seance}'`)}`);
  q.dire(`Courriels seance_terminee : ${sql(`select count(*) from public.courriels_sortants where modele = 'seance_terminee'`)}`);
  const lus = {};
  for (const x of [e, a]) {
    await x.page.goto(APP + '/');
    await x.page.waitForTimeout(6000); await activerSemantique(x.page);
    const cloche = await trouver(x.page, /^Notifications/, { delai: 10000 });
    if (cloche) { await cloche.click(); await x.page.waitForTimeout(4000); await activerSemantique(x.page); }
    lus[x.role] = await trouverTexte(x.page, /est terminée/, 15000);
    await q.capture(x, 'avis_fin_de_seance');
    q.dire(`${x.role}, ${new Date().toISOString()}, notifications ${cloche ? 'ouvertes' : 'introuvables'} : ${lus[x.role] ?? (await libelles(x.page)).slice(0, 12).join(' | ')}`);
  }
  const attendu = { enseignant: /présents? sur .*Cahier déposé, merci\.|présents? sur .*cahier de transmission attend/, adulte: /Travail à préparer\s*:\s*Réviser la page 5/ };
  const manque = ['enseignant', 'adulte'].filter((r) => !lus[r] || !attendu[r].test(lus[r].replace(/\u00a0/g, ' ')));
  return q.fin(manque.length ? 'rouge' : 'vert', manque.length ? `avis absent ou incomplet pour : ${manque.join(', ')}` : '');
}
