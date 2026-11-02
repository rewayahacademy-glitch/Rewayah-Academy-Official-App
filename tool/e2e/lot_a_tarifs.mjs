// Lot (A) : la direction offre l'acces a un enfant suspendu pour impaye, la
// famille retrouve « Rejoindre » ; puis l'acces offert est retire et remplace
// par un prix special en prix par mois ; la facture du mois suivant, emise par
// la direction, montre a la famille la ligne « Prix spécial ». Tout passe par
// l'interface (Finance › Paiements). Captures a 1440 et a 390 de large.
// Usage : node tool/e2e/lot_a_tarifs.mjs
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
const LARGE = { width: 1440, height: 900 };
const echap = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

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
// La facture posee vise un mois lointain, pour laisser libre le mois suivant,
// que la direction emettra depuis l'interface.
sql(`update public.acces_suspensions_paiement set retabli_le = clock_timestamp(), retabli_motif = 'facture_close'
  where profile_id = '${enfant}' and retabli_le is null`);
sql(`update public.bourses_eleves set retiree_le = clock_timestamp(),
  retiree_par = (select id from public.profiles where role = 'admin' and deleted_at is null limit 1)
  where profile_id = '${enfant}' and retiree_le is null`);
const facture = sql(`insert into public.factures_mensuelles(profile_id, household_id, mois, politique_version, devise,
  rang_familial, lignes, total_mineur) select p.id, p.household_id, (date_trunc('month', now()) + make_interval(months => 12 + (select count(*)::int from public.factures_mensuelles
  where profile_id = '${enfant}')))::date,
  'v2.0.0', 'USD', 1, '[]'::jsonb, 5500 from public.profiles p where p.id = '${enfant}' returning id`).split('\n')[0];
sql(`insert into public.acces_suspensions_paiement(profile_id, facture_id, jour) values ('${enfant}', '${facture}', current_date)`);
const suivant = sql(`select to_char(date_trunc('month', now()) + interval '1 month', 'YYYY-MM-DD')`);
const dejaSuivant = sql(`select count(*) from public.factures_mensuelles where profile_id = '${enfant}' and mois = '${suivant}'`);
p.dire(`Enfant ${FAMILLE.enfant} suspendu (facture ${facture}) ; facture du mois suivant deja la : ${dejaSuivant}`);

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
await p.capture(f, '390_famille_suspendue');
p.dire(`Avant : Rejoindre ${avant ? 'PRESENT' : 'absent'}`);
if (avant) manque.push('« Rejoindre » present alors que l enfant est suspendu (lot B)');

// La direction : Finance, Paiements.
const allerPaiements = async (page) => {
  await cliquer(page, 'Finance Onglet', { pause: 2500 });
  await cliquer(page, /^Sections de la page/);
  await cliquer(page, /^Paiements$/, { pause: 3000 });
  await activerSemantique(page);
};
// La ligne de l'eleve dans la liste des eleves (pas un autre bloc qui cite son
// prenom) : son nom, puis son matricule ou ce qui reste a payer.
const ouvrirEnfant = async (page) => {
  const motif = new RegExp(`^${echap(FAMILLE.enfant)}[^|]*(RA-|\\$|jour)`);
  const ligne = await trouver(page, motif, { delai: 10000 });
  if (!ligne) {
    const vus = (await libelles(page)).filter((x) => x.includes(FAMILLE.enfant));
    throw new Error(`ligne de l eleve introuvable ; libelles avec son prenom : ${vus.join(' | ')}`);
  }
  p.dire(`Ligne de l eleve : ${(await ligne.getAttribute('aria-label')) ?? '(sans libelle)'}`);
  await ligne.scrollIntoViewIfNeeded().catch(() => {});
  await ligne.click();
  await page.waitForTimeout(2000);
  await cliquer(page, /^Accès offert ou prix spécial$/, { role: 'button', pause: 2000 });
  await activerSemantique(page);
};

const d = await p.contexte('direction', { vue: LARGE });
await connecter(d.page, COMPTES.direction);
await allerPaiements(d.page);
const vide = await trouverTexte(d.page, /Aucun accès offert ni prix spécial[^|]*/, 6000);
await p.capture(d, '1440_paiements_avant');
p.dire(`Bloc des remises avant : ${vide ?? 'liste non vide'}`);

