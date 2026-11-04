// Parcours 4 : la direction place un eleve dans une classe ; la famille voit
// l'enfant, sa classe et l'heure de la prochaine seance ; l'eleve adulte voit sa
// classe. S'appuie sur la classe du parcours 2 et les comptes du parcours 3
// (fichiers classe_parcours2.json et comptes_parcours3.json de la pile).
// Gestes et libelles : docs/current/PARCOURS-OUVERTURE-2026-11-01.md, parcours 4.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, trouverTexte, libelles, sql,
  COMPTES, TRAVAIL } from './commun.mjs';
import { ouvrirClasses, creerClasse, ajouterEleve } from './classes.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const p = await parcours('Parcours 4 : la direction place un eleve dans une classe', 'parcours-4');
let code = 1;
try {
  const classe = lire('classe_parcours2.json');
  const { FAMILLE, ADULTE } = lire('comptes_parcours3.json');
  classe.debut = new Date(classe.debut);
  p.dire(`Classe du parcours 2 : « ${classe.nom} » (${classe.jour} ${classe.heure} h, ${classe.fuseau}) ; enfant ${FAMILLE.enfant} ; adulte ${ADULTE.prenom} ${ADULTE.nom}`);

  // 1. Direction : Operations, Classes, la classe, « Ajouter un élève ».
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await ouvrirClasses(d.page);
  await p.capture(d, 'classes');
  const deja = sql(`select count(*) from public.groupe_membres gm join public.groupes g on g.id = gm.groupe_id
    join public.profiles e on e.id = gm.student_id where g.libelle = '${classe.nom}' and e.first_name = '${FAMILLE.enfant}' and gm.left_at is null`);
  if (deja !== '0') p.dire(`  ${FAMILLE.enfant} est deja dans « ${classe.nom} » (passage precedent) : ajout non rejoue`);
  else await ajouterEleve(p, d, { classe: classe.nom, eleve: FAMILLE.enfant });
  const membres = sql(`select count(*) from public.groupe_membres gm join public.groupes g on g.id = gm.groupe_id
    join public.profiles e on e.id = gm.student_id where g.libelle = '${classe.nom}' and e.first_name = '${FAMILLE.enfant}'`);
  p.dire(`Base locale : ${membres} placement de ${FAMILLE.enfant} dans « ${classe.nom} »`);
  if (membres === '0') throw new Error(`direction, « Ajouter » : ${FAMILLE.enfant} n'est pas dans la classe en base ; ecran : ${(await libelles(d.page)).slice(-12).join(' | ')}`);

  // Classe d'adultes (hommes) une heure apres, pour placer l'eleve adulte
  // (et servir au parcours 8).
  const heureAdultes = classe.heure < 21 ? classe.heure + 1 : classe.heure - 1;
  const nomAdultes = classe.nom.replace('enfants', 'adultes');
  if (sql(`select count(*) from public.groupes where libelle = '${nomAdultes}' and ended_at is null`) !== '0') {
    p.dire(`  « ${nomAdultes} » existe deja (passage precedent) : creation non rejouee`);
  } else {
    await creerClasse(p, d, { public: 'Adultes', genre: 'Hommes|Garçons', enseignant: 'E2E Enseignant Valide',
      creneaux: [{ jour: classe.jour, heure: heureAdultes }], nom: nomAdultes });
  }
  await ajouterEleve(p, d, { classe: nomAdultes, eleve: `${ADULTE.prenom} ${ADULTE.nom}` });
  fs.writeFileSync(path.join(TRAVAIL, 'classe_adultes.json'), JSON.stringify({ nom: nomAdultes, heure: heureAdultes,
    jour: classe.jour, fuseau: classe.fuseau, debut: new Date(classe.debut.getTime() + (heureAdultes - classe.heure) * 3600000) }, null, 2));

  // 2. Famille : son Accueil montre l'enfant, sa classe et l'heure de la prochaine seance.
  const f = await p.contexte('famille', { telephone: true });
  await connecterParLien(f.page, FAMILLE.courriel);
  await f.page.waitForTimeout(3000);
  await p.capture(f, 'accueil');
  const heureParis = new Intl.DateTimeFormat('fr-FR', { timeZone: 'Europe/Paris', hour: '2-digit', minute: '2-digit' }).format(classe.debut);
  const carte = await trouverTexte(f.page, FAMILLE.enfant, 15000);
  const heureVue = await trouverTexte(f.page, new RegExp(heureParis.replace(':', '[:h ]')), 5000);
  const classeVue = await trouverTexte(f.page, new RegExp(classe.nom.replace(/ \d+$/, '')), 3000);
  p.dire(`Famille, Accueil : enfant « ${carte ?? '-'} » ; heure ${heureParis} « ${heureVue ?? '-'} » ; classe « ${classeVue ?? '-'} »`);
  if (!carte || !heureVue) throw new Error(`famille, Accueil : ${!carte ? 'enfant absent' : `heure de la prochaine seance (${heureParis}) absente`} ; ecran : ${(await libelles(f.page)).slice(0, 20).join(' | ')}`);

  // Eleve adulte : son Accueil montre sa classe.
  const a = await p.contexte('adulte', { telephone: true });
  await connecterParLien(a.page, ADULTE.courriel);
  await a.page.waitForTimeout(3000);
  await p.capture(a, 'accueil');
  const vide = await trouverTexte(a.page, /Aucune classe pour le moment/, 2000);
  const adulteVu = await trouverTexte(a.page, new RegExp(`${nomAdultes}|Rejoindre|Prochaine séance|\\d{1,2}:00`), 8000);
  p.dire(`Adulte, Accueil : « ${adulteVu ?? vide ?? '-'} »`);
  if (vide || !adulteVu) throw new Error(`eleve adulte, Accueil : sa classe n'apparait pas (${vide ?? 'rien'}) ; ecran : ${(await libelles(a.page)).slice(0, 15).join(' | ')}`);
  if (!classeVue) p.dire('  remarque : le nom de la classe n\'est pas affiche sur l\'Accueil de la famille (l\'heure l\'est)');
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
