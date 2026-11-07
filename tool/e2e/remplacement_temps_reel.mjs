// REMPLACEMENT-TEMPS-REEL (07/11/2026) : la fenetre de priorite, sur la pile
// LOCALE, avec des donnees de test seulement.
//
// Ce que le parcours prouve, a 1440 x 900 puis a 390 x 844 :
//   A. l'enseignant de test (homme, francais) accepte seul une classe de
//      femmes en arabe (rang 4) : « Vous etes en tete… » et le compte a
//      rebours s'affichent ; a la fin de la fenetre, le serveur le retient et
//      la page dit « C'est confirme » ;
//   B. une collegue mieux placee (rang 2) a accepte juste avant lui : la page
//      dit « Un collegue a aussi accepte… », jamais « en tete » ; a la fin de
//      la fenetre, le serveur la retient et la page dit « Un autre enseignant
//      a pris ce cours ».
// Chaque etape verifie le texte a l'ecran et la ligne en base.
//
// Prerequis : la migration 20261119300000 appliquee sur la pile LOCALE
// (tool/e2e/pile.sh), comptes amorces (tool/e2e/amorcer.sh). Usage :
// node tool/e2e/remplacement_temps_reel.mjs
import fs from 'node:fs'
import path from 'node:path'
import { parcours, libelles, activerSemantique, connecter, attendreTexte,
  trouver, nettoyerClassesE2E, sql, COMPTES, DEPOT } from './commun.mjs'

const p = await parcours('Remplacement en temps reel : la fenetre de priorite', 'remplacement-temps-reel')
const VUES = [['1440', { width: 1440, height: 900 }], ['390', { width: 390, height: 844 }]]
const ROUTE = '/enseignant/journee/remplacements'
const T = '7e5e0000-0000-4000-8000-000000000001'
const R = '7e5e0000-0000-4000-8000-000000000002'
const CLASSE = '7e5e0000-0000-4000-8000-000000000101'
const ASSURER = 'Assurer ce remplacement'
const EN_TETE = 'Vous êtes en tête, confirmation dans quelques secondes.'
const ATTENTE = 'Un collègue a aussi accepté : confirmation dans quelques secondes.'
const CONFIRME = "C'est confirmé : vous assurez cette séance."
const PRIS = 'Un autre enseignant a pris ce cours. Merci.'

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`)
  p.dire(`  OK ${message}`)
}

/// Recharge la page sur [chemin] : le tableau des offres est relu (il est
/// garde en memoire d'un ecran a l'autre, et relu toutes les 30 s seulement).
async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}` }, chemin)
  await page.reload()
  await page.waitForTimeout(6000)
  await activerSemantique(page)
}

/// Une seance de la classe d'essai, a [jours] d'ici, et l'absence du
/// titulaire. Les seances d'essai precedentes sont retirees.
function seanceOuverte(jours) {
  const s = sql('select gen_random_uuid()')
  sql(`begin;
    update public.sessions set deleted_at = now() where groupe_id = '${CLASSE}' and deleted_at is null;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
      values ('${s}', '${T}', now() + interval '${jours} days', now() + interval '${jours} days 45 minutes',
              'planned', 'standard', '${CLASSE}');
    insert into public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence)
      values ('${s}', 'absence_declaree', '${T}', '${T}', gen_random_uuid());
    commit;`)
  return s
}

function retenu(s) {
  return sql(`select coalesce(string_agg(enseignant_remplacant_id::text, ','), '')
                from public.remplacements_seance where session_id = '${s}' and evenement = 'remplacement_pris'`)
}

async function compter(page, texte) {
  return (await libelles(page)).filter((l) => l.includes(texte)).length
}

