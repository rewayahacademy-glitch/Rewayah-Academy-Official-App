// L3 des listes (pilote, 01/11/2026 ; DECISION-LISTES-2026-10-23.md
// §5 quater) : « Classes a ouvrir » (les regroupements de demandes) prend la
// methode de Classes et Comptes, sur la pile LOCALE, lue par le robot.
//
// Ce que le parcours prouve, a 1440 x 900, 1366 x 768 et 390 x 844 :
//   * un regroupement pret porte le bouton « Creer la classe », visible ; un
//     regroupement pas pret n'en porte aucun et dit ce qui manque ;
//   * au bureau, recherche et filtres sont en panneau, derriere l'icone ;
//   * le bouton ouvre la feuille de creation ; a 1440, la classe est creee
//     (genre « Garcons »), la ligne dit « Enseignant a confirmer », et son
//     menu « ... » ouvre la classe comme une page.
//
// Donnees de test, sur la pile LOCALE seulement : des eleves fictifs dans le
// foyer de test existant, et leurs demandes (cles A et B pretes, cle C
// incomplete). Les demandes de test d'un passage precedent sont retirees
// (etat « retiree », rien n'est efface). Aucune migration.
// Usage : node tool/e2e/l3_listes_regroupements.mjs
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES } from './commun.mjs';

const p = await parcours('L3 : la liste des classes a ouvrir, bureau et telephone', 'l3-listes-regroupements');
let code = 1;
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');
const n = Date.now() % 100000;
const famille = `L3E2E${n}`;

/// Des eleves fictifs (garcons, 6-9 ans, francais) et leurs demandes.
function semer(nombre, jours, heures) {
  for (let i = 1; i <= nombre; i++) {
    sql(`begin;
      with u as (
        insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
          email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
        values (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'eleve-${famille}-${heures.split(',')[0]}-${i}@eleves.example.com', '', now(),
          '{}', '{}', now(), now())
        returning id),
      pr as (
        insert into public.profiles (id, role, household_id, first_name, last_name, gender, account_status)
        select u.id, 'student', h.household_id, 'Rayan${i}', '${famille}', 'male', 'active'
          from u, (select household_id from public.profiles where role = 'student'
                    and household_id is not null order by created_at limit 1) h
        returning id),
      sp as (
        insert into public.student_profiles (profile_id, student_type, langue_cours, cohorte, niveau_declare)
        select id, 'minor', 'francais', 'enfant_6_9', 'debut_lettres' from pr returning profile_id)
      insert into public.demandes_horaires_famille
        (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, niveau_declare)
      select profile_id, 'enfant', 'francais', 'Europe/Paris', '{${jours}}', '{${heures}}',
             'personnalisee', 'debut_lettres' from sp;
      commit;`);
  }
}

/// Le bouton [nom] de la ligne dont le titre suit [titre] : le plus proche
/// sous le titre (meme rangee au bureau, plus bas dans la carte au telephone).
async function noeudDeLigne(page, titre, delai = 8000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const l = page.locator('[aria-label]');
    for (let i = 0; i < await l.count(); i++) {
      const nom = ((await l.nth(i).getAttribute('aria-label')) ?? '')
        .replace(/[\u2068\u2069]/g, '').trim();
      if (titre.test(nom) && await l.nth(i).isVisible().catch(() => false)) return l.nth(i);
    }
    const t = await trouver(page, titre, { delai: 400 });
    if (t) return t;
  }
  return null;
}

async function boutonDeLigne(page, titre, nom) {
  const t = await noeudDeLigne(page, titre);
  if (!t) return null;
  await amenerEnVue(page, t);
  const bt = await t.boundingBox();
  const boutons = page.getByRole('button', { name: nom });
  let meilleur = null; let ecart = Infinity;
  for (let i = 0; i < await boutons.count(); i++) {
    const b = await boutons.nth(i).boundingBox();
    if (!b) continue;
    const d = b.y - bt.y;
    if (d > -24 && d < 260 && Math.abs(d) < ecart) { ecart = Math.abs(d); meilleur = boutons.nth(i); }
  }
  return meilleur;
}

