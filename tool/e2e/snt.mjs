// SNT (03/11/2026) : seance non tenue a T+30, report et nouvelle date, sur la
// pile LOCALE.
//
// Ce que le parcours prouve, a 1440 x 900 et 390 x 844, en clair et en sombre :
//   1. une vraie seance de classe, commencee depuis 31 minutes, ou aucun
//      enseignant n'a rejoint la salle : le passage de chaque minute
//      (private.remplacement_auto_passer) la met en teacher_absent, cree une
//      seance reportee, previent la famille (notification « seance_reportee »)
//      et la direction (e-mail) ; un second passage ne cree rien de plus ;
//   2. le tuteur lit « La séance du … n'a pas eu lieu : elle est reportée.
//      Nouvelle date à venir. » dans ses notifications ;
//   3. la direction voit « Séances reportées » en tete du planning, ouvre
//      « Fixer la nouvelle date », choisit le jour et l'heure ; la nouvelle
//      seance est creee en base avec l'enseignant de la classe et la meme
//      duree, l'eleve inscrit, et la famille est prevenue (seance_deplacee) ;
//   4. Configuration > Regles montre « Séance non tenue » (30 min).
// Chaque etape verifie le texte a l'ecran ou la ligne en base.
//
// Prerequis : migrations 20261106500000 et 20261106500001 appliquees sur la
// pile LOCALE (tool/e2e/pile.sh), comptes amorces (tool/e2e/amorcer.sh).
// Donnees : un tuteur, un eleve, une classe et une seance neufs a chaque
// passage ; rien n'est efface. Usage : node tool/e2e/snt.mjs
import { parcours, trouver, libelles, activerSemantique, amenerEnVue,
  connecter, attendreTexte, nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs'

const p = await parcours('SNT : seance non tenue, reportee, nouvelle date', 'SNT')
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
  await page.waitForTimeout(3500)
  await activerSemantique(page)
}

/// Defile jusqu'au texte puis capture : la capture montre la ligne.
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

const TUTEUR = `e2e-snt-tuteur-${n}@example.com`
const CLASSE = `E2E SNT ${n}`