// 1. Acces offert.
await ouvrirEnfant(d.page);
const aide = await trouverTexte(d.page, /n'a rien à payer jusqu'à la fin du mois choisi[^|]*/, 6000);
p.dire(`Fiche : ${aide ?? 'phrase de l acces offert absente'}`);
await saisir(d.page, 'Raison', 'Famille aidée par l\'académie (banc lot A)');
await p.capture(d, '1440_fiche_acces_offert');
await cliquer(d.page, /^Accorder$/, { role: 'button', pause: 3000 });
const fait = await trouverTexte(d.page, /C'est accordé/, 8000);
await p.capture(d, '1440_acces_offert_accorde');
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
await p.capture(f, '390_famille_acces_offert');
p.dire(`Apres : ${apres ? (await apres.getAttribute('aria-label')) ?? 'Rejoindre' : 'Rejoindre absent'}`);
if (!apres) {
  manque.push('« Rejoindre » absent apres l acces offert');
  p.dire(`Ecran : ${(await libelles(f.page)).slice(0, 30).join(' | ')}`);
}

// 2. Retrait de l'acces offert, depuis la liste.
await d.page.reload();
await d.page.waitForTimeout(4000);
await allerPaiements(d.page);
const ligne = await trouverTexte(d.page, /Accès offert jusqu'à fin[^|]*/, 8000);
await p.capture(d, '1440_liste_acces_offert');
p.dire(`Liste : ${ligne ?? 'ligne absente'}`);
if (!ligne) manque.push('la liste ne montre pas l acces offert');
await cliquer(d.page, /Accès offert jusqu'à fin/, { pause: 2000 });
await saisir(d.page, 'Raison', 'Remplacé par un prix spécial (banc lot A)');
await cliquer(d.page, /^Retirer$/, { role: 'button', pause: 3000 });
const retire = await trouverTexte(d.page, /C'est retiré/, 8000);
p.dire(`Retrait : ${retire ? 'fait' : 'pas de confirmation'}`);
if (!retire) manque.push('le retrait n a pas ete confirme');
await cliquer(d.page, /^Fermer$/, { role: 'button', pause: 2000 });

// 3. Prix special en prix par mois : d'abord un prix trop haut (refuse), puis 40.
const tarif = Number(sql(`select private.fac_tarif_profil('${enfant}', private.fac_politique_au(private.fac_mois_courant()))`));
p.dire(`Tarif de l eleve lu dans la politique : ${tarif} (unites mineures)`);
await ouvrirEnfant(d.page);
await cliquer(d.page, /^Prix spécial$/, { pause: 1000 });
await cliquer(d.page, /^Prix par mois$/, { pause: 1000 });
await saisir(d.page, 'Prix par mois', String(Math.ceil(tarif / 100)));
await saisir(d.page, 'Raison', 'Inscrit avant novembre 2026 (banc lot A)');
await cliquer(d.page, /^Accorder$/, { role: 'button', pause: 3000 });
const refus = await trouverTexte(d.page, /n'est pas inférieur au prix normal[^|]*/, 8000);
await p.capture(d, '1440_prix_trop_haut_refuse');
p.dire(`Prix egal au tarif : ${refus ?? 'aucun refus'}`);
if (!refus) manque.push('un prix egal au tarif n a pas ete refuse a l ecran');
await cliquer(d.page, /^Fermer$/, { role: 'button', pause: 2000 });

await ouvrirEnfant(d.page);
await cliquer(d.page, /^Prix spécial$/, { pause: 1000 });
await cliquer(d.page, /^Prix par mois$/, { pause: 1000 });
await saisir(d.page, 'Prix par mois', '40');
await saisir(d.page, 'Raison', 'Inscrit avant novembre 2026 (banc lot A)');
await p.capture(d, '1440_fiche_prix_par_mois');
await cliquer(d.page, /^Accorder$/, { role: 'button', pause: 3000 });
const faitPrix = await trouverTexte(d.page, /C'est accordé/, 8000);
await cliquer(d.page, /^Fermer$/, { role: 'button', pause: 2500 });
await activerSemantique(d.page);
const lignePrix = await trouverTexte(d.page, /40,00[^|]*par mois jusqu'à fin[^|]*/, 8000);
await p.capture(d, '1440_liste_prix_par_mois');
const remisePrix = sql(`select nature || ' ' || coalesce(pour_mille::text, '-') || ' ' || montant_mineur || ' ' || devise
  from public.bourses_eleves where profile_id = '${enfant}' and retiree_le is null`);
p.dire(`Prix par mois : ${faitPrix ? 'accorde' : 'pas de confirmation'} ; liste : ${lignePrix ?? 'absente'} ; base : ${remisePrix}`);
if (remisePrix !== 'prix_special - 4000 USD') manque.push(`prix special en base inattendu (${remisePrix})`);
if (!lignePrix) manque.push('la liste ne montre pas le prix par mois');
const suspendu = sql(`select count(*) from public.acces_suspensions_paiement where profile_id = '${enfant}' and retabli_le is null`);
p.dire(`Suspensions ouvertes apres le prix par mois : ${suspendu} (attendu 0 : rien n'a ete re-suspendu)`);

// La meme fiche a 390 de large (telephone de la direction).
const dt = await p.contexte('direction', { telephone: true });
await connecter(dt.page, COMPTES.direction);
await allerPaiements(dt.page);
await trouverTexte(dt.page, /40,00[^|]*par mois jusqu'à fin[^|]*/, 8000);
await p.capture(dt, '390_liste_prix_par_mois');
await cliquer(dt.page, /40,00[^|]*par mois jusqu'à fin/, { pause: 2000 });
await p.capture(dt, '390_fiche_retrait_prix_par_mois');
await dt.ctx.close();

// 4. La direction emet les factures du mois suivant ; la famille lit la ligne.
await d.page.reload();
await d.page.waitForTimeout(4000);
await allerPaiements(d.page);
const moisSuivantMots = sql(`select to_char(date '${suivant}', 'MM')`);
const NOMS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
await cliquer(d.page, new RegExp(`Factures d.{0,3}${NOMS[Number(moisSuivantMots) - 1]}`), { pause: 2000 });
await cliquer(d.page, /^Émettre/, { role: 'button', pause: 4000 });
await p.capture(d, '1440_factures_mois_suivant');
const facSuivante = sql(`select total_mineur || ' ' || (select l ->> 'remise' from jsonb_array_elements(lignes) l
  where l ->> 'nature' = 'bourse') from public.factures_mensuelles where profile_id = '${enfant}' and mois = '${suivant}'`);
p.dire(`Facture du mois suivant : ${facSuivante || 'absente'}`);
if (!/^4000 prix_special$/.test(facSuivante ?? '')) manque.push(`facture du mois suivant inattendue (${facSuivante})`);

for (const [acteur, etiquette] of [[f, '390'], [await p.contexte('famille', { vue: LARGE }), '1440']]) {
  if (etiquette === '1440') await connecterParLien(acteur.page, FAMILLE.courriel);
  await ouvrir(acteur.page, '/#/tuteur/foyer');
  await acteur.page.waitForTimeout(4000); await activerSemantique(acteur.page);
  await cliquer(acteur.page, new RegExp(`^${echap(FAMILLE.enfant)}`), { pause: 3000 });
  await activerSemantique(acteur.page);
  const fin = await trouver(acteur.page, /^Finances/, { delai: 6000 });
  if (fin) { await fin.click(); await acteur.page.waitForTimeout(3000); await activerSemantique(acteur.page); }
  let vu = null;
  for (let i = 0; i < 8 && !vu; i++) {
    vu = await trouverTexte(acteur.page, /Prix spécial[^|]*/, 800);
    if (!vu) { await acteur.page.mouse.move(195, 400); await acteur.page.mouse.wheel(0, 300); await acteur.page.waitForTimeout(400); await activerSemantique(acteur.page); }
  }
  await p.capture(acteur, `${etiquette}_famille_ligne_prix_special`);
  p.dire(`Famille ${etiquette} : ${vu ?? 'ligne « Prix spécial » absente'}`);
  if (!vu) {
    manque.push(`la famille (${etiquette}) ne lit pas « Prix spécial »`);
    p.dire(`Ecran : ${(await libelles(acteur.page)).slice(0, 40).join(' | ')}`);
  }
  if (await trouverTexte(acteur.page, /Bourse Rewayah/, 500)) manque.push(`la famille (${etiquette}) lit « Bourse Rewayah »`);
  if (etiquette === '1440') await acteur.ctx.close();
}

await f.ctx.close();
await d.ctx.close();
await e.ctx.close();
process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'acces offert : suspension levee, Rejoindre revenu ; retrait ; prix par mois trop haut refuse, 40 $ accorde ; facture du mois suivant a 40 $, la famille lit « Prix spécial »'));