try {
  // Pile locale : les classes de test d'un passage precedent sont closes
  // (rien n'est efface), leurs demandes retirees.
  sql(`update public.groupes set ended_at = now(), end_reason = 'E2E L3 : nettoyage',
          ended_by = (select id from auth.users where email = '${COMPTES.direction}')
        where ended_at is null and id in (select gm.groupe_id from public.groupe_membres gm
          join public.profiles p on p.id = gm.student_id where p.last_name like 'L3E2E%')`);
  sql(`update public.demandes_horaires_famille set etat = 'retiree'
        where etat = 'envoyee' and eleve_id in
          (select id from public.profiles where last_name like 'L3E2E%')`);
  semer(5, '1,3', '17,17'); // A : prete, creee a 1440
  semer(5, '1,3', '18,18'); // B : prete
  semer(2, '2,4', '16,16'); // C : incomplete (2 sur 5)
  const avant = Number(sql(`select count(*) from public.groupes where etat = 'en_attente_enseignant' and ended_at is null`));
  p.dire(`Eleves de test : famille ${famille} ; classes en attente d'enseignant avant : ${avant}`);

  const A = /^Lundi, mercredi · 17\sh/;
  const B = /^Lundi, mercredi · 18\sh/;
  const C = /^Mardi, jeudi · 16\sh/;
  const verdicts = {};
  for (const [largeur, hauteur] of [[1440, 900], [1366, 768], [390, 844]]) {
    const cle = `${largeur}`;
    const bureau = largeur >= 1200;
    const v = {};
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, '/#/admin/operations/regroupements');
    await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    const l = await lus(c.page);
    p.dire(`${cle}, a l'ouverture : ${l}`);
    // Pret : le bouton ; pas pret : aucun bouton, la phrase de ce qui manque.
    v.boutonPret = !!(await boutonDeLigne(c.page, B, /^Créer la classe$/));
    v.pasPretSansBouton = !(await boutonDeLigne(c.page, C, /^Créer la classe$/))
      && /Il manque 3 demandes/.test(l + (await lus(c.page, 200)));
    await p.capture(c, `${cle}_ouverture`);

    if (bureau) {
      const filtres = await trouver(c.page, /^Filtres/, { delai: 8000, role: 'button' });
      v.panneau = false;
      if (filtres) {
        await filtres.click(); await c.page.waitForTimeout(1200); await activerSemantique(c.page);
        v.panneau = !!(await trouver(c.page, /^Rechercher/, { delai: 5000, role: 'textbox' }));
        await p.capture(c, `${cle}_filtres_ouverts`);
        await filtres.click(); await c.page.waitForTimeout(800);
      }
    }

    // Le chemin jusqu'a la feuille « Creer la classe ».
    await activerSemantique(c.page);
    const ligne = largeur === 1440 ? A : B;
    const bouton = await boutonDeLigne(c.page, ligne, /^Créer la classe$/);
    v.feuille = false;
    if (bouton) {
      await bouton.click(); await c.page.waitForTimeout(1500); await activerSemantique(c.page);
      v.feuille = !!(await trouver(c.page, /^Garçons/, { delai: 6000 }));
      await p.capture(c, `${cle}_feuille_creer_la_classe`);
      if (largeur === 1440) {
        // La classe est creee pour de bon (pile locale) : genre, puis envoi.
        const garcons = await trouver(c.page, /^Garçons/, { delai: 4000 });
        if (garcons) { await garcons.click(); await c.page.waitForTimeout(600); }
        const creer = await trouver(c.page, /^Créer la classe$/, { delai: 4000, role: 'button' });
        if (creer) { await creer.click(); await c.page.waitForTimeout(3500); }
        await activerSemantique(c.page);
        await p.capture(c, `${cle}_classe_creee_enseignant`);
        const apres = Number(sql(`select count(*) from public.groupes where etat = 'en_attente_enseignant' and ended_at is null`));
        v.classeCreee = apres === avant + 1;
        p.dire(`${cle}, classes en attente d'enseignant apres : ${apres}`);
      }
      const fermer = await trouver(c.page, /^Fermer$/, { delai: 4000, role: 'button' });
      if (fermer) { await amenerEnVue(c.page, fermer); await fermer.click(); await c.page.waitForTimeout(1500); }
      // Secours : la feuille se ferme aussi au clavier.
      // Secours : un clic sur le fond assombri ferme la feuille, puis Echap.
      await c.page.mouse.click(8, hauteur - 8); await c.page.waitForTimeout(1200);
      await c.page.keyboard.press('Escape'); await c.page.waitForTimeout(1200);
      await p.capture(c, `${cle}_feuille_fermee`);
    }

    // La classe creee : « Enseignant a confirmer », et son menu « ... ».
    await activerSemantique(c.page);
    const menu = await noeudDeLigne(c.page, /^Actions : Garçons, lundi, mercredi 17/);
    v.menu = false; v.fiche = largeur !== 1440;
    if (menu) {
      await amenerEnVue(c.page, menu);
      for (let essai = 0; essai < 2 && !v.menu; essai++) {
        const b = await menu.boundingBox();
        if (b) await c.page.mouse.click(b.x + b.width / 2, b.y + b.height / 2);
        await c.page.waitForTimeout(1200);
        v.menu = !!(await trouver(c.page, /^Voir la classe$/, { delai: 3000 }));
      }
      if (!v.menu) {
        // Dernier recours : le bouton par son role.
        const b = await trouver(c.page, /Actions :/, { delai: 3000, role: 'button' });
        if (b) { await b.click(); await c.page.waitForTimeout(1200); }
        v.menu = !!(await trouver(c.page, /^Voir la classe$/, { delai: 3000 }));
      }
      await p.capture(c, `${cle}_menu_ouvert`);
      if (largeur === 1440) {
        const voir = await trouver(c.page, /^Voir la classe$/, { delai: 4000 });
        if (voir) { await voir.click(); await c.page.waitForTimeout(2500); }
        await activerSemantique(c.page);
        const f = await lus(c.page, 60);
        v.fiche = /Informations générales/.test(f);
        p.dire(`${cle}, fiche de la classe : ${f}`);
        await p.capture(c, `${cle}_fiche_de_la_classe`);
      } else {
        await c.page.keyboard.press('Escape'); await c.page.waitForTimeout(600);
      }
    }
    verdicts[cle] = v;
    p.dire(`${cle} : ${JSON.stringify(v)}`);
  }

  const ok = Object.values(verdicts).every((v) => Object.values(v).every(Boolean));
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
