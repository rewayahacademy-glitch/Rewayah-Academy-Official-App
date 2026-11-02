// Lot (A) : la direction offre l'acces a un enfant suspendu pour impaye, la
// famille retrouve « Rejoindre » ; puis l'acces offert est retire et remplace
// par un prix special de 35 %. Tout passe par l'interface de la direction
// (Finance, Paiements). Usage : node tool/e2e/lot_a_tarifs.mjs
// Prerequis : parcours 2 a 4 (classe_parcours2.json, comptes_parcours3.json).
// Pile LOCALE seulement. Comme pour le lot (B), la seance suivante de la Classe
// est avancee en base a maintenant et le mois de l'enfant est rendu impaye par
// une facture et une suspension posees en base.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, cliquer, ouvrir, trouver, trouverTexte, libelles, saisir, sql,
  activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const classe = lire('classe_parcours2.json');
const { FAMILLE } = lire('comptes_parcours3.json');
const p = await parcours('Lot A : la direction offre l acces ou un prix special', 'lot-a-tarifs');
const manque = [];

const enfant = sql(`select p.id from public.profiles p where p.role = 'student' and p.first_name = '${FAMILLE.enfant}'
  and p.household_id = (select t.household_id from public.profiles t join auth.users u on u.id = t.id
  where u.email = '${FAMILLE.courriel}') limit 1`);
const groupe = sql(`select id from public.groupes where libelle = '${classe.nom}' and ended_at is null limit 1`);
if (!enfant || !groupe) process.exit(await p.fin('rouge', 'famille ou classe du banc introuvable'));

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
sql(`update public.sessions set status = 'ended' where groupe_id = '${groupe}' and id <> '${seance}'
  and ended_at < now() and status in ('planned', 'in_progress', 'preflight')`);
p.dire(`Seance ${seance} ouverte`);

// Le mois de l'enfant n'est pas paye : facture et suspension ; aucune remise.
sql(`update public.acces_suspensions_paiement set retabli_le = clock_timestamp(), retabli_motif = 'facture_close'
  where profile_id = '${enfant}' and retabli_le is null`);
sql(`delete from public.bourses_eleves where profile_id = '${enfant}'`);
const facture = sql(`insert into public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise,
  rang_familial, lignes, total_mineur) select p.id, p.household_id, (date_trunc('month', now()) + make_interval(months => 1 + (select count(*)::int from public.factures_mensuelles
  where profile_id = '${enfant}')))::date,
  'v2.0.0', 'USD', 1, '[]'::jsonb, 5500 from public.profiles p where p.id = '${enfant}' returning id`).split('\n')[0];
sql(`insert into public.acces_suspensions_paiement(profile_id, facture_id, jour) values ('${enfant}', '${facture}', current_date)`);
p.dire(`Enfant ${FAMILLE.enfant} suspendu (facture ${facture})`);

// L'enseignant ouvre la salle (sans lui, aucun « Rejoindre », PR 100).
const e = await p.contexte('enseignant');
await connecter(e.page, COMPTES.enseignant);
await e.page.waitForTimeout(3000);
await cliquer(e.page, /^Rejoindre la salle/, { pause: 6000 });
if (!e.page.url().includes('/salle')) manque.push('l enseignant n a pas ouvert la salle');

// Avant : la famille n'a pas « Rejoindre ».
const f = await p.contexte('famille', { telephone: true });
await connecterParLien(f.page, FAMILLE.courriel);
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const avant = await trouver(f.page, new RegExp(`^Rejoindre la salle avec ${FAMILLE.enfant}`), { delai: 8000 });
await p.capture(f, 'famille_suspendue');
p.dire(`Avant : Rejoindre ${avant ? 'PRESENT' : 'absent'}`);
if (avant) manque.push('« Rejoindre » present alors que l enfant est suspendu (lot B)');

// La direction : Finance, Paiements, l'enfant, « Accès offert ou prix spécial ».
const d = await p.contexte('direction');
await connecter(d.page, COMPTES.direction);
await cliquer(d.page, 'Finance Onglet', { pause: 2500 });
await cliquer(d.page, /^Sections de la page/);
await cliquer(d.page, /^Paiements$/, { pause: 3000 });
await activerSemantique(d.page);
const vide = await trouverTexte(d.page, /Aucun accès offert ni prix spécial[^|]*/, 6000);
await p.capture(d, 'paiements_avant');
p.dire(`Bloc des remises avant : ${vide ?? 'liste non vide'}`);

