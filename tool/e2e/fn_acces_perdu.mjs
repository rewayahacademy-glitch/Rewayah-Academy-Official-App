// PR 124 : l'enseignant ecarte par l'absence automatique (A3) lit la vraie
// raison du refus de la salle. Usage : node tool/e2e/fn_acces_perdu.mjs
// Prerequis : le parcours 4 a cree la classe d'adultes (classe_adultes.json).
// Pile LOCALE seulement : la prochaine seance de la classe est avancee en SQL
// pour avoir commence il y a 9 minutes, sans que l'enseignant ait rejoint la
// salle ; puis un passage de la regle A3 est joue (comme le fait la
// planification de chaque minute). Aucun texte n'est lu ailleurs que dans
// l'application.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, trouverTexte, libelles, sql,
  activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';

const classe = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'classe_adultes.json'), 'utf8'));
const q = await parcours('Salle : enseignant ecarte par l absence automatique (A3)', 'salle-acces-perdu');
const groupe = `(select id from public.groupes where libelle = '${classe.nom}' and ended_at is null limit 1)`;
const seance = sql(`select id from public.sessions where groupe_id = ${groupe} and deleted_at is null
  and status in ('planned','preflight','in_progress')
  and not exists (select 1 from public.remplacements_seance r where r.session_id = sessions.id)
  and not exists (select 1 from public.remplacements_preparation p where p.session_id = sessions.id)
  order by abs(extract(epoch from started_at - now())) limit 1`);
if (!seance) process.exit(await q.fin('rouge', `aucune seance materialisee pour ${classe.nom}`));
const reglages = sql(`select string_agg(key || '=' || value::text, ' ; ' order by key) from public.app_config where key like 'remplacement.%'`);
q.dire(`Reglages A3 : ${reglages}`);
// Les autres seances de cet enseignant qui chevaucheraient l'heure choisie
// sont decalees de plusieurs annees, au hasard (pile locale, hors de tout autre creneau) : un enseignant n'a jamais deux
// seances a la fois (sessions_no_teacher_overlap).
sql(`with d as (select (interval '1 day') * (1000 + floor(random() * 100000)) as decalage)
  update public.sessions o set started_at = o.started_at + d.decalage, ended_at = o.ended_at + d.decalage,
  join_opens_at = o.join_opens_at + d.decalage
  from public.sessions s, d where s.id = '${seance}' and o.teacher_id = s.teacher_id and o.id <> s.id
  and o.deleted_at is null and tstzrange(o.started_at, o.ended_at) && tstzrange(now() - interval '10 minutes', now() + interval '52 minutes')`);
// Debut il y a 7 min : la pile locale fait tourner A3 chaque minute (pg_cron),
// l'ecran de l'enseignant doit s'ouvrir AVANT le delai de 8 min.
sql(`update public.sessions set started_at = now() - interval '7 minutes', ended_at = now() + interval '53 minutes',
  join_opens_at = now() - interval '27 minutes' where id = '${seance}'`);
const entre = sql(`select count(*) from public.session_events e join public.sessions s on s.id = e.session_id
  where s.id = '${seance}' and e.profile_id = s.teacher_id and e.event_type = 'joined'`);
q.dire(`Seance ${seance} : debut il y a 7 min ; arrivees du titulaire en base : ${entre}`);
const e = await q.contexte('enseignant');
await connecter(e.page, COMPTES.enseignant);
await e.page.waitForTimeout(3000); await activerSemantique(e.page);
await q.capture(e, 'accueil');
const r = await trouver(e.page, new RegExp(`^Rejoindre la salle de la Classe ${classe.nom}`), { delai: 15000 });
if (!r) {
  q.dire(`enseignant, Accueil : ${(await libelles(e.page)).slice(0, 15).join(' | ')}`);
  process.exit(await q.fin('rouge', 'enseignant : pas de « Rejoindre la salle » pour essayer'));
}
// Comme en production : l'ecran de l'enseignant est deja ouvert, le bouton
// « Rejoindre » visible ; le passage A3 l'ecarte pendant ce temps.
sql(`update public.sessions set started_at = now() - interval '9 minutes', ended_at = now() + interval '51 minutes',
  join_opens_at = now() - interval '29 minutes' where id = '${seance}'`);
const passage = sql(`select private.remplacement_auto_passer(now())::text`);
q.dire(`Passage A3 : ${passage}`);
const ecarte = sql(`select private.remplacement_titulaire_ecarte(s.id, s.teacher_id) from public.sessions s where s.id = '${seance}'`);
q.dire(`Titulaire ecarte selon le serveur : ${ecarte}`);
if (ecarte !== 't') process.exit(await q.fin('rouge', 'le passage A3 n a pas ecarte le titulaire'));

await r.click(); await e.page.waitForTimeout(8000); await activerSemantique(e.page);
const titre = await trouverTexte(e.page, /Vous n'avez pas rejoint la salle à temps/, 20000);
const phrase = await trouverTexte(e.page, /Passé le délai pour rejoindre la salle[^|]*/, 5000);
const ancien = await trouverTexte(e.page, /Ce cours ne vous est pas ouvert/, 1000);
await q.capture(e, 'refus_acces_perdu');
q.dire(`enseignant, apres « Rejoindre » : ${e.page.url()} ; ${(await libelles(e.page)).slice(0, 12).join(' | ')}`);
const manque = [!titre && 'titre « Vous n avez pas rejoint la salle à temps »',
  !phrase && 'phrase « Passé le délai pour rejoindre la salle »',
  ancien && 'ancien message « Ce cours ne vous est pas ouvert » encore affiche'].filter(Boolean);
await e.ctx.close();
process.exit(manque.length
  ? await q.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await q.fin('vert', 'l enseignant ecarte lit « Vous n avez pas rejoint la salle à temps » et la raison'));