let code = 1
try {
  verifier(sql("select value::text from public.app_config where key = 'remplacement.seance_non_tenue_minutes'") === '30',
    'base : reglage seance non tenue 30 pose par la migration')

  p.dire('-- 1. banc : une seance de classe sans enseignant entre, a T+31')
  nettoyerClassesE2E()
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`)
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`)
  const tuteur = creerCompte(TUTEUR)
  const eleve = sql('select gen_random_uuid()')
  const classe = sql('select gen_random_uuid()')
  const seance = sql('select gen_random_uuid()')
  sql(`begin;
    insert into auth.users (id, email) values ('${eleve}', 'e2e-snt-eleve-${n}@example.com');
    insert into public.households (id, timezone) values ('${tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${tuteur}', 'E2E-SNT-T-${n}', 'guardian', '${tuteur}', 'Amina', 'FamilleSNT', 'active', 'female'),
           ('${eleve}', 'E2E-SNT-E-${n}', 'student', '${tuteur}', 'Yasmine', 'FamilleSNT', 'active', 'female');
    update public.households set primary_guardian_id = '${tuteur}' where id = '${tuteur}';
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${classe}', '${prof}', 'enfant', 5, '${CLASSE}',
              extract(isodow from (now() at time zone 'Europe/Paris') + interval '3 days')::int, 6, 'Europe/Paris', now() - interval '1 day');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${classe}', '${eleve}', now() - interval '1 day');
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
      values ('${seance}', '${prof}', now() - interval '31 minutes', now() + interval '29 minutes', 'planned', 'child', '${classe}');
    update public.sessions set created_at = now() - interval '1 day' where id = '${seance}';
    insert into public.session_participants (session_id, profile_id, role) values ('${seance}', '${eleve}', 'student');
    commit;`)
  const passage1 = sql('select private.remplacement_auto_passer(clock_timestamp())')
  sql('select private.remplacement_auto_passer(clock_timestamp())')
  p.dire(`  passage : ${passage1}`)
  verifier(sql(`select status from public.sessions where id = '${seance}'`) === 'teacher_absent',
    'base : la seance non tenue est en teacher_absent')
  verifier(sql(`select count(*) from public.seances_reportees where session_id = '${seance}'`) === '1',
    'base : une seule seance reportee apres deux passages')
  verifier(sql(`select count(*) from public.notifications where evenement = 'seance_reportee'
                 and destinataire = '${tuteur}' and params->>'session_id' = '${seance}'`) === '1',
    'base : le tuteur a une notification seance_reportee')
  const courriel = sql(`select modele || ' | ' || destinataire_adresse || ' | ' || cle_idempotence || ' | ' || statut
                          from public.courriels_sortants where cle_idempotence = 'snt-report:${seance}:${admin}'`)
  p.dire(`  courriels_sortants : ${courriel}`)
  verifier(courriel.startsWith('seance_reportee_direction | e2e-direction@example.com'),
    'base : un e-mail seance_reportee_direction a la direction')
  verifier(sql(`select count(*) from public.tresorerie_mouvements where source_id = '${seance}'`) === '0',
    'base : aucune ecriture d\'argent pour la seance non tenue')

  p.dire('-- 2. la famille lit la notification')
  for (const v of VUES) {
    const c = await p.contexte('tuteur', { vue: v.vue, sombre: v.sombre })
    await connecter(c.page, TUTEUR)
    await vers(c.page, '/tuteur/notifications')
    verifier(await attendreTexte(c.page, "n'a pas eu lieu", 30000), `${v.nom} : la famille lit « n'a pas eu lieu »`)
    verifier(await attendreTexte(c.page, 'Nouvelle date à venir', 5000), `${v.nom} : « Nouvelle date à venir »`)
    verifier(!(await attendreTexte(c.page, 'rattrap', 1500)), `${v.nom} : jamais « rattrapage » a la famille`)
    await montrer(c, 'reportée', `famille_notification_${v.nom}`)
    await c.ctx.close()
  }

  p.dire('-- 3. la direction : la section et la feuille')
  const ligne = `Séance reportée de la classe ${CLASSE}`
  // Le geste se fait une fois, a la derniere vue (1440 clair) : apres lui, la
  // section n'a plus de ligne.
  for (const v of [...VUES.slice(1), VUES[0]]) {
    const c = await p.contexte('direction', { vue: v.vue, sombre: v.sombre })
    await connecter(c.page, COMPTES.direction)
    await vers(c.page, '/admin/operations/planning')
    verifier(await attendreTexte(c.page, 'Séances reportées', 30000), `${v.nom} : la section « Séances reportées »`)
    await montrer(c, ligne, `direction_section_${v.nom}`)
    // La ligne est un lien Flutter (<a> sans nom accessible) : son texte la nomme.
    await c.page.waitForTimeout(1500)
    const l = c.page.locator('a').filter({ hasText: ligne }).first()
    verifier(await l.isVisible(), `${v.nom} : la ligne de la classe ${CLASSE}`)
    await amenerEnVue(c.page, l); await l.click(); await c.page.waitForTimeout(1500)
    await activerSemantique(c.page)
    verifier(await attendreTexte(c.page, 'Fixer cette date', 10000), `${v.nom} : la feuille « Fixer la nouvelle date »`)
    await p.capture(c, `direction_feuille_${v.nom}`)
    if (v.nom !== '1440_clair') { await c.ctx.close(); continue }

    // Le geste, une fois : le jour au calendrier, l'heure au menu.
    const jour = await trouver(c.page, 'Jour de la nouvelle séance', { delai: 8000 })
    await amenerEnVue(c.page, jour); await jour.click(); await c.page.waitForTimeout(1200)
    await activerSemantique(c.page)
    const dans = new Date(Date.now() + 9 * 86400000)
    if (dans.getMonth() !== new Date().getMonth()) {
      const suivant = await trouver(c.page, /mois suivant|Next month/i, { delai: 4000 })
      if (suivant) { await suivant.click(); await c.page.waitForTimeout(800) }
    }
    const jourNum = await trouver(c.page, new RegExp(`^${dans.getDate()}\\b`), { delai: 6000 })
    verifier(jourNum != null, `calendrier : le jour ${dans.getDate()}`)
    await jourNum.click(); await c.page.waitForTimeout(600)
    const ok = await trouver(c.page, /^OK$/i, { delai: 4000 })
    if (ok) { await ok.click(); await c.page.waitForTimeout(1000) }
    await activerSemantique(c.page)
    const heure = await trouver(c.page, /^Heure\b/, { delai: 8000, role: 'button' })
    await amenerEnVue(c.page, heure); await heure.click(); await c.page.waitForTimeout(900)
    const h = await trouver(c.page, /^10\s*h$/, { delai: 6000, role: 'menuitem' }) ?? await trouver(c.page, /^10\s*h$/, { delai: 3000 })
    verifier(h != null, 'menu : 10 h')
    await amenerEnVue(c.page, h); await h.click(); await c.page.waitForTimeout(900)
    await p.capture(c, 'direction_feuille_choix_1440_clair')
    const go = await trouver(c.page, 'Fixer cette date', { delai: 6000 })
    await amenerEnVue(c.page, go); await go.click(); await c.page.waitForTimeout(3500)
    verifier(await attendreTexte(c.page, 'Nouvelle date fixée', 15000), 'la feuille dit « Nouvelle date fixée »')
    await p.capture(c, 'direction_nouvelle_date_fixee_1440_clair')
    await c.ctx.close()
  }
  const nouvelle = sql(`select seance_nouvelle_id from public.seances_reportees where session_id = '${seance}'`)
  verifier(nouvelle !== '', 'base : la seance reportee porte sa nouvelle seance')
  verifier(sql(`select (teacher_id = '${prof}' and groupe_id = '${classe}' and status = 'planned'
                        and ended_at - started_at = interval '60 minutes'
                        and extract(hour from started_at at time zone 'Europe/Paris') = 10)::text
                  from public.sessions where id = '${nouvelle}'`) === 'true',
    'base : nouvelle seance de la meme classe, meme enseignant, 60 minutes, a 10 h')
  verifier(sql(`select count(*) from public.session_participants where session_id = '${nouvelle}' and profile_id = '${eleve}'`) === '1',
    'base : l\'eleve est inscrit a la nouvelle seance')
  verifier(sql(`select count(*) from public.notifications where evenement = 'seance_deplacee'
                 and destinataire = '${tuteur}' and params->>'session_id' = '${nouvelle}'`) === '1',
    'base : la famille est prevenue de la nouvelle date (seance_deplacee)')

  p.dire('-- 4. Configuration > Regles')
  for (const v of VUES) {
    const c = await p.contexte('direction', { vue: v.vue, sombre: v.sombre })
    await connecter(c.page, COMPTES.direction)
    await vers(c.page, '/admin/configuration/regles')
    verifier(await attendreTexte(c.page, 'Séance non tenue', 30000), `${v.nom} : « Séance non tenue » affiche`)
    verifier(await attendreTexte(c.page, 'la séance est reportée', 5000), `${v.nom} : son detail dit le report`)
    await montrer(c, 'Séance non tenue', `regles_seance_non_tenue_${v.nom}`)
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
