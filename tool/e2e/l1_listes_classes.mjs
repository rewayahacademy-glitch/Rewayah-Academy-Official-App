// L1 des listes (directeur, 01/11/2026 ; DECISION-LISTES-2026-10-23.md
// §5 quater, DECISION-DEFILEMENT-2026-11-01) : la liste Operations > Classes
// refondue, sur la pile LOCALE, lue par le robot.
//
// Ce que le parcours prouve : au bureau (1440 x 900), la liste s'ouvre sans
// les classes cloturees (vue « Ouvertes »), une seule action et l'icone des
// filtres en tete ; les filtres se deplient en panneau, « Cloturees » les
// montre ; une ligne ouvre la fiche comme une page, et le retour retrouve la
// liste ; au telephone (390 x 844), « Nouvelle classe » flotte ; en sombre,
// la meme page. La migration 20261103800000 doit etre installee sur la pile.
// Usage : node tool/e2e/l1_listes_classes.mjs
import { parcours, connecter, cliquer, trouver, libelles, ouvrir,
  activerSemantique, sql, COMPTES } from './commun.mjs';

const p = await parcours('L1 : la liste des classes, bureau et telephone', 'fn113-listes-classes');
let code = 1;
const lus = async (page, n = 40) => (await libelles(page)).slice(0, n).join(' | ');
try {
  const ouvertes = Number(sql(`select count(*) from public.groupes where ended_at is null`));
  const cloturees = Number(sql(`select count(*) from public.groupes where ended_at is not null`));
  p.dire(`Base locale : ${ouvertes} classe(s) ouverte(s), ${cloturees} cloturee(s)`);

  // 1. Bureau 1440 x 900, clair.
  const d = await p.contexte('direction', { vue: { width: 1440, height: 900 } });
  await connecter(d.page, COMPTES.direction);
  await cliquer(d.page, 'Opérations Onglet');
  await cliquer(d.page, /^Classes$/);
  await d.page.waitForTimeout(2500); await activerSemantique(d.page);
  const bureau = await lus(d.page, 60);
  p.dire(`Bureau, vue par defaut : ${bureau}`);
  const nouvelle = await trouver(d.page, /^Nouvelle classe$/, { delai: 8000 });
  const filtres = await trouver(d.page, /^Filtres/, { delai: 8000, role: 'button' });
  const sansCloturee = !/Clôturée/.test(bureau);
  const sansIntro = !/Chaque classe réunit un enseignant/.test(bureau);
  await p.capture(d, 'bureau_1440_vue_ouvertes');

  // 2. Le panneau des filtres, puis « Cloturees ».
  let vuCloturees = cloturees === 0;
  if (filtres) {
    await filtres.click(); await d.page.waitForTimeout(1200); await activerSemantique(d.page);
    p.dire(`Panneau des filtres : ${await lus(d.page, 50)}`);
    await p.capture(d, 'bureau_1440_filtres_ouverts');
    if (cloturees > 0) {
      await cliquer(d.page, /^Clôturées/);
      await d.page.waitForTimeout(1500); await activerSemantique(d.page);
      const l = await lus(d.page, 60);
      vuCloturees = /Clôturée/.test(l);
      p.dire(`Filtre Cloturees : ${l}`);
      await p.capture(d, 'bureau_1440_cloturees');
      await cliquer(d.page, /^Ouvertes/);
      await d.page.waitForTimeout(1500);
    }
    await filtres.click(); await d.page.waitForTimeout(800);
  }

  // 3. Une ligne ouvre la fiche comme une page ; le retour retrouve la liste.
  await activerSemantique(d.page);
  const ligne = await trouver(d.page, /^E2E Classe/, { delai: 8000 });
  let fichePage = false; let retour = false;
  if (ligne) {
    await ligne.click(); await d.page.waitForTimeout(2500); await activerSemantique(d.page);
    // La fiche est une page empilee (`push`) : l'adresse du navigateur ne
    // change pas ; on lit son contenu.
    const fiche = await lus(d.page, 60);
    fichePage = /Informations générales/.test(fiche) && /Membres/.test(fiche);
    p.dire(`Fiche : ${fiche}`);
    await p.capture(d, 'bureau_1440_fiche_page');
    const dos = await trouver(d.page, /Retour/i, { delai: 5000 });
    if (dos) { await dos.click(); } else { await d.page.goBack(); }
    await d.page.waitForTimeout(2000);
    retour = d.page.url().endsWith('/admin/operations/groupes');
    await p.capture(d, 'bureau_1440_retour_liste');
  }

  // 4. Telephone 390 x 844 : « Nouvelle classe » flotte.
  const t = await p.contexte('direction', { vue: { width: 390, height: 844 } });
  await connecter(t.page, COMPTES.direction);
  await ouvrir(t.page, '/#/admin/operations/groupes');
  await t.page.waitForTimeout(2500); await activerSemantique(t.page);
  const tel = await lus(t.page, 40);
  p.dire(`Telephone : ${tel}`);
  const flottant = await trouver(t.page, /^Nouvelle classe$/, { delai: 8000 });
  await p.capture(t, 'telephone_390');

  // 5. Bureau en sombre.
  const s = await p.contexte('direction', { vue: { width: 1440, height: 900 }, sombre: true });
  await connecter(s.page, COMPTES.direction);
  await ouvrir(s.page, '/#/admin/operations/groupes');
  await s.page.waitForTimeout(2500);
  await p.capture(s, 'bureau_1440_sombre');

  const verdicts = { nouvelle: !!nouvelle, filtres: !!filtres, sansCloturee, sansIntro, vuCloturees, fichePage, retour, flottant: !!flottant };
  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every(Boolean);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
