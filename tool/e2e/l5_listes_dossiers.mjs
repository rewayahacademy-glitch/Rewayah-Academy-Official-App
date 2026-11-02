// L5 des listes (pilote, 02/11/2026 ; DECISION-LISTES-2026-10-23.md
// §5 quater) : « Dossiers a valider » prend la methode de Classes, Comptes,
// Classes a ouvrir et l'Espace de traitement, sur la pile LOCALE, lue par le
// robot.
//
// Ce que le parcours prouve, a 1440 x 900, 1366 x 768 et 390 x 844 :
//   * la liste est la page (plus de detail a cote) : la ligne du dossier de
//     test, sans apercu de la piece ni case a cocher (DEC:24) ;
//   * la ligne ouvre le dossier, en page, sur la meme route ; la piece et
//     les verifications n'existent que la ; le retour ramene a la liste ;
//   * une seule source d'heure : la liste (« Aujourd'hui · HH:mm »), le
//     dossier (« Deposé le jj/mm/aaaa à HH:mm ») et l'Espace de traitement
//     disent la meme heure pour le meme depot (avant L5, le dossier disait
//     l'heure UTC, une heure de moins a Paris).
//
// Donnees de test, sur la pile LOCALE seulement : une enseignante fictive
// (piece en attente, deposee il y a 5 minutes). Les pieces de test d'un
// passage precedent sont retirees (deleted_at) ; rien n'est efface. Aucune
// migration.
// Usage : node tool/e2e/l5_listes_dossiers.mjs
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES } from './commun.mjs';

const p = await parcours('L5 : les dossiers a valider, bureau et telephone', 'l5-listes-dossiers');
let code = 1;
const lus = async (page, n = 120) => (await libelles(page)).slice(0, n).join(' | ');
const n = Date.now() % 100000;
const nom = `EssaiL5${n}`;

/// Le noeud dont le nom accessible suit [motif] (isolements retires).
async function noeud(page, motif, delai = 8000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const l = page.locator('[aria-label]');
    for (let i = 0; i < await l.count(); i++) {
      const nomA = ((await l.nth(i).getAttribute('aria-label')) ?? '')
        .replace(/[⁨⁩]/g, '').trim();
      if (motif.test(nomA) && await l.nth(i).isVisible().catch(() => false)) return l.nth(i);
    }
    const t = await trouver(page, motif, { delai: 400 });
    if (t) return t;
  }
  return null;
}

/// L'heure « HH:mm » qui suit [avant] dans les libelles lus.
const heureApres = (texte, avant) => {
  const m = texte.replace(/[⁨⁩  ]/g, ' ').match(
    new RegExp(`${avant}[^|]*?(\\d{2}:\\d{2})`));
  return m ? m[1] : null;
};

try {
  sql(`update public.kyc_documents set deleted_at = now()
        where deleted_at is null and object_key like 'e2e/l5-%'`);
  sql(`begin;
    with u as (insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
      values (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'authenticated',
        'authenticated', 'e2e-l5-${n}@example.com', '', now(), '{}', '{}', now(), now())
      returning id),
    pr as (insert into public.profiles (id, role, first_name, last_name, gender, account_status)
      select id, 'teacher', 'Salma', '${nom}', 'female', 'pending_kyc' from u returning id)
    insert into public.kyc_documents (profile_id, doc_type, gender, object_key, status, created_at)
      select id, 'id_card', 'female', 'e2e/l5-${n}.webp', 'pending', now() - interval '5 minutes' from pr;
    commit;`);
  const depot = sql(`select to_char(created_at at time zone 'UTC', 'HH24:MI') from public.kyc_documents
                      where object_key = 'e2e/l5-${n}.webp'`);
  p.dire(`Enseignante de test : Salma ${nom} ; depot a ${depot} UTC`);

  const verdicts = {};
  for (const [largeur, hauteur] of [[1440, 900], [1366, 768], [390, 844]]) {
    const cle = `${largeur}`;
    const v = {};
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, '/#/admin/personnes/dossiers');
    await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    const ligne = await noeud(c.page, new RegExp(`^Ouvrir le dossier de Salma ${nom}`));
    if (ligne) await amenerEnVue(c.page, ligne);
    await c.page.waitForTimeout(600); await activerSemantique(c.page);
    const l = await lus(c.page, 200);
    p.dire(`${cle}, la liste : ${l}`);
    v.ligne = !!ligne;
    // Aucun apercu de piece ni case a cocher dans la liste (DEC:24).
    v.sansApercu = !/Voir la pièce|Vérifications/.test(l)
      && (await c.page.locator('img').count()) === 0;
    v.sansCase = (await c.page.getByRole('checkbox').count()) === 0;
    const heureListe = heureApres(l, `Salma ${nom}`);
    await c.page.mouse.move(2, hauteur - 2); await c.page.waitForTimeout(400);
    await p.capture(c, `${cle}_liste`);

    // La ligne ouvre le dossier, en page.
    v.dossierOuvert = false; v.memeHeure = false; v.retour = false;
    if (ligne) {
      await ligne.click(); await c.page.waitForTimeout(2500); await activerSemantique(c.page);
      const d = await lus(c.page, 200);
      p.dire(`${cle}, le dossier : ${d}`);
      v.dossierOuvert = c.page.url().includes('/admin/personnes/dossiers')
        && d.includes(`Dossier de Salma ${nom}`) && /Vérifications/.test(d);
      const heureDossier = heureApres(d, 'Déposé le');
      p.dire(`${cle}, heure dans la liste ${heureListe}, dans le dossier ${heureDossier}`);
      v.memeHeure = !!heureListe && heureListe === heureDossier && !/UTC/.test(d);
      await p.capture(c, `${cle}_dossier_ouvert`);
      const retour = await trouver(c.page, /^Retour$/, { delai: 5000, role: 'button' });
      if (retour) { await retour.click(); await c.page.waitForTimeout(2000); }
      await activerSemantique(c.page);
      v.retour = !!(await noeud(c.page, new RegExp(`^Ouvrir le dossier de Salma ${nom}`), 5000));
      await p.capture(c, `${cle}_retour_liste`);
    }

    // L'Espace de traitement dit la meme heure (une seule source).
    if (largeur === 1440) {
      await ouvrir(c.page, '/#/admin/operations/traitement');
      await c.page.waitForTimeout(2500); await activerSemantique(c.page);
      const tr = await lus(c.page, 200);
      const heureTraitement = heureApres(tr, `Salma ${nom}`);
      p.dire(`${cle}, heure dans l'Espace de traitement ${heureTraitement}`);
      v.traitementMemeHeure = !!heureTraitement && heureTraitement === heureListe;
      await p.capture(c, `${cle}_espace_de_traitement`);
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