const ouvrirEnfant = async () => {
  await cliquer(d.page, new RegExp(FAMILLE.enfant), { pause: 2000 });
  await cliquer(d.page, /^Accès offert ou prix spécial$/, { role: 'button', pause: 2000 });
};
await ouvrirEnfant();
await activerSemantique(d.page);
const aide = await trouverTexte(d.page, /n'a rien à payer jusqu'à la fin du mois choisi[^|]*/, 6000);
p.dire(`Fiche : ${aide ?? 'phrase de l acces offert absente'}`);
await saisir(d.page, 'Raison', 'Famille aidée par l\'académie (banc lot A)');
await p.capture(d, 'fiche_acces_offert');
await cliquer(d.page, /^Accorder$/, { role: 'button', pause: 3000 });
const fait = await trouverTexte(d.page, /C'est accordé/, 8000);
await p.capture(d, 'acces_offert_accorde');
p.dire(`Acces offert : ${fait ? 'accorde' : 'pas de confirmation'}`);
if (!fait) manque.push('la fiche n a pas confirme l acces offert');

const remise = sql(`select nature || ' ' || pour_mille || ' ' || mois_fin from public.bourses_eleves
  where profile_id = '${enfant}' and retiree_le is null`);
const leve = sql(`select retabli_motif from public.acces_suspensions_paiement where facture_id = '${facture}'`);
p.dire(`En base : remise « ${remise} » ; suspension levee : « ${leve} »`);
if (!/^acces_offert 1000 /.test(remise ?? '')) manque.push(`remise en base inattendue (${remise})`);
if (leve !== 'bourse') manque.push(`suspension non levee (${leve})`);

// La famille rouvre l'application : « Rejoindre » revient.
await f.page.reload();
await f.page.waitForTimeout(6000); await activerSemantique(f.page);
const apres = await trouver(f.page, new RegExp(`^Rejoindre la salle avec ${FAMILLE.enfant}`), { delai: 20000 });
await p.capture(f, 'famille_acces_offert');
p.dire(`Apres : ${apres ? (await apres.getAttribute('aria-label')) ?? 'Rejoindre' : 'Rejoindre absent'}`);
if (!apres) {
  manque.push('« Rejoindre » absent apres l acces offert');
  p.dire(`Ecran : ${(await libelles(f.page)).slice(0, 30).join(' | ')}`);
}

// La direction relit la liste, retire l'acces offert, puis accorde un prix
// special de 35 %.
await d.page.reload();
await d.page.waitForTimeout(4000);
await cliquer(d.page, 'Finance Onglet', { pause: 2500 });
await cliquer(d.page, /^Sections de la page/);
await cliquer(d.page, /^Paiements$/, { pause: 3000 });
await activerSemantique(d.page);
const ligne = await trouverTexte(d.page, /Accès offert jusqu'à fin[^|]*/, 8000);
await p.capture(d, 'liste_acces_offert');
p.dire(`Liste : ${ligne ?? 'ligne absente'}`);
if (!ligne) manque.push('la liste ne montre pas l acces offert');

await cliquer(d.page, /Accès offert jusqu'à fin/, { pause: 2000 });
await saisir(d.page, 'Raison', 'Remplacé par un prix spécial (banc lot A)');
await cliquer(d.page, /^Retirer$/, { role: 'button', pause: 3000 });
const retire = await trouverTexte(d.page, /C'est retiré/, 8000);
await p.capture(d, 'acces_offert_retire');
p.dire(`Retrait : ${retire ? 'fait' : 'pas de confirmation'}`);
if (!retire) manque.push('le retrait n a pas ete confirme');
await d.page.keyboard.press('Escape');
await d.page.waitForTimeout(1500);

await ouvrirEnfant();
await cliquer(d.page, /^Prix spécial$/, { pause: 1000 });
await saisir(d.page, 'Réduction', '35');
await saisir(d.page, 'Raison', 'Inscrit avant novembre 2026 (banc lot A)');
await p.capture(d, 'fiche_prix_special');
await cliquer(d.page, /^Accorder$/, { role: 'button', pause: 3000 });
const faitPrix = await trouverTexte(d.page, /C'est accordé/, 8000);
await d.page.keyboard.press('Escape');
await d.page.waitForTimeout(2000);
await activerSemantique(d.page);
const lignePrix = await trouverTexte(d.page, /Moins 35 % jusqu'à fin[^|]*/, 8000);
await p.capture(d, 'liste_prix_special');
const remisePrix = sql(`select nature || ' ' || pour_mille from public.bourses_eleves
  where profile_id = '${enfant}' and retiree_le is null`);
p.dire(`Prix special : ${faitPrix ? 'accorde' : 'pas de confirmation'} ; liste : ${lignePrix ?? 'absente'} ; base : ${remisePrix}`);
if (remisePrix !== 'prix_special 350') manque.push(`prix special en base inattendu (${remisePrix})`);
if (!lignePrix) manque.push('la liste ne montre pas le prix special');

await f.ctx.close();
await d.ctx.close();
await e.ctx.close();
process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'acces offert par la direction : suspension levee, Rejoindre revenu ; retrait puis prix special de 35 % visibles'));
