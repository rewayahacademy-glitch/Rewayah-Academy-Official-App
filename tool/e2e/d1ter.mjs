// D1-ter (03/11/2026) : la famille lit ce qui lui est transmis, sur la pile
// LOCALE.
//
// Ce que le parcours prouve :
//   1. la direction transmet (vraie fonction transmettre_student_concern) un
//      message sur un enfant et un message a un eleve adulte : le titulaire du
//      foyer et l'eleve adulte sont prevenus (message_academie_eleve), sans le
//      message dans la notification ;
//   2. le tuteur lit « Messages de l'académie sur Yasmine » en tete de son
//      Historique, a 1440 x 900 et 390 x 844, en clair et en sombre ;
//   3. la securite d'un enfant ne donne rien : pour la soeur, qui n'a qu'un
//      signalement « securite d'un enfant », aucune carte ;
//   4. l'eleve adulte lit « Messages de l'académie » dans son Suivi, a 1440 et
//      390 ;
//   5. l'enfant connecte ne voit rien dans sa page Ma classe, et la vue ne lui
//      rend rien (lecture en base sous son jeton).
// Chaque etape verifie le texte a l'ecran ou la ligne en base.
//
// Prerequis : migrations 20261107200001 puis 20261107200000 appliquees sur la
// pile LOCALE (tool/e2e/pile.sh), comptes amorces (tool/e2e/amorcer.sh).
// Donnees : un foyer, deux enfants, un eleve adulte, une classe et des seances
// neufs a chaque passage ; rien n'est efface. Usage : node tool/e2e/d1ter.mjs
import { parcours, trouver, libelles, activerSemantique, amenerEnVue,
  connecter, attendreTexte, nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs'

const p = await parcours('D1-ter : la famille lit ce qui lui est transmis', 'D1-ter')
const n = Date.now() % 1000000
const VUES = [
  { nom: '1440_clair', vue: { width: 1440, height: 900 }, sombre: false },
  { nom: '1440_sombre', vue: { width: 1440, height: 900 }, sombre: true },
  { nom: '390_clair', vue: { width: 390, height: 844 }, sombre: false },
  { nom: '390_sombre', vue: { width: 390, height: 844 }, sombre: true },
]

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`)
  p.dire(`  OK ${message}`)
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}` }, chemin)
  await page.waitForTimeout(4000)
  await activerSemantique(page)
}

