// Lot FOYER-ELEVE (04/11/2026) : la ligne « Foyer » (« Les appareils et
// profils rattaches a votre foyer ») ne s'affiche qu'a qui tient un foyer
// (capacite `aUnFoyer`). Pile LOCALE seulement.
//
// Amorce (SQL local) : un tuteur et deux enfants mineurs, Hakim hors
// Interface guidee (standard) et Yasmine en Interface guidee (child).
// Puis :
//   1. Hakim, Compte : pas de ligne « Foyer » ;
//   2. Hakim, Reglages : pas de ligne « Foyer », ni l'interrupteur des
//      notifications du foyer (« Activite des profils de votre foyer ») ;
//   3. Yasmine, Compte : pas de ligne « Foyer » ;
//   4. l'enseignant, Compte : pas de ligne « Foyer » (elle y etait inerte) ;
//   5. le tuteur, Compte : son Foyer reste joignable.
// Captures : docs/current/captures/E2E/FOYER-ELEVE/<date>/<largeur>.
//
// Usage : E2E_VUE=1440x900 node tool/e2e/foyer_eleve.mjs (puis 390x844)
import { parcours, connecter, libelles, activerSemantique, trouver, amenerEnVue, sql, MDP, COMPTES,
  nettoyerClassesE2E } from './commun.mjs';

const [largeur, hauteur] = (process.env.E2E_VUE ?? '1440x900').split('x').map(Number);
const vue = { width: largeur, height: hauteur };
const date = new Date().toISOString().slice(0, 10);
const p = await parcours(`FOYER-ELEVE : la ligne Foyer selon la capacite (${largeur} x ${hauteur})`,
  `FOYER-ELEVE/${date}/${largeur}`);
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
const DETAIL = 'Les appareils et profils rattachés à votre foyer';
const lus = async (page, k = 300) => (await libelles(page)).slice(0, k).join(' | ');

function creerCompte(courriel) {
  return sql(`with nouveau as (
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
      'authenticated', '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
    returning id),
  ident as (insert into auth.identities (id, user_id, provider_id, identity_data, provider,
      created_at, updated_at, last_sign_in_at)
    select gen_random_uuid(), id, id::text,
      jsonb_build_object('sub', id::text, 'email', '${courriel}', 'email_verified', true),
      'email', now(), now(), now() from nouveau returning user_id)
  select id from nouveau`).split('\n')[0];
}

async function vers(page, chemin, attente = 6000) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(attente);
  await activerSemantique(page);
}

/// Ouvre un compte, va a la page, releve et capture.
async function releve(qui, courriel, chemin, etiquette) {
  const c = await p.contexte(qui, { vue });
  await connecter(c.page, courriel);
  await vers(c.page, chemin);
  const texte = await lus(c.page);
  // La preuve d'absence n'a de sens que si la page est lue jusqu'au bout :
  // « Confidentialite » est la ligne qui suit celle du Foyer.
  p.dire(`${etiquette} : lue jusqu'a Confidentialite = ${texte.includes('Confidentialité')} ; ${texte.slice(0, 500)}`);
  // La capture montre l'endroit ou etait la ligne : on fait defiler jusqu'a
  // « Confidentialite », qui la suivait.
  const repere = await trouver(c.page, /^Confidentialité/, { delai: 5000 });
  if (repere) { await amenerEnVue(c.page, repere); await c.page.waitForTimeout(800); }
  await p.capture(c, etiquette);
  await c.ctx.close();
  return texte;
}

let code = 1;
try {
  nettoyerClassesE2E();
  ID.courrielTuteur = `e2e-fe-tuteur-${n}@example.com`;
  ID.courrielHakim = `e2e-fe-hakim-${n}@example.com`;
  ID.courrielYasmine = `e2e-fe-yasmine-${n}@example.com`;
  ID.tuteur = creerCompte(ID.courrielTuteur);
  ID.hakim = creerCompte(ID.courrielHakim);
  ID.yasmine = creerCompte(ID.courrielYasmine);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', 'E2E-FE-T-${n}', 'guardian', '${ID.tuteur}', 'Samira', 'Foyer${n}', 'active', 'female'),
      ('${ID.hakim}', 'E2E-FE-E-${n}', 'student', '${ID.tuteur}', 'Hakim', 'Foyer${n}', 'active', 'male'),
      ('${ID.yasmine}', 'E2E-FE-Y-${n}', 'student', '${ID.tuteur}', 'Yasmine', 'Foyer${n}', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values
      ('${ID.hakim}', 'minor', 'standard'), ('${ID.yasmine}', 'minor', 'child');
    commit;`);
  p.dire(`Amorce : tuteur ${ID.courrielTuteur}, Hakim (standard), Yasmine (child)`);

  const hakimCompte = await releve('enfant', ID.courrielHakim, '/compte', '01_hakim_compte');
  verdicts.hakimCompteOuvert = hakimCompte.includes('Hakim');
  verdicts.hakimCompteSansFoyer = hakimCompte.includes('Confidentialité') && !hakimCompte.includes(DETAIL);

  const hakimReglages = await releve('enfant', ID.courrielHakim, '/compte/reglages', '02_hakim_reglages');
  verdicts.hakimReglagesOuverts = /Réglages|Langue des e-mails/.test(hakimReglages);
  verdicts.hakimReglagesSansFoyer = hakimReglages.includes('Confidentialité') && !hakimReglages.includes(DETAIL);
  verdicts.hakimReglagesSansNotificationsFoyer = hakimReglages.includes('Confidentialité')
    && !hakimReglages.includes('Activité des profils de votre foyer');

  const yasmineCompte = await releve('enfant', ID.courrielYasmine, '/compte', '03_yasmine_compte_interface_guidee');
  verdicts.yasmineCompteOuvert = yasmineCompte.includes('Yasmine');
  verdicts.yasmineCompteSansFoyer = yasmineCompte.includes('Confidentialité') && !yasmineCompte.includes(DETAIL);

  const profCompte = await releve('enseignant', COMPTES.enseignant, '/compte', '04_enseignant_compte');
  verdicts.enseignantCompteSansFoyer = profCompte.includes('Confidentialité') && !profCompte.includes(DETAIL);

  const tuteurCompte = await releve('tuteur', ID.courrielTuteur, '/tuteur/compte', '05_tuteur_compte');
  verdicts.tuteurGardeSonFoyer = /Foyer/.test(tuteurCompte);

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
