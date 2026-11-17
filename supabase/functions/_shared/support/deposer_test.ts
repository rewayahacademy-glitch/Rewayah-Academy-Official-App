// PX-BD-SUPPORT : le depot d'un support texte, avec des ports factices (ni base, ni coffre).
import { assert, assertEquals } from 'jsr:@std/assert@1'
import { cleDerivee, deposerSupport, type Json, type PortDepot } from './deposer.ts'

const IDEM = '11111111-2222-4333-8444-555555555555'
const ID = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
const UP = 'bbbbbbbb-bbbb-4ccc-8ddd-eeeeeeeeeeee'

interface Trace { actes: { acte: string; params: Record<string, Json>; cle: string }[]; ecrits: { cle: string; octets: Uint8Array }[] }

function faux(opts: {
  pret?: boolean; prepare?: unknown; confirme?: unknown; ecritureEchoue?: boolean; signatureEchoue?: boolean
} = {}): { port: PortDepot; trace: Trace } {
  const trace: Trace = { actes: [], ecrits: [] }
  const port: PortDepot = {
    pret: () => opts.pret ?? true,
    agir: (acte, params, cle) => {
      trace.actes.push({ acte, params, cle })
      if (acte === 'depot_support_preparer') {
        return Promise.resolve(opts.prepare ?? { ok: true, resultat: { id: ID, version_id: 'v1', revision: 3, upload_id: UP, cle_finale: `supports/${ID}/1/document.md`, etat: 'brouillon' } })
      }
      return Promise.resolve(opts.confirme ?? { ok: true, resultat: { etat: 'brouillon', version_id: 'v1' } })
    },
    ecrire: (cle, octets) => {
      if (opts.ecritureEchoue) return Promise.reject(new Error('r2'))
      trace.ecrits.push({ cle, octets })
      return Promise.resolve()
    },
    signer: (i, e, t) => opts.signatureEchoue ? Promise.reject(new Error('hmac')) : Promise.resolve(`sig:${i}:${e}:${t}`.padEnd(64, '0').slice(0, 64)),
  }
  return { port, trace }
}

const base = { titre: 'Les lettres', langue: 'ar', corps: '# Titre\n\nبِسْمِ اللَّهِ\n', cle_idempotence: IDEM }

Deno.test('nominal : analyse, prepare, ecrit, signe, confirme ; brouillon, jamais publie', async () => {
  const { port, trace } = faux()
  const r = await deposerSupport(base, port)
  assertEquals(r.ok, true)
  assertEquals(r.etat, 'brouillon')
  assertEquals(trace.actes.map((a) => a.acte), ['depot_support_preparer', 'depot_support_confirmer'])
  const octets = new TextEncoder().encode(base.corps)
  assertEquals(trace.actes[0].params.octets, octets.byteLength)
  assertEquals(trace.ecrits.length, 1)
  assertEquals(trace.ecrits[0].cle, `supports/${ID}/1/document.md`)
  assertEquals(trace.ecrits[0].octets, octets)
  // L'empreinte annoncee est celle des octets ecrits.
  const h = await crypto.subtle.digest('SHA-256', octets)
  const hex = Array.from(new Uint8Array(h), (o) => o.toString(16).padStart(2, '0')).join('')
  assertEquals(trace.actes[0].params.sha256, hex)
  assertEquals(trace.actes[1].params.sha256, hex)
  assertEquals(trace.actes[1].params.upload_id, UP)
  assertEquals(trace.actes[0].cle, IDEM)
  assert(trace.actes[1].cle !== IDEM && /^[0-9a-f-]{36}$/.test(trace.actes[1].cle))
})

Deno.test('un texte hors du sous-ensemble est refuse AVANT toute base et tout coffre', async () => {
  for (const corps of ['<b>x</b>', '[lien](http://x)', '![i](a.png)', '| a | b |', '```\ncode\n```', '', '   ', 'a‮b']) {
    const { port, trace } = faux()
    const r = await deposerSupport({ ...base, corps }, port)
    assertEquals(r.erreur, 'format', corps)
    assertEquals(trace.actes.length, 0)
    assertEquals(trace.ecrits.length, 0)
  }
})

Deno.test('plus de 100 000 octets : refus, rien n\'est cree', async () => {
  const { port, trace } = faux()
  const r = await deposerSupport({ ...base, corps: 'a'.repeat(100_001) }, port)
  assertEquals(r.erreur, 'format')
  assertEquals(trace.actes.length, 0)
})

Deno.test('stockage ou secret non regles : rien n\'est cree (aucun brouillon orphelin)', async () => {
  const { port, trace } = faux({ pret: false })
  const r = await deposerSupport(base, port)
  assertEquals(r.erreur, 'stockage_indisponible')
  assertEquals(trace.actes.length, 0)
})

Deno.test('la base refuse la preparation : une cause fermee, aucune ecriture', async () => {
  const { port, trace } = faux({ prepare: { erreur: 'refuse', code: '42501' } })
  const r = await deposerSupport(base, port)
  assertEquals(r, { erreur: 'preparation', cause: 'refuse:42501' })
  assertEquals(trace.ecrits.length, 0)
  assertEquals(trace.actes.length, 1)
})

Deno.test('un parametre refuse par l\'adaptateur est une preparation refusee, jamais un succes', async () => {
  const { port } = faux({ prepare: { ok: true, resultat: { erreur: 'parametre' } } })
  assertEquals((await deposerSupport(base, port)).cause, 'parametre')
})

Deno.test('ecriture R2 en echec : dit que le brouillon existe sans fichier, ne confirme pas', async () => {
  const { port, trace } = faux({ ecritureEchoue: true })
  const r = await deposerSupport(base, port)
  assertEquals(r.erreur, 'stockage')
  assertEquals(r.id, ID)
  assertEquals(trace.actes.map((a) => a.acte), ['depot_support_preparer'])
})

Deno.test('signature impossible ou confirmation refusee : dit l\'etape, rend l\'id', async () => {
  const a = await deposerSupport(base, faux({ signatureEchoue: true }).port)
  assertEquals([a.erreur, a.id], ['confirmation', ID])
  const b = await deposerSupport(base, faux({ confirme: { erreur: 'refuse', code: '42501' } }).port)
  assertEquals([b.erreur, b.cause, b.id], ['confirmation', 'refuse:42501', ID])
})

Deno.test('la cle derivee est stable et differente de la cle d\'origine', async () => {
  assertEquals(await cleDerivee(IDEM, 'confirmer'), await cleDerivee(IDEM.toUpperCase(), 'confirmer'))
  assert((await cleDerivee(IDEM, 'confirmer')) !== (await cleDerivee(IDEM, 'autre')))
})

Deno.test('rayon et description facultatifs ne sont transmis que fournis', async () => {
  const a = faux()
  await deposerSupport(base, a.port)
  assertEquals(Object.keys(a.trace.actes[0].params).sort(), ['langue', 'octets', 'sha256', 'titre'])
  const b = faux()
  await deposerSupport({ ...base, rayon: 'plus_loin', description: 'Fiche' }, b.port)
  assertEquals(b.trace.actes[0].params.rayon, 'plus_loin')
  assertEquals(b.trace.actes[0].params.description, 'Fiche')
})
