// L4 des listes (pilote, 02/11/2026 ; DECISION-LISTES-2026-10-23.md
// §5 quater) : l'Espace de traitement prend la methode de Classes, Comptes et
// Classes a ouvrir, sur la pile LOCALE, lue par le robot.
//
// Ce que le parcours prouve, a 1440 x 900, 1366 x 768 et 390 x 844 :
//   * la liste est la page (plus de detail a cote) : un dossier d'identite et
//     une demande, avec ce que le detail disait, en colonnes ;
//   * au bureau, les filtres sont en panneau, derriere l'icone ;
//   * la ligne d'un dossier ouvre la file des dossiers sur lui ; celle d'une
//     demande ouvre la file des demandes.
//
// Donnees de test, sur la pile LOCALE seulement : une enseignante fictive
// (piece en attente) et une demande de changement d'enseignant pour l'eleve
// de test. Les elements de test d'un passage precedent sont clos (piece
// retiree, demande refusee) ; rien n'est efface. Aucune migration.
// Usage : node tool/e2e/l4_listes_traitement.mjs
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES } from './commun.mjs';

const p = await parcours("L4 : l'espace de traitement, bureau et telephone", 'l4-listes-traitement');
let code = 1;
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');
const n = Date.now() % 100000;
const enseignante = `Salma EssaiL4${n}`;

/// Le noeud dont le nom accessible suit [motif] (isolements retires).
async function noeud(page, motif, delai = 8000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const l = page.locator('[aria-label]');
    for (let i = 0; i < await l.count(); i++) {
      const nom = ((await l.nth(i).getAttribute('aria-label')) ?? '')
        .replace(/[⁨⁩]/g, '').trim();
      if (motif.test(nom) && await l.nth(i).isVisible().catch(() => false)) return l.nth(i);
    }
    const t = await trouver(page, motif, { delai: 400 });
    if (t) return t;
  }
  return null;
}

try {
  const direction = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  sql(`update public.kyc_documents set deleted_at = now()
        where deleted_at is null and object_key like 'e2e/l4-%'`);
  sql(`update public.matching_requests set status = 'rejected', decided_by = '${direction}',
          decided_at = now(), decision_reason = 'E2E L4 : nettoyage'
        where status = 'pending' and reason like 'E2E L4%'`);
  sql(`begin;
    with u as (insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
      values (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'authenticated',
        'authenticated', 'e2e-l4-${n}@example.com', '', now(), '{}', '{}', now(), now())
      returning id),
    pr as (insert into public.profiles (id, role, first_name, last_name, gender, account_status)
      select id, 'teacher', 'Salma', 'EssaiL4${n}', 'female', 'pending_kyc' from u returning id)
    insert into public.kyc_documents (profile_id, doc_type, gender, object_key, status)
      select id, 'id_card', 'female', 'e2e/l4-${n}.webp', 'pending' from pr;
    insert into public.matching_requests (kind, subject_profile_id, reason, requested_by, requester_role)
      select 'reassignment', s.id, 'E2E L4 : les horaires ne conviennent plus.', g.id, 'guardian'
        from (select id from public.profiles where role = 'student' order by created_at limit 1) s,
             (select id from public.profiles where role = 'guardian' order by created_at limit 1) g;
    commit;`);
  const eleve = sql(`select first_name from public.profiles where role = 'student' order by created_at limit 1`);
  p.dire(`Enseignante de test : ${enseignante} ; demande pour l'eleve ${eleve}`);

  const verdicts = {};
  for (const [largeur, hauteur] of [[1440, 900], [1366, 768], [390, 844]]) {
    const cle = `${largeur}`;
    const bureau = largeur >= 1200;
    const v = {};
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, '/#/admin/operations/traitement');
    await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    const l = await lus(c.page, 120);
    p.dire(`${cle}, a l'ouverture : ${l}`);
    v.ligneDossier = l.includes(enseignante);
    v.ligneDemande = /E2E L4 : les horaires ne conviennent plus/.test(l);
    await c.page.mouse.move(2, hauteur - 2); await c.page.waitForTimeout(400);
    await p.capture(c, `${cle}_ouverture`);

    if (bureau) {
      const filtres = await trouver(c.page, /^Filtres/, { delai: 8000, role: 'button' });
      v.panneau = false;
      if (filtres) {
        await filtres.click(); await c.page.waitForTimeout(1200); await activerSemantique(c.page);
        v.panneau = !!(await trouver(c.page, /^Dossiers/, { delai: 5000, role: 'button' }));
        await p.capture(c, `${cle}_filtres_ouverts`);
        await filtres.click(); await c.page.waitForTimeout(800);
      }
    }

    // La ligne du dossier : la file des dossiers, sur lui.
    await activerSemantique(c.page);
    const ligneD = await noeud(c.page, new RegExp(`^${enseignante}`));
    v.dossierOuvert = false;
    if (ligneD) {
      await amenerEnVue(c.page, ligneD);
      await ligneD.click(); await c.page.waitForTimeout(2500); await activerSemantique(c.page);
      v.dossierOuvert = c.page.url().includes('/admin/personnes/dossiers')
        && (await lus(c.page, 120)).includes(enseignante);
      await p.capture(c, `${cle}_dossier_ouvert`);
      await c.page.goBack(); await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    }

    // La ligne de la demande : la file des demandes.
    const ligneR = await noeud(c.page, new RegExp(`^${eleve}`));
    v.demandeOuverte = false;
    if (ligneR) {
      await amenerEnVue(c.page, ligneR);
      await ligneR.click(); await c.page.waitForTimeout(2500); await activerSemantique(c.page);
      v.demandeOuverte = c.page.url().includes('/admin/operations/demandes');
      p.dire(`${cle}, demandes : ${await lus(c.page, 60)}`);
      await p.capture(c, `${cle}_demande_ouverte`);
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
