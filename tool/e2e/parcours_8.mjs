// Parcours 8 : l'eleve adulte suit sa classe. Tuteur qui apprend lui-meme
// (compte « Je m'inscris pour moi » du parcours 3, place au parcours 4 dans la
// classe d'adultes) : son Accueil avec son prenom et SA classe, « Rejoindre » a
// l'heure (l'enseignant est dans la salle), puis « Dernières séances »,
// « Voir tout » apres une seance.
// Usage : node parcours_8.mjs            (etapes 1 et 2, pendant la seance)
//         node parcours_8.mjs --apres    (etape 3, une fois la seance terminee)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, allerOnglet, connecter, connecterParLien, cliquer, trouver, trouverTexte, libelles,
  COMPTES, TRAVAIL } from './commun.mjs';

const apres = process.argv.includes('--apres');
const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const p = await parcours('Parcours 8 : l\'eleve adulte suit sa classe', apres ? 'parcours-8-apres' : 'parcours-8');
let code = 1;
try {
  const classe = lire('classe_adultes.json');
  const { ADULTE } = lire('comptes_parcours3.json');
  const debut = Date.parse(classe.debut);
  p.dire(`Classe « ${classe.nom} », debut ${classe.debut} ; adulte ${ADULTE.prenom} ${ADULTE.nom}`);

  // 1. L'Accueil de l'eleve adulte : son prenom et sa classe.
  const a = await p.contexte('adulte', { telephone: true });
  await connecterParLien(a.page, ADULTE.courriel);
  await a.page.waitForTimeout(3000);
  await p.capture(a, 'accueil');
  const prenom = await trouverTexte(a.page, new RegExp(`Bonjour ${ADULTE.prenom}`), 15000);
  const saClasse = await trouverTexte(a.page, classe.nom, 8000);
  p.dire(`Accueil : « ${prenom ?? '-'} » ; classe « ${saClasse ?? '-'} »`);
  if (!prenom || !saClasse) throw new Error(`eleve adulte, Accueil : ${!prenom ? 'prenom absent' : 'sa classe absente'} ; ecran : ${(await libelles(a.page)).slice(0, 15).join(' | ')}`);

  if (!apres) {
    if (Date.now() < debut - 20 * 60000) {
      p.dire('Attente de l\'ouverture de la salle');
      await new Promise((r) => setTimeout(r, debut - 20 * 60000 - Date.now() + 15000));
      await a.page.reload(); await a.page.waitForTimeout(5000);
    }
    // 2. « Rejoindre » a l'heure, avec l'enseignant dans la salle. La seance
    // d'adultes suit celle des enfants (meme enseignant) : on attend son debut
    // pour que « Aujourd'hui » propose bien la salle des adultes.
    if (Date.now() < debut + 30000) {
      p.dire(`Attente du debut de la seance (${classe.debut})`);
      await new Promise((r) => setTimeout(r, debut + 30000 - Date.now()));
      await a.page.reload(); await a.page.waitForTimeout(5000);
    }
    const e = await p.contexte('enseignant');
    await connecter(e.page, COMPTES.enseignant);
    let rejoindreEns = await trouver(e.page, new RegExp(`^Rejoindre la salle de la Classe ${classe.nom}`), { delai: 10000 });
    if (!rejoindreEns) {
      // Seances qui s'enchainent : la precedente reste « en direct » jusqu'a sa
      // cloture automatique (fin + 30 min) et masque celle-ci sur « Aujourd'hui ».
      p.dire(`  ECART : « Aujourd'hui » ne propose pas la salle de ${classe.nom} (la seance precedente reste « en direct · temps prévu écoulé ») ; passage par l'onglet Classes`);
      await p.capture(e, 'aujourdhui_sans_salle_adultes');
      await allerOnglet(e.page, 'Classes', '/enseignant/classes', p.dire);
      rejoindreEns = await trouver(e.page, new RegExp(`^Rejoindre la salle de la Classe ${classe.nom}`), { delai: 10000 });
    }
    if (!rejoindreEns) throw new Error(`enseignant, Aujourd'hui : pas de « Rejoindre la salle de la Classe ${classe.nom} » ; ecran : ${(await libelles(e.page)).slice(0, 20).join(' | ')}`);
    await rejoindreEns.click(); await e.page.waitForTimeout(6000);
    await cliquer(e.page, /^Allumer la caméra/, { pause: 1500 });
    await cliquer(e.page, /^Ouvrir le micro/, { pause: 1500 });
    await p.capture(e, 'salle');
    const { activerSemantique } = await import('./commun.mjs');
    await activerSemantique(a.page);
    await p.capture(a, 'accueil_salle_ouverte');
    const rejoindre = await trouver(a.page, /^Rejoindre/, { delai: 10000, role: 'button' });
    if (!rejoindre) throw new Error(`eleve adulte : pas de « Rejoindre » sur l'Accueil, salle ouverte ; ecran : ${(await libelles(a.page)).slice(0, 20).join(' | ')}`);
    p.dire(`Adulte : ${(await rejoindre.getAttribute('aria-label')) ?? (await rejoindre.textContent())}`);
    await rejoindre.click();
    await a.page.waitForTimeout(7000);
    await activerSemantique(a.page);
    const camera = await trouver(a.page, /^Allumer la caméra/, { delai: 3000 });
    if (camera) { await camera.click(); await a.page.waitForTimeout(1000); }
    const micro = await trouver(a.page, /^Ouvrir le micro/, { delai: 3000 });
    if (micro) { await micro.click(); await a.page.waitForTimeout(1000); }
    await e.page.waitForTimeout(5000);
    await p.capture(a, 'salle');
    await p.capture(e, 'salle_eleve_arrive');
    const vuParEns = await trouverTexte(e.page, new RegExp(`fiche d.{1,4}${ADULTE.prenom}[^|]*`), 10000);
    const vuParAd = await trouverTexte(a.page, /Sayyid E2E Enseignant[^|]*/, 8000);
    p.dire(`Enseignant voit : « ${vuParEns ?? '-'} » ; adulte voit : « ${vuParAd ?? '-'} »`);
    if (!a.page.url().includes('/salle') && !vuParAd) throw new Error(`eleve adulte : « Rejoindre » n'ouvre pas la salle (${a.page.url()})`);
    if (!vuParEns || /Pas encore connecté/.test(vuParEns)) throw new Error(`salle, enseignant : l'eleve adulte n'apparait pas (« ${vuParEns} »)`);
    if (!vuParAd || /Sans image/.test(vuParAd)) throw new Error(`salle, eleve adulte : l'enseignant n'apparait pas ou sans image (« ${vuParAd} »)`);
  } else {
    // 3. Apres une seance : « Dernières séances », « Voir tout ».
    const dernieres = await trouverTexte(a.page, /Dernières séances/, 10000);
    p.dire(`« Dernières séances » : ${dernieres ?? 'absent'}`);
    if (!dernieres) throw new Error(`eleve adulte, Accueil apres la seance : pas de « Dernières séances » ; ecran : ${(await libelles(a.page)).slice(0, 25).join(' | ')}`);
    await cliquer(a.page, /^Voir tout/, { pause: 3000 });
    await p.capture(a, 'dernieres_seances');
    const ligne = await trouverTexte(a.page, new RegExp(`${classe.nom}|Présent|Partiel|Absent|min`), 10000);
    p.dire(`« Voir tout » : ${ligne ?? '-'}`);
    if (!ligne) throw new Error(`eleve adulte, « Voir tout » : aucune seance passee affichee ; ecran : ${(await libelles(a.page)).slice(0, 20).join(' | ')}`);
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
