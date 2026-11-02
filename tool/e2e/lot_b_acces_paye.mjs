// Lot (B) : la famille dont l'enfant n'a pas paye ne voit plus « Rejoindre »,
// garde son espace et peut payer ; une bourse de 100 % rouvre l'acces tout de
// suite. Usage : node tool/e2e/lot_b_acces_paye.mjs
// Prerequis : parcours 2 a 4 (classe_parcours2.json, comptes_parcours3.json).
// Pile LOCALE seulement. La seance suivante de la Classe est avancee en base a
// maintenant ; le mois de l'enfant est rendu impaye par une facture et une
// suspension posees en base, comme le fait le passage quotidien des relances.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, cliquer, ouvrir, trouver, trouverTexte, libelles, sql,
  activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const classe = lire('classe_parcours2.json');
const { FAMILLE } = lire('comptes_parcours3.json');
const p = await parcours('Lot B : sans paiement, ni seances ni ressources ; une bourse rouvre', 'lot-b-acces-paye');
const manque = [];

const enfant = sql(`select p.id from public.profiles p where p.role = 'student' and p.first_name = '${FAMILLE.enfant}'
  and p.household_id = (select t.household_id from public.profiles t join auth.users u on u.id = t.id
  where u.email = '${FAMILLE.courriel}') limit 1`);
const groupe = sql(`select id from public.groupes where libelle = '${classe.nom}' and ended_at is null limit 1`);
if (!enfant || !groupe) process.exit(await p.fin('rouge', 'famille ou classe du banc introuvable'));

// Une seance de la Classe ouverte maintenant ; les seances de l'enseignant
// qui la chevaucheraient sont decalees (pile locale).
// La seance du moment si elle existe deja (un passage precedent l'a ouverte),
// sinon la suivante, avancee a maintenant.
const enCours = sql(`select id from public.sessions where groupe_id = '${groupe}' and deleted_at is null
  and status in ('planned', 'preflight', 'in_progress') and started_at between now() - interval '50 minutes'
  and now() + interval '20 minutes' order by started_at limit 1`);
const seance = enCours || sql(`select id from public.sessions where groupe_id = '${groupe}' and deleted_at is null
  and status = 'planned' and started_at > now() order by started_at limit 1`);
if (!enCours) sql(`with d as (select (interval '1 day') * (1000 + floor(random() * 100000)) as decalage)
  update public.sessions o set started_at = o.started_at + d.decalage, ended_at = o.ended_at + d.decalage,
  join_opens_at = o.join_opens_at + d.decalage from public.sessions s, d where s.id = '${seance}'
  and o.teacher_id = s.teacher_id and o.id <> s.id and o.deleted_at is null
  and tstzrange(o.started_at, o.ended_at) && tstzrange(now() - interval '30 minutes', now() + interval '70 minutes')`);
if (!enCours) sql(`update public.sessions set started_at = now() + interval '5 minutes', ended_at = now() + interval '65 minutes',
  join_opens_at = now() - interval '15 minutes' where id = '${seance}'`);
p.dire(`Seance ${seance} ouverte (debut dans 5 min)`);

// Les seances passees de la Classe restees ouvertes sont closes : sinon
// l'Accueil montre encore l'une d'elles au lieu de la seance du moment
// (seances qui s'enchainent, FN-006, hors de ce lot).
sql(`update public.sessions set status = 'ended' where groupe_id = '${groupe}' and id <> '${seance}'
  and ended_at < now() and status in ('planned', 'in_progress', 'preflight')`);

// Le mois de l'enfant n'est pas paye : facture et suspension.
sql(`update public.acces_suspensions_paiement set retabli_le = clock_timestamp(), retabli_motif = 'facture_close'
  where profile_id = '${enfant}' and retabli_le is null`);
sql(`delete from public.bourses_eleves where profile_id = '${enfant}'`);
const facture = sql(`insert into public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise,
  rang_familial, lignes, total_mineur) select p.id, p.household_id, (date_trunc('month', now()) + make_interval(months => 1 + (select count(*)::int from public.factures_mensuelles
  where profile_id = '${enfant}')))::date,
  'v2.0.0', 'USD', 1, '[]'::jsonb, 5500 from public.profiles p where p.id = '${enfant}' returning id`).split('\n')[0];
sql(`insert into public.acces_suspensions_paiement(profile_id, facture_id, jour) values ('${enfant}', '${facture}', current_date)`);
p.dire(`Enfant ${FAMILLE.enfant} suspendu (facture ${facture})`);