let code = 1
try {
  verifier(sql("select to_regclass('private.remplacements_acceptations') is not null") === 't',
    'base : la migration 20261119300000 est appliquee sur la pile locale')
  verifier(sql("select value::text from public.app_config where key = 'remplacement.fenetre_priorite_secondes'") === '8',
    'base : fenetre de 8 s')
  nettoyerClassesE2E()
  sql(fs.readFileSync(path.join(DEPOT, 'tool/e2e/remplacement_temps_reel_amorce.sql'), 'utf8'))
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`)
  // Les offres ouvertes d'autres parcours ne doivent pas preter a confusion.
  sql(`update public.sessions s set deleted_at = now()
        where s.deleted_at is null and s.groupe_id is distinct from '${CLASSE}'
          and exists (select 1 from public.remplacements_seance r where r.session_id = s.id)`)

  let jours = 20
  for (const [taille, vue] of VUES) {
    const acteur = await p.contexte('enseignant', { vue })
    // Le journal garde chaque reponse du serveur a l'acceptation.
    acteur.page.on('response', async (r) => {
      if (/\/rpc\/(prendre|offres)_remplacement/.test(r.url())) {
        p.dire(`  [serveur] ${r.url().split('/rpc/')[1]} ${r.status()} ${(await r.text().catch(() => '')).slice(0, 200)}`)
      }
    })
    await connecter(acteur.page, COMPTES.enseignant)

    p.dire(`-- ${taille} A : seul a accepter, en tete puis retenu`)
    const a = seanceOuverte(jours++)
    verifier(sql(`select private.remplacement_rang('${a}', '${prof}')`) === '4',
      `${taille} A : rang 4 (ni le genre ni la langue de la classe)`)
    await vers(acteur.page, ROUTE)
    verifier(await attendreTexte(acteur.page, ASSURER, 20000) && (await compter(acteur.page, ASSURER)) === 1,
      `${taille} A : une seule offre, « ${ASSURER} »`)
    await (await trouver(acteur.page, ASSURER)).click()
    verifier(await attendreTexte(acteur.page, EN_TETE, 4000), `${taille} A : « en tete » s'affiche`)
    verifier((await libelles(acteur.page)).some((l) => /\b\d{1,2} s\b/.test(l)),
      `${taille} A : le compte a rebours s'affiche`)
    await p.capture(acteur, `${taille}_a_en_tete`)
    verifier(retenu(a) === '', `${taille} A : personne n'est retenu pendant la fenetre`)
    verifier(await attendreTexte(acteur.page, CONFIRME, 20000), `${taille} A : « C'est confirme » a la fin de la fenetre`)
    verifier(retenu(a) === prof, `${taille} A : le serveur l'a retenu, une seule prise`)
    await acteur.page.waitForTimeout(600)
    await p.capture(acteur, `${taille}_a_confirme`)

    p.dire(`-- ${taille} B : une collegue mieux placee a accepte avant`)
    const b = seanceOuverte(jours++)
    await vers(acteur.page, ROUTE)
    verifier(await attendreTexte(acteur.page, ASSURER, 20000) && (await compter(acteur.page, ASSURER)) === 1,
      `${taille} B : une seule offre ouverte`)
    sql(`insert into private.remplacements_acceptations (absence_id, session_id, enseignant_id, rang, cle_idempotence)
         select r.id, r.session_id, '${R}', private.remplacement_rang(r.session_id, '${R}'), gen_random_uuid()
           from public.remplacements_seance r where r.session_id = '${b}' and r.evenement = 'absence_declaree'`)
    verifier(sql(`select rang from private.remplacements_acceptations where session_id = '${b}' and enseignant_id = '${R}'`) === '2',
      `${taille} B : la collegue est au rang 2 (genre de la classe)`)
    await (await trouver(acteur.page, ASSURER)).click()
    verifier(await attendreTexte(acteur.page, ATTENTE, 4000), `${taille} B : « Un collegue a aussi accepte » s'affiche`)
    verifier((await compter(acteur.page, EN_TETE)) === 0, `${taille} B : jamais « en tete »`)
    await p.capture(acteur, `${taille}_b_attente`)
    verifier(await attendreTexte(acteur.page, PRIS, 20000), `${taille} B : « Un autre enseignant a pris ce cours »`)
    verifier(retenu(b) === R, `${taille} B : le serveur a retenu la collegue, une seule prise`)
    await acteur.page.waitForTimeout(600)
    await p.capture(acteur, `${taille}_b_pris_par_un_autre`)
    await acteur.page.context().close()
  }
  sql(`update public.sessions set deleted_at = now() where groupe_id = '${CLASSE}' and deleted_at is null`)
  code = await p.fin('vert')
} catch (e) {
  p.dire(`  ${String(e.stack ?? e).slice(0, 1500)}`)
  for (const ctx of p.navigateur.contexts()) {
    for (const pg of ctx.pages()) p.dire(`  visibles : ${(await libelles(pg)).slice(0, 50).join(' | ')}`)
  }
  code = await p.fin('rouge', String(e.message ?? e).slice(0, 300))
}
process.exit(code)
