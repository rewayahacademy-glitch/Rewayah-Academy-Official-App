// FN-113 (01/11/2026) : le directeur cree une classe pour un enseignant qui
// tient deja le maximum de classes (`enseignant.classes_max`). Le serveur
// refuse (`plafond_classes_atteint`, migration 20261022000200) ; l'ecran doit
// le dire, avec le nombre, les deux sorties et le lien vers les Regles.
//
// Pile LOCALE. Le formulaire est ouvert pendant que l'enseignant est encore
// sous le maximum (la liste ne propose pas un enseignant deja au maximum) ;
// le maximum est abaisse en SQL local juste avant « Créer la classe », ce qui
// reproduit un refus du serveur sur une liste deja ouverte. Le reglage est
// remis a sa valeur a la fin.
// Usage : node tool/e2e/fn113_plafond.mjs
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, taper,
  activerSemantique, sql, COMPTES } from './commun.mjs';

const p = await parcours('FN-113 : maximum de classes atteint a la creation d une classe', 'fn113-plafond');
let code = 1;
const avant = sql(`select value::text from public.app_config where key = 'enseignant.classes_max'`) || null;
try {
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  const actives = Number(sql(`select count(*) from public.groupes where teacher_id = '${prof}' and ended_at is null`));
  p.dire(`Enseignant de test : ${actives} classe(s) active(s) ; maximum avant le test : ${avant ?? 'defaut (3)'}`);
  // Sous le maximum le temps d'ouvrir le formulaire.
  sql(`insert into public.app_config (key, value) values ('enseignant.classes_max', '${actives + 1}'::jsonb)
       on conflict (key) do update set value = excluded.value`);

  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await cliquer(d.page, 'Opérations Onglet');
  await cliquer(d.page, /^Classes$/);
  await cliquer(d.page, 'Nouvelle classe');
  await cliquer(d.page, /^Adultes\./, { role: 'radio' });
  await cliquer(d.page, /^(Hommes|Garçons)/, { role: 'radio' });
  await cliquer(d.page, /^E2E Enseignant Valide/, { role: 'radio' });
  const nb = await d.page.getByRole('button', { name: /^Heure/ }).count();
  await d.page.getByRole('button', { name: /^Mercredi$/ }).first().click();
  await d.page.waitForTimeout(500);
  await d.page.getByRole('button', { name: /^Heure/ }).first().click();
  await d.page.waitForTimeout(700);
  await cliquer(d.page, /^10 h$/, { role: 'menuitem' });
  for (let i = nb; i > 1; i--) await cliquer(d.page, `Retirer le créneau ${i}`);
  await taper(d.page, 'input[aria-label^="Nom de la classe"]', `E2E FN-113 ${Date.now() % 100000}`);
  await p.capture(d, 'formulaire_rempli');

  // L'enseignant atteint le maximum : le serveur va refuser.
  sql(`update public.app_config set value = '${actives}'::jsonb where key = 'enseignant.classes_max'`);
  p.dire(`Maximum abaisse a ${actives} (classes actives de l'enseignant) avant « Créer la classe »`);
  await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 3500 });
  await activerSemantique(d.page);
  const message = await trouverTexte(d.page, /La classe n.est pas créée[^|]*/, 10000);
  await p.capture(d, 'refus_maximum_de_classes');
  p.dire(`Message lu : ${message ?? (await libelles(d.page)).slice(0, 15).join(' | ')}`);
  const lien = await trouver(d.page, /^Relever le maximum dans les Règles/, { delai: 5000 });
  p.dire(`Lien vers les Règles : ${lien ? 'present' : 'absent'}`);
  let regles = null;
  if (lien) {
    await lien.click();
    await d.page.waitForTimeout(4000); await activerSemantique(d.page);
    regles = d.page.url();
    await p.capture(d, 'page_regles');
    p.dire(`Apres le lien : ${regles.replace(/^https?:\/\/[^/]+/, '')}`);
  }
  const attendu = new RegExp(`tient déjà ${actives} classes? actives?, pour un maximum de ${actives}.*Clôturez une de ses classes.*relevez le maximum`);
  const ok = message && attendu.test(message.replace(/ /g, ' ')) && regles?.endsWith('/admin/configuration/regles');
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : `message ou lien incorrect`);
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
} finally {
  // Le reglage d'avant (sinon le defaut du serveur).
  // Le reglage ne s'efface pas (declencheur) : sans valeur d'avant, le defaut 3.
  sql(`update public.app_config set value = '${avant ?? '3'}'::jsonb where key = 'enseignant.classes_max'`);
}
process.exit(code);
