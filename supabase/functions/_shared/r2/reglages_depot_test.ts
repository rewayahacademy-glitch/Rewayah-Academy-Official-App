// DEPOT-SIMPLE : la lecture des reglages du depot nomme ce qui manque, par son
// nom, et jamais une valeur. Aucun appel reseau : le seau est simule.

import { assert, assertEquals } from 'jsr:@std/assert@1'
import { DOMAINES, type LecteurEnvironnement, prefixeSecrets, seauAttendu } from './domaines.ts'
import {
  corpsRefusReglage,
  NOM_REGLE_ORIGINE,
  NOM_SECRET_BASE,
  NOM_SECRET_CONFIRMATION,
  origineAdmise,
  reglageManquant,
  reglagesDepot,
  secretsStockageManquants,
} from './reglages_depot.ts'

const HEX32 = 'a'.repeat(32)
const HEX64 = 'b'.repeat(64)
const SECRET = 'un-secret-de-confirmation-de-test-assez-long'
const ORIGINE = 'https://app.rewayahacademy.com'

function env(ajustements: Record<string, string | undefined> = {}): LecteurEnvironnement {
  const table: Record<string, string> = { [NOM_SECRET_CONFIRMATION]: SECRET }
  for (const domaine of DOMAINES) {
    const p = prefixeSecrets(domaine)
    table[`${p}_ACCOUNT_ID`] = HEX32
    table[`${p}_ACCESS_KEY_ID`] = HEX32
    table[`${p}_SECRET_ACCESS_KEY`] = HEX64
    if (domaine === 'supports') table.R2_BUCKET_SUPPORTS = 'rewayah-supports'
    else table[`${p}_BUCKET_NAME`] = seauAttendu(domaine)!
    table[`${p}_ENDPOINT`] = `https://${HEX32}.eu.r2.cloudflarestorage.com`
  }
  return (nom) => (nom in ajustements ? ajustements[nom] : table[nom])
}

function seau(enTetes: Record<string, string>, statut = 200): typeof fetch {
  return (_url, init) => {
    assertEquals((init as RequestInit).method, 'OPTIONS')
    return Promise.resolve(new Response(null, { status: statut, headers: enTetes }))
  }
}

const SEAU_OUVERT = seau({
  'access-control-allow-origin': ORIGINE,
  'access-control-allow-methods': 'GET, PUT',
})

Deno.test('reglages : tout est pose, rien ne manque', async () => {
  const r = await reglagesDepot(ORIGINE, true, env(), SEAU_OUVERT)
  assertEquals(r.manquants, [])
  assertEquals(r.origine, 'admise')
})

Deno.test('reglages : le nom du seau des documents manque, il est nomme', async () => {
  // Le 13/11/2026 : R2_BUCKET_SUPPORTS n'etait pas pose, et rien ne le disait.
  const e = env({ R2_BUCKET_SUPPORTS: undefined })
  assertEquals(secretsStockageManquants(e), ['R2_BUCKET_SUPPORTS'])
  assertEquals(reglageManquant(['priveApplicatif'], e), null)
  assertEquals(reglageManquant(['priveApplicatif', 'supports'], e), 'R2_BUCKET_SUPPORTS')
  const r = await reglagesDepot(ORIGINE, true, e, SEAU_OUVERT)
  assertEquals(r.manquants, ['R2_BUCKET_SUPPORTS'])
})

Deno.test('reglages : plusieurs secrets absents sont tous nommes', () => {
  const e = env({ R2_APP_PRIVATE_ENDPOINT: undefined, R2_APP_PRIVATE_ACCESS_KEY_ID: ' ' })
  assertEquals(secretsStockageManquants(e), ['R2_APP_PRIVATE_ACCESS_KEY_ID', 'R2_APP_PRIVATE_ENDPOINT'])
})

Deno.test('reglages : un secret mal forme est nomme, sa valeur jamais', async () => {
  const e = env({ R2_APP_PRIVATE_ACCOUNT_ID: 'pas-hexadecimal' })
  const r = await reglagesDepot(ORIGINE, true, e, SEAU_OUVERT)
  assert(r.manquants.includes('R2_APP_PRIVATE_ACCOUNT_ID'))
  assert(!JSON.stringify(r).includes('pas-hexadecimal'))
  assert(!JSON.stringify(r).includes(HEX64))
  assert(!JSON.stringify(r).includes('rewayah-supports'))
})

Deno.test('reglages : le secret de confirmation absent, court ou avec une espace', async () => {
  for (const valeur of [undefined, 'court', ` ${SECRET}`, `${SECRET}\n`]) {
    const r = await reglagesDepot(ORIGINE, true, env({ [NOM_SECRET_CONFIRMATION]: valeur }), SEAU_OUVERT)
    assertEquals(r.manquants, [NOM_SECRET_CONFIRMATION])
    assert(!JSON.stringify(r).includes(SECRET))
  }
})

Deno.test('reglages : le secret absent en base est nomme', async () => {
  const r = await reglagesDepot(ORIGINE, false, env(), SEAU_OUVERT)
  assertEquals(r.manquants, [NOM_SECRET_BASE])
})

Deno.test('reglages : le seau qui n admet pas l origine est nomme', async () => {
  // Sans regle d'origine, le navigateur bloque l'envoi : c'etait « la
  // connexion s'est interrompue » le 13/11/2026.
  for (
    const ferme of [
      seau({}, 403),
      seau({ 'access-control-allow-origin': 'https://ailleurs.example', 'access-control-allow-methods': 'PUT' }),
      seau({ 'access-control-allow-origin': ORIGINE, 'access-control-allow-methods': 'GET' }),
    ]
  ) {
    const r = await reglagesDepot(ORIGINE, true, env(), ferme)
    assertEquals(r.origine, 'refusee')
    assertEquals(r.manquants, [NOM_REGLE_ORIGINE])
  }
  // Une etoile admet toute origine.
  assertEquals(
    await origineAdmise(ORIGINE, env(), seau({ 'access-control-allow-origin': '*', 'access-control-allow-methods': 'PUT' })),
    'admise',
  )
})

Deno.test('reglages : sans reponse du seau ou sans origine, rien n est affirme', async () => {
  const panne: typeof fetch = () => Promise.reject(new Error('reseau'))
  const r = await reglagesDepot(ORIGINE, true, env(), panne)
  assertEquals(r.origine, 'inconnue')
  assertEquals(r.manquants, [])
  assertEquals(await origineAdmise(null, env(), SEAU_OUVERT), 'inconnue')
  assertEquals(await origineAdmise('pas une origine', env(), SEAU_OUVERT), 'inconnue')
})

Deno.test('reglages : le nom d un reglage n est rendu qu a la direction', () => {
  // La direction sait lequel poser.
  assertEquals(
    corpsRefusReglage('stockage indisponible', 'R2_BUCKET_SUPPORTS', true),
    { error: 'stockage indisponible', reglage: 'R2_BUCKET_SUPPORTS' },
  )
  // Un eleve, un tuteur, un enseignant : le refus, jamais le nom.
  for (const role of ['student', 'guardian', 'teacher', 'controleur']) {
    const corps = corpsRefusReglage('stockage indisponible', 'R2_BUCKET_SUPPORTS', role === 'admin')
    assertEquals(corps, { error: 'stockage indisponible' })
    assert(!JSON.stringify(corps).includes('R2_'))
  }
  assertEquals(corpsRefusReglage('confirmation indisponible', null, true), { error: 'confirmation indisponible' })
})
