// Parcours 2 : la direction cree une classe a plusieurs seances ; l'enseignant
// la voit dans son onglet « Classes » avec sa prochaine seance.
// Gestes et libelles : docs/current/PARCOURS-OUVERTURE-2026-11-01.md, parcours 2.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, taper, sql, nettoyerClassesE2E, allerOnglet,
  COMPTES, TRAVAIL } from './commun.mjs';
import { horaireProche, autreJour } from './horaire.mjs';

const echap = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const p = await parcours('Parcours 2 : la direction cree une classe a plusieurs seances', 'parcours-2');
let code = 1;
try {
  // Horaire : prochaine heure pleine dans 3 a 40 minutes (fuseau de l'enseignant de test).
  let h = horaireProche({ delaiMax: 40 });
  while (!h) { await new Promise((r) => setTimeout(r, 60000)); h = horaireProche({ delaiMax: 40 }); }
  const jour2 = autreJour(h.jourIndex);
  const nom = `E2E Classe enfants ${new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '')}`;
  p.dire(`Horaire : ${h.jour} ${h.heure} h (${h.fuseau}), debut ${h.debut.toISOString()} ; second creneau ${jour2} ${h.heure} h ; nom « ${nom} »`);
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  nettoyerClassesE2E();
  sql(`update public.teacher_profiles set timezone_iana = '${h.fuseau}' where profile_id = '${prof}'`);

  // 1. Direction : Operations, Classes, Nouvelle classe.
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await p.capture(d, 'accueil');
  await cliquer(d.page, 'Opérations Onglet');
  await cliquer(d.page, /^Classes$/);
  await p.capture(d, 'classes');
  await cliquer(d.page, 'Nouvelle classe');

  // 2. Public (Enfants par defaut), genre, enseignant, deux creneaux.
  await cliquer(d.page, /^Enfants\./, { role: 'radio' });
  await cliquer(d.page, /^Garçons\./, { role: 'radio' });
  await cliquer(d.page, /^E2E Enseignant Valide/, { role: 'radio' });
  await p.capture(d, 'public_genre_enseignant');
  const jours1 = d.page.getByRole('button', { name: new RegExp(`^${h.jour}$`) });
  await jours1.first().click(); await d.page.waitForTimeout(500);
  await d.page.getByRole('button', { name: /^Heure/ }).first().click();
  await d.page.waitForTimeout(700);
  await cliquer(d.page, new RegExp(`^${h.heure} h$`), { role: 'menuitem' });
  await p.capture(d, 'creneau_1');
  // Le formulaire ouvre trois creneaux (le premier et deux lignes « a remplir
  // ou a retirer », D2 du 29/10) : on remplit le 2e et on retire le 3e.
  const nb = await d.page.getByRole('button', { name: /^Heure/ }).count();
  p.dire(`Creneaux ouverts par le formulaire : ${nb}`);
  await d.page.getByRole('button', { name: new RegExp(`^${jour2}$`) }).nth(1).click();
  await d.page.waitForTimeout(500);
  await d.page.getByRole('button', { name: /^Heure/ }).nth(1).click();
  await d.page.waitForTimeout(700);
  await cliquer(d.page, new RegExp(`^${h.heure} h$`), { role: 'menuitem' });
  for (let i = nb; i > 2; i--) await cliquer(d.page, `Retirer le créneau ${i}`);
  await p.capture(d, 'creneau_2');
  await taper(d.page, 'input[aria-label^="Nom de la classe"]', nom);
  await p.capture(d, 'nom');

  // 3. « Créer la classe » : la classe apparait, active, avec son enseignant.
  await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 3000 });
  await p.capture(d, 'apres_creer');
  const ligne = await trouverTexte(d.page, nom, 15000);
  p.dire(`Liste des classes : ${ligne ?? 'classe absente'}`);
  const base = sql(`select g.etat || '|' || coalesce(p.first_name,'') || '|' || g.timezone_iana || '|' ||
    (select string_agg(weekday || ':' || hour_local, ',' order by weekday) from public.groupe_creneaux c where c.groupe_id = g.id)
    from public.groupes g left join public.profiles p on p.id = g.teacher_id where g.libelle = '${nom}'`);
  const seances = sql(`select count(*) || ' seance(s), premiere ' || coalesce(min(s.started_at)::text, 'aucune')
    from public.sessions s join public.groupes g on g.id = s.groupe_id where g.libelle = '${nom}'`);
  p.dire(`Base locale : ${base || 'aucune classe'} ; ${seances}`);
  if (!base) throw new Error(`« Créer la classe » : aucune classe « ${nom} » en base ; ecran : ${(await libelles(d.page)).slice(-15).join(' | ')}`);
  const [etat, prenomProf, , creneaux] = base.split('|');
  if (etat !== 'active' || !prenomProf.startsWith('E2E Enseignant')) throw new Error(`classe creee mais etat « ${etat} », enseignant « ${prenomProf} »`);
  if (!creneaux || creneaux.split(',').length < 2) throw new Error(`un seul creneau retenu en base (${creneaux}) : le second creneau n'a pas ete enregistre`);
  if (!ligne) throw new Error('classe creee en base mais absente de la liste « Classes » de la direction');
  if (await cliquer(d.page, nom).then(() => true).catch(() => false)) await p.capture(d, 'fiche_classe');

  // 4. Enseignant : onglet « Classes » : la classe et sa prochaine seance.
  const e = await p.contexte('enseignant');
  await connecter(e.page, COMPTES.enseignant);
  await p.capture(e, 'aujourdhui');
  await allerOnglet(e.page, 'Classes', '/enseignant/classes', p.dire);
  await e.page.waitForTimeout(2000);
  await p.capture(e, 'classes');
  const vue = await trouverTexte(e.page, nom, 15000);
  p.dire(`Enseignant, onglet Classes : ${vue ?? 'classe absente'}`);
  if (!vue) throw new Error(`enseignant, onglet « Classes » : la classe « ${nom} » n'apparait pas ; ecran : ${(await libelles(e.page)).slice(-20).join(' | ')}`);
  // Heure affichee dans le fuseau du navigateur de l'enseignant (Europe/Paris).
  const attendu = new Intl.DateTimeFormat('fr-FR', { timeZone: 'Europe/Paris', weekday: 'long',
    hour: '2-digit', minute: '2-digit' }).format(h.debut).replace(' à ', ' ');
  p.dire(`Prochaine seance attendue : « ${attendu} »`);
  const prochaine = await trouverTexte(e.page, new RegExp(echap(attendu).replace(' ', '\\s+'), 'i'), 8000);
  p.dire(`Prochaine seance affichee : ${prochaine ?? 'non lue'}`);
  if (!prochaine) throw new Error('enseignant, onglet « Classes » : la classe apparait sans sa prochaine seance');
  fs.writeFileSync(path.join(TRAVAIL, 'classe_parcours2.json'), JSON.stringify({ nom, ...h }, null, 2));
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
