// Gestes de la direction sur les classes (Operations, Classes), partages par
// les parcours 2, 4 et 8.
import { cliquer, trouver, taper, libelles, trouverTexte } from './commun.mjs';

export async function ouvrirClasses(page) {
  await cliquer(page, 'Opérations Onglet');
  await cliquer(page, /^Classes$/);
}

/// « Nouvelle classe » : public, genre, enseignant, creneaux [{jour, heure}],
/// nom. Le formulaire ouvre trois creneaux (le premier et deux lignes « a
/// remplir ou a retirer ») : on remplit ce qu'il faut et on retire le reste.
export async function creerClasse(p, acteur, { public: pub, genre, enseignant, creneaux, nom }) {
  const page = acteur.page;
  await cliquer(page, 'Nouvelle classe');
  await cliquer(page, new RegExp(`^${pub}\\.`), { role: 'radio' });
  await cliquer(page, new RegExp(`^(${genre})\\.`), { role: 'radio' });
  await cliquer(page, new RegExp(`^${enseignant}`), { role: 'radio' });
  await p.capture(acteur, 'public_genre_enseignant');
  const nb = await page.getByRole('button', { name: /^Heure/ }).count();
  p.dire(`Creneaux ouverts par le formulaire : ${nb}`);
  for (let i = 0; i < creneaux.length; i++) {
    const { jour, heure } = creneaux[i];
    await page.getByRole('button', { name: new RegExp(`^${jour}$`) }).nth(i).click();
    await page.waitForTimeout(500);
    await page.getByRole('button', { name: /^Heure/ }).nth(i).click();
    await page.waitForTimeout(700);
    await cliquer(page, new RegExp(`^${heure} h$`), { role: 'menuitem' });
  }
  for (let i = nb; i > creneaux.length; i--) await cliquer(page, `Retirer le créneau ${i}`);
  await p.capture(acteur, 'creneaux');
  await taper(page, 'input[aria-label^="Nom de la classe"]', nom);
  await p.capture(acteur, 'nom');
  await cliquer(page, /^Créer la classe$/, { role: 'button', pause: 3000 });
  await p.capture(acteur, 'apres_creer');
  const erreur = await trouverTexte(page, /La classe n'est pas créée[^|]*/, 1500);
  if (erreur) throw new Error(`« Créer la classe » refuse : ${erreur}`);
  return trouverTexte(page, nom, 15000);
}

/// Actions de la classe, « Ajouter un élève », choix de l'eleve, motif, « Ajouter ».
export async function ajouterEleve(p, acteur, { classe, eleve, motif = 'Demande de la famille' }) {
  const page = acteur.page;
  await cliquer(page, new RegExp(`^Actions : ${classe}`));
  await cliquer(page, /^Ajouter un élève$/, { role: 'menuitem', pause: 1500 });
  await p.capture(acteur, 'ajouter_un_eleve');
  const choix = await trouver(page, new RegExp(`^${eleve}`), { role: 'radio', delai: 10000 });
  if (!choix) {
    throw new Error(`« Ajouter un élève » : ${eleve} absent de la liste ; proposes : ${(await libelles(page)).filter((x) => x.startsWith('radio:')).join(' | ') || 'aucun'}`);
  }
  await choix.click();
  await page.waitForTimeout(500);
  await cliquer(page, new RegExp(`^${motif}$`), { pause: 500 });
  await p.capture(acteur, 'eleve_et_motif');
  await cliquer(page, /^Ajouter$/, { role: 'button', pause: 3000 });
  await p.capture(acteur, 'apres_ajouter');
}