// L'enseignant ouvre la salle (la salle s'ouvre par son jeton, PR 100) : sans
// lui, la famille lit « Ouverture de la salle non confirmée » et n'a jamais de
// « Rejoindre », suspendue ou non.
const e = await p.contexte('enseignant');
await connecter(e.page, COMPTES.enseignant);
await e.page.waitForTimeout(3000);
await cliquer(e.page, /^Rejoindre la salle/, { pause: 6000 });
await p.capture(e, 'salle_ouverte');
p.dire(`Enseignant : ${e.page.url()}`);
if (!e.page.url().includes('/salle')) manque.push('l enseignant n a pas ouvert la salle');

const f = await p.contexte('famille', { telephone: true });
await connecterParLien(f.page, FAMILLE.courriel);
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const rejoindreSuspendu = await trouver(f.page, new RegExp(`^Rejoindre la salle avec ${FAMILLE.enfant}`), { delai: 8000 });
const espace = await trouverTexte(f.page, /espace reste ouvert pour voir son profil, son historique et payer[^|]*/, 6000);
await p.capture(f, 'accueil_suspendu');
// Plus bas sur l'Accueil : la carte d'acces dit pourquoi et propose de payer.
await f.page.mouse.move(195, 400);
let carteAcces = null;
for (let i = 0; i < 10 && !carteAcces; i++) {
  await f.page.mouse.wheel(0, 300); await f.page.waitForTimeout(300); await activerSemantique(f.page);
  carteAcces = await trouverTexte(f.page, /(Accès suspendu|paiement du mois n'est pas reçu)[^|]*/, 800);
}
await p.capture(f, 'accueil_suspendu_carte_acces');
p.dire(`Suspendu, carte d'acces : ${carteAcces ?? 'absente'}`);
if (!carteAcces) manque.push('aucune explication de la suspension sur l Accueil');
p.dire(`Suspendu, Accueil : Rejoindre ${rejoindreSuspendu ? 'PRESENT' : 'absent'} ; texte : ${espace ?? 'absent'}`);
if (rejoindreSuspendu) manque.push('« Rejoindre » encore propose a l enfant suspendu');

await ouvrir(f.page, '/#/tuteur/foyer');
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const recharger = await trouver(f.page, /Recharger/, { delai: 10000 });
await p.capture(f, 'foyer_suspendu');
p.dire(`Suspendu, Foyer : ${recharger ? (await recharger.getAttribute('aria-label')) ?? 'Recharger' : 'Recharger absent'}`);
if (!recharger) manque.push('« Recharger » absent du Foyer');

await ouvrir(f.page, '/#/tuteur/historique');
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const historique = await trouverTexte(f.page, /Historique/, 8000);
await p.capture(f, 'historique_suspendu');
p.dire(`Suspendu, Historique : ${historique ? 'ouvert' : 'absent'}`);
if (!historique) manque.push('Historique ferme a la famille suspendue');

// La direction accorde une bourse de 100 % : la suspension se leve tout de suite.
sql(`insert into public.bourses_eleves(profile_id, pour_mille, mois_debut, mois_fin, motif, accordee_par)
  select '${enfant}', 1000, private.fac_mois_courant(), (private.fac_mois_courant() + interval '5 months')::date,
  'Banc lot B', (select id from public.profiles where role = 'admin' and deleted_at is null limit 1)`);
const leve = sql(`select retabli_motif from public.acces_suspensions_paiement where facture_id = '${facture}'`);
p.dire(`Bourse de 100 % : suspension levee, motif « ${leve} »`);
if (leve !== 'bourse') manque.push(`suspension non levee par la bourse (${leve})`);

// La famille rouvre l'application (rechargement) : l'acces est relu.
await ouvrir(f.page, '/#/tuteur');
await f.page.reload();
await f.page.waitForTimeout(6000); await activerSemantique(f.page);
const rejoindreRetabli = await trouver(f.page, new RegExp(`^Rejoindre la salle avec ${FAMILLE.enfant}`), { delai: 20000 });
await p.capture(f, 'accueil_retabli');
p.dire(`Retabli, Accueil : ${rejoindreRetabli ? (await rejoindreRetabli.getAttribute('aria-label')) ?? 'Rejoindre' : 'Rejoindre absent'}`);
if (!rejoindreRetabli) {
  manque.push('« Rejoindre » absent apres la bourse');
  p.dire(`Ecran : ${(await libelles(f.page)).slice(0, 30).join(' | ')}`);
}
await f.ctx.close();
await e.ctx.close();
process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'suspendu : ni Rejoindre ni ressources, Foyer et Historique ouverts, Recharger visible ; bourse : rouvert'));
