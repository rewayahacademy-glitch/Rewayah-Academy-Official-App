// PR 128 : les trois delais A3 se reglent dans Configuration > Regles.
// Usage : node tool/e2e/regles_a3.mjs
// Pile LOCALE seulement. La direction ouvre Regles, lit la section « Quand
// l'enseignant n'a pas rejoint la salle », ouvre « Perte de la seance » et
// monte jusqu'a la borne (10, avant l'objectif de 11) ; la feuille dit
// comment aller au-dela ; l'enregistrement passe. Puis une seconde direction
// (simulee en SQL local) baisse l'objectif pendant que la feuille est ouverte :
// le serveur refuse l'ordre faux, et l'ecran le dit.
import { parcours, connecter, ouvrir, trouver, trouverTexte, libelles, sql,
  activerSemantique, COMPTES } from './commun.mjs';

const q = await parcours('Regles : delais A3 reglables par la direction', 'regles-a3');
const lire = () => sql(`select string_agg(replace(key,'remplacement.','') || '=' || value::text, ' ; ' order by key)
  from public.app_config where key like 'remplacement.%'`);
// Point de depart connu : 3, 8, 11 (dans l'ordre qui respecte la regle).
sql(`update public.app_config set value = '11' where key = 'remplacement.debut_remplacant_minutes'`);
sql(`update public.app_config set value = '3' where key = 'remplacement.avertissement_minutes'`);
sql(`update public.app_config set value = '8' where key = 'remplacement.perte_acces_minutes'`);
q.dire(`Delais en base au depart : ${lire()}`);

const d = await q.contexte('direction');
await connecter(d.page, COMPTES.direction);
await ouvrir(d.page, '/#/admin/configuration/regles');
const section = await trouverTexte(d.page, /Quand l'enseignant n'a pas rejoint la salle/, 20000);
if (!section) {
  await q.capture(d, 'regles');
  process.exit(await q.fin('rouge', `section absente ; ${(await libelles(d.page)).slice(0, 20).join(' | ')}`));
}
const ligne = await trouver(d.page, /Perte de la séance/, { delai: 10000 });
if (ligne) await ligne.scrollIntoViewIfNeeded().catch(() => {});
await d.page.waitForTimeout(1000);
await q.capture(d, 'regles_section_a3');
q.dire(`Regles : ${(await libelles(d.page)).filter((x) => /Avertissement|Perte|Remplaçant|min/.test(x)).slice(0, 8).join(' | ')}`);
if (!ligne) process.exit(await q.fin('rouge', 'ligne « Perte de la séance » absente'));

// La feuille : monter jusqu'a la borne haute.
await ligne.click(); await d.page.waitForTimeout(2000); await activerSemantique(d.page);
const aide = await trouverTexte(d.page, /Pour aller au-delà de[^|]*relevez d'abord l'objectif[^|]*/, 10000);
q.dire(`Feuille : ${aide ?? 'phrase des bornes absente'}`);
for (let i = 0; i < 5; i++) {
  const plus = await trouver(d.page, /^Augmenter/, { delai: 1500 });
  if (!plus) break;
  await plus.click(); await d.page.waitForTimeout(400);
}
const plusRestant = await trouver(d.page, /^Augmenter/, { delai: 1500 });
await activerSemantique(d.page);
await q.capture(d, 'feuille_perte_borne_haute');
q.dire(`« Augmenter » encore present a la borne : ${plusRestant ? 'oui' : 'non'}`);
const enregistrer = await trouver(d.page, /^Enregistrer/, { delai: 5000 });
await enregistrer.click(); await d.page.waitForTimeout(3000); await activerSemantique(d.page);
const apres = lire();
q.dire(`Apres « Enregistrer » : ${apres}`);
await q.capture(d, 'regles_perte_10');

// Seconde direction : l'objectif baisse a 9 pendant que la feuille de la perte
// est ouverte (elle propose encore jusqu'a 10).
const ligne2 = await trouver(d.page, /Perte de la séance/, { delai: 10000 });
await ligne2.click(); await d.page.waitForTimeout(2000); await activerSemantique(d.page);
const moins = await trouver(d.page, /^Diminuer/, { delai: 5000 });
await moins.click(); await d.page.waitForTimeout(400);   // 9
sql(`update public.app_config set value = '7' where key = 'remplacement.perte_acces_minutes'`);
sql(`update public.app_config set value = '9' where key = 'remplacement.debut_remplacant_minutes'`);
q.dire(`Une autre direction a change les delais : ${lire()}`);
await (await trouver(d.page, /^Enregistrer/, { delai: 5000 })).click();
await d.page.waitForTimeout(3000); await activerSemantique(d.page);
const refus = await trouverTexte(d.page, /la perte de la seance doit venir avant le remplacant[^|]*/, 10000);
await q.capture(d, 'refus_ordre_serveur');
q.dire(`Refus affiche : ${refus ?? 'aucun'} ; base : ${lire()}`);

const manque = [!aide && 'phrase « relevez d abord l objectif »',
  plusRestant && '« Augmenter » present a la borne',
  !/perte_acces_minutes=10/.test(apres) && 'perte non enregistree a 10',
  !refus && 'refus du serveur non affiche'].filter(Boolean);
await d.ctx.close();
// Retour aux valeurs par defaut, dans l'ordre que le serveur accepte.
sql(`update public.app_config set value = '3' where key = 'remplacement.avertissement_minutes'`);
sql(`update public.app_config set value = '11' where key = 'remplacement.debut_remplacant_minutes'`);
sql(`update public.app_config set value = '8' where key = 'remplacement.perte_acces_minutes'`);
process.exit(manque.length
  ? await q.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await q.fin('vert', 'les trois delais se lisent et se reglent dans Regles ; l ordre faux est refuse et dit'));
