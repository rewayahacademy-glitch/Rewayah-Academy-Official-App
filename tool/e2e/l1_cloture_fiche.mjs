// L1 des listes, constat du directeur du 01/11/2026 : « Clôturer la classe »
// ne se trouvait pas. Il est en dernier dans la fiche-page, a part, avec la
// confirmation existante (motif) et le meme appel `cloturer_groupe`.
//
// Pile LOCALE. Une classe de test est creee pour l'occasion (sans enseignant,
// en attente), puis cloturee depuis sa fiche ; elle doit quitter la vue
// « Ouvertes ». Aucune autre classe n'est touchee. La migration
// 20261103800000 doit etre installee sur la pile.
// Usage : node tool/e2e/l1_cloture_fiche.mjs
import { parcours, connecter, cliquer, trouver, libelles,
  activerSemantique, sql, COMPTES } from './commun.mjs';

// VUE=1366x768 : une autre taille d'ecran (defaut 1440 x 900).
const [largeur, hauteur] = (process.env.VUE ?? '1440x900').split('x').map(Number);
const p = await parcours(`L1 : cloturer une classe depuis sa fiche (${largeur} x ${hauteur})`,
  largeur === 1440 ? 'fn113-cloture-fiche' : `fn113-cloture-fiche-${largeur}`);
let code = 1;
const lus = async (page, n = 60) => (await libelles(page)).slice(0, n).join(' | ');
const nom = `E2E L1 a clore ${Date.now() % 100000}`;
try {
  const id = sql(`insert into public.groupes (type_public, seuil_max, libelle, weekday, hour_local, etat)
                  values ('adulte', 6, '${nom}', 4, 8, 'en_attente_enseignant') returning id`).split('\n')[0];
  p.dire(`Classe de test : ${nom} (${id})`);

  const d = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
  await connecter(d.page, COMPTES.direction);
  await cliquer(d.page, 'Opérations Onglet');
  await cliquer(d.page, /^Classes$/);
  await d.page.waitForTimeout(2000);
  await activerSemantique(d.page);
  const avant = await lus(d.page);
  p.dire(`Liste, vue Ouvertes : ${avant}`);
  const presente = avant.includes(nom);
  await p.capture(d, 'liste_avant');

  await cliquer(d.page, new RegExp(`^${nom}`));
  await d.page.waitForTimeout(2000); await activerSemantique(d.page);
  const bouton = await trouver(d.page, /^Clôturer la classe$/, { delai: 8000 });
  p.dire(`Fiche : ${await lus(d.page, 40)}`);
  await p.capture(d, 'fiche_cloturer_en_dernier');
  let confirme = false;
  let confirmationVisible = false;
  if (bouton) {
    await bouton.click(); await d.page.waitForTimeout(1500);
    await cliquer(d.page, /^Fin du cycle de la classe$/);
    // Le bouton de confirmation est-il visible sans defiler ?
    const envoyer = await trouver(d.page, /^Clôturer$/, { role: 'button', delai: 5000 });
    const b = envoyer ? await envoyer.boundingBox() : null;
    confirmationVisible = !!b && b.y >= 0 && b.y + b.height <= hauteur;
    p.dire(`Bouton « Clôturer » : ${b ? `y=${Math.round(b.y)}, h=${Math.round(b.height)}` : 'absent'} ; visible sans defiler : ${confirmationVisible}`);
    await p.capture(d, 'confirmation_motif');
    await cliquer(d.page, /^Clôturer$/, { role: 'button', pause: 3000 });
    // L'appel est parti vers le serveur : la ligne est close EN BASE, avec le
    // motif saisi (journal de la cloture), pas seulement dans l'etat local.
    confirme = sql(`select ended_at is not null from public.groupes where id = '${id}'`) === 't';
    const raison = sql(`select coalesce(end_reason, '') from public.groupes where id = '${id}'`);
    p.dire(`En base : cloturee=${confirme} ; motif enregistre : « ${raison} »`);
  }
  await activerSemantique(d.page);
  const apres = await lus(d.page);
  p.dire(`Apres la cloture : ${apres}`);
  const disparue = !apres.includes(nom);
  await p.capture(d, 'liste_apres_vue_ouvertes');

  const verdicts = { presente, bouton: !!bouton, confirmationVisible, confirme, disparue };
  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every(Boolean);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