async function montrer(acteur, texte, etiquette) {
  const e = texte ? await trouver(acteur.page, texte, { delai: 15000 }) : null
  if (e) {
    await amenerEnVue(acteur.page, e)
    const b = await e.boundingBox()
    const vue = acteur.page.viewportSize()
    if (b && b.y > vue.height / 2) {
      await acteur.page.mouse.move(vue.width * 0.6, vue.height / 2)
      await acteur.page.mouse.wheel(0, b.y - vue.height / 3)
      await acteur.page.waitForTimeout(500)
    }
  }
  await acteur.page.waitForTimeout(600)
  return p.capture(acteur, etiquette)
}

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
  select id from nouveau`).split('\n')[0]
}

/// Une fonction appelee sous le jeton d'une personne (base LOCALE seulement).
function sousJeton(uid, role, foyer, requete) {
  const jwt = JSON.stringify({ sub: uid, role: 'authenticated',
    app_metadata: { role, ...(foyer ? { household_id: foyer } : {}) } })
  return sql(`begin;
    select set_config('request.jwt.claims', '${jwt}', true);
    select set_config('request.jwt.claim.sub', '${uid}', true);
    set local role authenticated;
    ${requete};
    commit;`).split('\n').filter((l) => l !== '' && l !== 'BEGIN' && l !== 'COMMIT' && l !== 'SET').pop()
}

const COMPTE = {
  tuteur: `e2e-d1t-tuteur-${n}@example.com`,
  enfant: `e2e-d1t-enfant-${n}@example.com`,
  soeur: `e2e-d1t-soeur-${n}@example.com`,
  adulte: `e2e-d1t-adulte-${n}@example.com`,
}
const CLASSE = `E2E D1T ${n}`

let code = 1
try {
  p.dire('-- 1. banc : un foyer, deux enfants, un eleve adulte, une classe')
  nettoyerClassesE2E()
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`)
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`)
  const T = creerCompte(COMPTE.tuteur)
  const E = creerCompte(COMPTE.enfant)
  const S = creerCompte(COMPTE.soeur)
  const A = creerCompte(COMPTE.adulte)
  const G = sql('select gen_random_uuid()')
  const F2 = sql('select gen_random_uuid()')
  sql(`begin;
    insert into public.households (id, timezone) values ('${T}', 'Europe/Paris'), ('${F2}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${T}', 'E2E-D1T-T-${n}', 'guardian', '${T}', 'Amina', 'FamilleD1T', 'active', 'female'),
      ('${E}', 'E2E-D1T-E-${n}', 'student', '${T}', 'Yasmine', 'FamilleD1T', 'active', 'female'),
      ('${S}', 'E2E-D1T-S-${n}', 'student', '${T}', 'Ines', 'FamilleD1T', 'active', 'female'),
      ('${A}', 'E2E-D1T-A-${n}', 'student', '${F2}', 'Karima', 'AdulteD1T', 'active', 'female');
    update public.households set primary_guardian_id = '${T}' where id = '${T}';
    update public.households set primary_guardian_id = '${A}' where id = '${F2}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values
      ('${E}', 'minor', 'child'), ('${S}', 'minor', 'child'), ('${A}', 'autonomous', 'standard');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${G}', '${prof}', 'enfant', 5, '${CLASSE}',
              extract(isodow from (now() at time zone 'Europe/Paris') + interval '3 days')::int, 7, 'Europe/Paris', now() - interval '10 days');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values
      ('${G}', '${E}', now() - interval '10 days'), ('${G}', '${S}', now() - interval '10 days'), ('${G}', '${A}', now() - interval '10 days');
    commit;`)
  // Une seance passee de l'eleve adulte : son Suivi a une ligne.
  const seance = sql('select gen_random_uuid()')
  sql(`begin;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
      values ('${seance}', '${prof}', now() - interval '3 days', now() - interval '3 days' + interval '1 hour', 'planned', 'child', '${G}');
    update public.sessions set created_at = now() - interval '5 days' where id = '${seance}';
    insert into public.session_participants (session_id, profile_id, role) values
      ('${seance}', '${A}', 'student'), ('${seance}', '${E}', 'student'), ('${seance}', '${S}', 'student');
    commit;`)

  // L'enseignant depose (sous son jeton), la direction redige et transmet.
  const ids = {}
  for (const [nom, cat, imm] of [['enfant', 'pedagogique', `E2E-D1T-E-${n}`], ['adulte', 'presence', `E2E-D1T-A-${n}`],
    ['securite', 'securite_enfant', `E2E-D1T-S-${n}`]]) {
    ids[nom] = sousJeton(prof, 'teacher', null,
      `select (public.deposer_student_concern('${cat}', '${G}', null, '${imm}', 'E2E note interne ${nom} ${n}', null) ->> 'id')`)
  }
  p.dire(`  signalements : ${JSON.stringify(ids)}`)
  sousJeton(admin, 'admin', null, `select public.rediger_resume_student_concern('${ids.enfant}',
    'Yasmine progresse bien ; elle gagnerait à relire la sourate Al-Fajr avant chaque cours.')`)
  sousJeton(admin, 'admin', null, `select public.transmettre_student_concern('${ids.enfant}', 'tuteur_du_mineur')`)
  sousJeton(admin, 'admin', null, `select public.rediger_resume_student_concern('${ids.adulte}',
    'Votre enseignant a noté deux retards ce mois-ci : merci de rejoindre la salle quelques minutes avant le début.')`)
  sousJeton(admin, 'admin', null, `select public.transmettre_student_concern('${ids.adulte}', 'eleve_adulte')`)
  verifier(sql(`select count(*) from public.notifications where evenement = 'message_academie_eleve'
                 and destinataire = '${T}' and destination = '/tuteur/suivi' and params->>'prenom' = 'Yasmine'`) === '1',
    'base : le titulaire du foyer est prevenu, vers son Historique')
  verifier(sql(`select count(*) from public.notifications where evenement = 'message_academie_eleve'
                 and destinataire = '${A}' and destination = '/eleve/suivi'`) === '1',
    'base : l\'eleve adulte est prevenu, vers son Suivi')
  verifier(sql(`select count(*) from public.notifications where evenement = 'message_academie_eleve'
                 and (params::text like '%sourate%' or params::text like '%retards%' or params::text like '%note interne%')`) === '0',
    'base : aucune notification ne porte le message ni la note interne')
  verifier(sql(`select count(*) from public.notifications where evenement = 'message_academie_eleve'
                 and destinataire in ('${E}', '${S}')`) === '0',
    'base : aucune notification aux enfants')

  p.dire('-- 2. le tuteur : la carte en tete de l\'Historique')
  for (const v of VUES) {
    const c = await p.contexte('tuteur', { vue: v.vue, sombre: v.sombre })
    await connecter(c.page, COMPTE.tuteur)
    await vers(c.page, '/tuteur/suivi')
    const yasmine = await trouver(c.page, /^Yasmine/, { delai: 8000 })
    if (yasmine) { await yasmine.click(); await c.page.waitForTimeout(2500); await activerSemantique(c.page) }
    verifier(await attendreTexte(c.page, "Messages de l'académie sur Yasmine", 30000), `${v.nom} : « Messages de l'académie sur Yasmine »`)
    verifier(await attendreTexte(c.page, 'relire la sourate Al-Fajr', 5000), `${v.nom} : le message transmis`)
    verifier(!(await attendreTexte(c.page, 'note interne', 1500)), `${v.nom} : jamais la note interne`)
    await montrer(c, "Messages de l'académie sur Yasmine", `tuteur_historique_${v.nom}`)
    if (v.nom === '1440_clair') {
      // La notification, vue par le tuteur.
      await vers(c.page, '/tuteur/notifications')
      verifier(await attendreTexte(c.page, 'La direction vous a transmis un message sur Yasmine', 20000),
        'la notification nomme Yasmine, sans le message')
      await p.capture(c, 'tuteur_notification_1440_clair')
      // 3. La soeur : seulement une securite d'un enfant, aucune carte.
      await vers(c.page, '/tuteur/suivi')
      const ines = await trouver(c.page, /^Ines/, { delai: 8000 })
      verifier(ines != null, 'le selecteur propose Ines')
      await ines.click(); await c.page.waitForTimeout(3000); await activerSemantique(c.page)
      verifier(!(await attendreTexte(c.page, "Messages de l'académie", 4000)),
        'securite d\'un enfant : aucune carte pour Ines, aucun resume')
      await p.capture(c, 'tuteur_historique_securite_enfant_aucune_carte_1440_clair')
    }
    await c.ctx.close()
  }

  p.dire('-- 4. l\'eleve adulte : la carte dans son Suivi')
  for (const v of [VUES[0], VUES[2]]) {
    const c = await p.contexte('adulte', { vue: v.vue, sombre: v.sombre })
    await connecter(c.page, COMPTE.adulte)
    await vers(c.page, '/eleve/suivi')
    verifier(await attendreTexte(c.page, "Messages de l'académie", 30000), `${v.nom} : « Messages de l'académie » pour l'eleve adulte`)
    verifier(await attendreTexte(c.page, 'deux retards', 5000), `${v.nom} : son message`)
    await montrer(c, "Messages de l'académie", `adulte_suivi_${v.nom}`)
    await c.ctx.close()
  }

  p.dire('-- 5. l\'enfant ne voit rien')
  verifier(sousJeton(E, 'student', T, 'select count(*)::text from public.concern_famille_v') === '0',
    'base : la vue ne rend rien a l\'enfant (son jeton)')
  verifier(sousJeton(S, 'student', T, 'select count(*)::text from public.concern_famille_v') === '0',
    'base : la vue ne rend rien a la soeur (son jeton)')
  {
    const c = await p.contexte('enfant', { vue: VUES[2].vue })
    await connecter(c.page, COMPTE.enfant)
    await vers(c.page, '/eleve/suivi')
    await c.page.waitForTimeout(3000)
    const lus = (await libelles(c.page)).join(' | ')
    p.dire(`  vus par l'enfant : ${lus.slice(0, 300)}`)
    verifier(!lus.includes("Messages de l'académie") && !lus.includes('sourate'),
      'l\'enfant connecte ne voit ni carte ni message')
    await p.capture(c, 'enfant_ma_classe_aucune_carte_390')
    await c.ctx.close()
  }

  code = await p.fin('vert')
} catch (e) {
  p.dire(`  ${String(e.stack ?? e).slice(0, 1500)}`)
  for (const ctx of p.navigateur.contexts()) {
    for (const pg of ctx.pages()) p.dire(`  visibles : ${(await libelles(pg)).slice(0, 60).join(' | ')}`)
  }
  code = await p.fin('rouge', String(e.message ?? e).slice(0, 300))
}
process.exit(code)
