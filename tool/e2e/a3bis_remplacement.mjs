// A3-bis (02/11/2026) : le remplacement sans perte de seance, sur la pile LOCALE.
//
// Ce que le parcours prouve :
//   1. la page Configuration > Regles montre, a 1440 x 900 et 390 x 844, les
//      deux reglages nouveaux (« Alerte de la direction » 3 min, « Seance
//      creee tard » 15 min) et le texte corrige de « Perte de la seance » ;
//   2. sur le banc, une seance commencee depuis plus de 3 minutes sans
//      personne dans la salle donne, au passage de la minute, une ligne
//      courriels_sortants « remplacement_personne_en_salle » pour la
//      direction, une seule meme apres trois passages ; sans remplacant pret,
//      aucune absence n'est posee.
// Chaque etape verifie le texte a l'ecran ou la ligne en base.
//
// Prerequis : la migration 20261105700000 appliquee sur la pile LOCALE
// (tool/e2e/pile.sh), comptes amorces (tool/e2e/amorcer.sh). Usage :
// node tool/e2e/a3bis_remplacement.mjs
import { parcours, trouver, libelles, activerSemantique, amenerEnVue,
  connecter, attendreTexte, nettoyerClassesE2E, sql, COMPTES } from './commun.mjs'

const p = await parcours('A3-bis : remplacement sans perte de seance', 'a3bis-remplacement')
const n = Date.now() % 1000000
const BUREAU = { vue: { width: 1440, height: 900 } }
const TEL = { vue: { width: 390, height: 844 } }

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
  const e = await trouver(acteur.page, texte, { delai: 15000 })
  if (e) {
    await amenerEnVue(acteur.page, e)
    // La ligne au milieu de l'ecran, jamais coupee au bord (L2).
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

async function regles(acteur, taille) {
  await connecter(acteur.page, COMPTES.direction)
  await vers(acteur.page, '/admin/configuration/regles')
  verifier(await attendreTexte(acteur.page, 'Alerte de la direction', 30000),
    `${taille} : « Alerte de la direction » affiche`)
  verifier(await attendreTexte(acteur.page, 'Séance créée tard', 5000),
    `${taille} : « Séance créée tard » affiche`)
  verifier(await attendreTexte(acteur.page, "Si personne ne s'est proposé, l'enseignant peut encore entrer", 5000),
    `${taille} : la perte de la seance dit la regle A3-bis`)
  verifier(!(await attendreTexte(acteur.page, "est noté absent et ne peut plus rejoindre", 2000)),
    `${taille} : l'ancien texte de la perte a disparu`)
  verifier(!(await attendreTexte(acteur.page, "avis dans l'application", 2000)),
    `${taille} : l'alerte ne promet pas d'avis dans l'application (e-mail seul)`)
  verifier(await attendreTexte(acteur.page, "qu'il risque de perdre la séance", 5000),
    `${taille} : l'avertissement dit « risque de perdre »`)
  await montrer(acteur, 'Alerte de la direction', `regles_alerte_${taille}`)
  await montrer(acteur, 'Séance créée tard', `regles_seance_tardive_${taille}`)
}

let code = 1
try {
  verifier(sql("select value::text from public.app_config where key = 'remplacement.alerte_direction_minutes'") === '3'
    && sql("select value::text from public.app_config where key = 'remplacement.seance_tardive_minutes'") === '15',
    'base : reglages 3 et 15 poses par la migration')

  p.dire('-- 1. page Regles, bureau puis telephone')
  await regles(await p.contexte('direction', BUREAU), '1440')
  await regles(await p.contexte('direction', TEL), '390')

  p.dire('-- 2. banc : seance sans personne dans la salle')
  nettoyerClassesE2E()
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`)
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`)
  const classe = sql('select gen_random_uuid()')
  const seance = sql('select gen_random_uuid()')
  sql(`begin;
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${classe}', '${prof}', 'enfant', 5, 'E2E A3bis ${n}',
              extract(isodow from (now() at time zone 'Europe/Paris') + interval '3 days')::int, 6, 'Europe/Paris', now() - interval '1 day');
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
      values ('${seance}', '${prof}', now() - interval '4 minutes', now() + interval '41 minutes', 'planned', 'standard', '${classe}');
    update public.sessions set created_at = now() - interval '1 day' where id = '${seance}';
    commit;`)
  for (let i = 0; i < 3; i++) sql('select private.remplacement_auto_passer(clock_timestamp())')
  const ligne = sql(`select modele || ' | ' || categorie || ' | ' || destinataire_adresse || ' | ' || cle_idempotence || ' | ' || statut || ' | ' || (donnees - 'prenom')::text
                       from public.courriels_sortants
                      where cle_idempotence = 'a3bis-alerte:${seance}:${admin}'`)
  p.dire(`  courriels_sortants : ${ligne}`)
  verifier(ligne.startsWith('remplacement_personne_en_salle | classes | e2e-direction@example.com'),
    'base : une ligne courriels_sortants « remplacement_personne_en_salle » pour la direction')
  verifier(sql(`select count(*) from public.courriels_sortants where cle_idempotence = 'a3bis-alerte:${seance}:${admin}'`) === '1',
    'base : une seule ligne apres trois passages')
  verifier(sql(`select count(*) from public.remplacements_seance where session_id = '${seance}'`) === '0',
    'base : sans remplacant pret, aucune absence posee, le titulaire garde la seance')

  code = await p.fin('vert')
} catch (e) {
  p.dire(`  ${String(e.stack ?? e).slice(0, 1500)}`)
  for (const ctx of p.navigateur.contexts()) {
    for (const pg of ctx.pages()) p.dire(`  visibles : ${(await libelles(pg)).slice(0, 50).join(' | ')}`)
  }
  code = await p.fin('rouge', String(e.message ?? e).slice(0, 300))
}
process.exit(code)
