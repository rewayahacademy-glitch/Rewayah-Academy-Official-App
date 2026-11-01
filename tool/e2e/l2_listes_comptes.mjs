// L2 des listes (directeur, 01/11/2026 ; DECISION-LISTES-2026-10-23.md
// §5 quater) : Personnes > Comptes prend la methode de Classes, sur la pile
// LOCALE, lue par le robot.
//
// Ce que le parcours prouve, a 1440 x 900, 1366 x 768 et 390 x 844 :
//   * au bureau, la tete tient sur une rangee : les vues, la puce
//     « En attente » ; la recherche et les filtres sont dans un panneau,
//     derriere l'icone des filtres de la tete ;
//   * une ligne « En attente » (une demande d'admission recue) porte
//     « Voir la demande », qui ouvre Demandes sur la bonne liste, deja
//     cherchee sur cette personne.
//
// Une personne de test est inscrite pour l'occasion par le vrai chemin
// (`inscrire_titulaire`, usage « moi » : un eleve adulte), sous une session
// simulee. Aucune autre ligne n'est touchee. Aucune migration nouvelle.
// Usage : node tool/e2e/l2_listes_comptes.mjs
import { randomUUID } from 'node:crypto';
import { parcours, connecter, cliquer, trouver, libelles, ouvrir,
  activerSemantique, sql, COMPTES } from './commun.mjs';

const p = await parcours('L2 : la liste des comptes, bureau et telephone', 'l2-listes-comptes');
let code = 1;
const lus = async (page, n = 60) => (await libelles(page)).slice(0, n).join(' | ');
const n = Date.now() % 100000;
const nom = `Karima Essai${n}`;
try {
  // 1. La personne de test : une adulte qui apprend pour elle-meme, sa
  //    demande est recue (etape « recue », issue « en cours »). Du meme genre
  //    que la direction de la pile : une candidature non confirmee d'un autre
  //    genre est hors de sa portee (`compte_candidat_hors_portee`).
  const u = randomUUID();
  sql(`begin;
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    values ('${u}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'e2e.l2.${n}@exemple.test', '', now(), '{}', '{}', now(), now());
    select set_config('request.jwt.claims', '{"sub":"${u}","role":"authenticated"}', true);
    select set_config('request.jwt.claim.sub', '${u}', true);
    select id from public.inscrire_titulaire('moi', 'Karima', 'Essai${n}', 'female', 'Europe/Paris', false);
    commit;`);
  const demande = sql(`select type_code || ' / ' || etape || ' / ' || issue
                         from public.candidatures where profile_id = '${u}'`);
  p.dire(`Personne de test : ${nom} (${u}) ; demande : ${demande}`);

  const verdicts = {};
  for (const [largeur, hauteur] of [[1440, 900], [1366, 768], [390, 844]]) {
    const cle = `${largeur}`;
    const bureau = largeur >= 1200;
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, '/#/admin/personnes/comptes');
    await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    const tete = await lus(c.page, 70);
    p.dire(`${cle}, a l'ouverture : ${tete}`);
    await p.capture(c, `${cle}_ouverture`);

    let panneau = true;
    let rechercheCachee = true;
    if (bureau) {
      // La recherche n'est pas sur la rangee ; l'icone l'ouvre en panneau.
      rechercheCachee = !(await trouver(c.page, /^Rechercher/, { delai: 1500, role: 'textbox' }));
      const filtres = await trouver(c.page, /^Filtres/, { delai: 8000, role: 'button' });
      panneau = false;
      if (filtres) {
        await filtres.click(); await c.page.waitForTimeout(1200); await activerSemantique(c.page);
        panneau = !!(await trouver(c.page, /^Rechercher/, { delai: 5000, role: 'textbox' }));
        p.dire(`${cle}, panneau des filtres : ${await lus(c.page, 70)}`);
        await p.capture(c, `${cle}_filtres_ouverts`);
        await filtres.click(); await c.page.waitForTimeout(800);
      }
    }

    // Au bureau, la puce « En attente » retient les lignes qui attendent une
    // decision. Au telephone, il n'y a pas de place pour elle : la ligne en
    // attente passe en tete, et le menu « État » propose « En attente ».
    await activerSemantique(c.page);
    const puce = bureau
      ? await trouver(c.page, /^En attente/, { delai: 8000, role: 'button' })
      : true;
    if (bureau && puce) { await puce.click(); await c.page.waitForTimeout(1500); }
    await activerSemantique(c.page);
    const ligneVue = (await lus(c.page, 90)).includes(nom);
    await p.capture(c, `${cle}_en_attente`);

    // La ligne porte « Voir la demande ».
    let action = false; let demandes = false; let cherchee = false; let adultes = false;
    const menu = await trouver(c.page, new RegExp(`^Actions : ${nom}`), { delai: 8000 });
    if (menu) {
      await menu.click(); await c.page.waitForTimeout(1000);
      const voir = await trouver(c.page, /^Voir la demande$/, { delai: 5000 });
      action = !!voir;
      await p.capture(c, `${cle}_menu_voir_la_demande`);
      if (voir) {
        await voir.click(); await c.page.waitForTimeout(3000); await activerSemantique(c.page);
        demandes = c.page.url().includes('/admin/personnes/demandes');
        const l = await lus(c.page, 90);
        cherchee = l.includes(nom);
        adultes = /Élèves adultes/.test(l);
        p.dire(`${cle}, Demandes : ${l}`);
        await p.capture(c, `${cle}_demandes_sur_la_personne`);
      }
    }
    // Relecture du pilote (PR 126) : le menu de ligne de Classes est passe
    // au meme declencheur « ... » ; une capture de Classes a 1440.
    let classesMenu = true;
    if (largeur === 1440) {
      await ouvrir(c.page, '/#/admin/operations/groupes');
      await c.page.waitForTimeout(2500); await activerSemantique(c.page);
      classesMenu = !!(await trouver(c.page, /^Actions : /, { delai: 8000 }));
      await p.capture(c, `${cle}_classes_menu_de_ligne`);
    }
    verdicts[cle] = { classesMenu, rechercheCachee, panneau, puce: !!puce, ligneVue, action, demandes, cherchee, adultes };
    p.dire(`${cle} : ${JSON.stringify(verdicts[cle])}`);
  }

  const ok = Object.values(verdicts).every((v) => Object.values(v).every(Boolean));
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
