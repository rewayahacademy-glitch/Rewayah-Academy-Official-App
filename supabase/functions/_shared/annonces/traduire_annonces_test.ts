// ANNONCES-SERVEUR (21/11/2026) : la traduction des annonces a l'envoi, sans reseau (faux traducteur, faux
// detecteur, faux client). Lancer : deno test supabase/functions/_shared/annonces/
import { assert, assertEquals } from 'jsr:@std/assert@1'
import { type AnnonceAtraduire, type ClientRpc, traduireAnnonces, traduireUne } from './traduire_annonces.ts'
import { protegerArabe, type Traducteur } from '../courriel/traduction.ts'

const faux: Traducteur = (textes, source, cible) => Promise.resolve(textes.map((t) => `[${source}>${cible}] ${t}`))

function client(lots: AnnonceAtraduire[][]) {
  const consignes: Record<string, unknown>[] = []
  const db: ClientRpc = {
    rpc(fonction, args) {
      if (fonction === 'com_annonce_traductions_reserver') {
        return Promise.resolve({ data: lots.shift() ?? [], error: null })
      }
      consignes.push(args)
      return Promise.resolve({ data: 0, error: null })
    },
  }
  return { db, consignes }
}

const ANNONCE: AnnonceAtraduire = {
  annonce_id: 'a1', titre: 'Rentrée', texte: 'La rentrée est lundi.', langues: ['ar', 'en', 'fr'], langue_source: null,
}

Deno.test('la langue d ecriture est detectee et n est pas traduite ; les deux autres le sont', async () => {
  const r = await traduireUne(ANNONCE, faux, () => Promise.resolve('fr'))
  assertEquals(r.source, 'fr')
  assertEquals(r.erreur, null)
  assertEquals(Object.keys(r.traductions).sort(), ['ar', 'en'])
  assertEquals(r.traductions.en, { titre: '[fr>en] Rentrée', texte: '[fr>en] La rentrée est lundi.' })
})

Deno.test('une langue regionale (pt-BR, zh-CN) se lit sans sa region', async () => {
  const r = await traduireUne({ ...ANNONCE, langues: ['fr'] }, faux, () => Promise.resolve('pt-BR'))
  assertEquals(r.source, 'pt')
  assertEquals(Object.keys(r.traductions), ['fr'])
})

Deno.test('detection impossible (cle absente) : rien n est traduit, la cause remonte', async () => {
  const r = await traduireUne(ANNONCE, faux, () => Promise.reject(new Error('configuration absente : GOOGLE_TRADUCTION_CLE')))
  assertEquals(r.source, null)
  assertEquals(r.traductions, {})
  assertEquals(r.erreur, 'configuration absente : GOOGLE_TRADUCTION_CLE')
})

Deno.test('une langue en echec n empeche pas les autres ; la cause est gardee', async () => {
  const parfois: Traducteur = (t, s, c) => (c === 'ar' ? Promise.reject(new Error('traduction 503')) : faux(t, s, c))
  const r = await traduireUne(ANNONCE, parfois, () => Promise.resolve('fr'))
  assertEquals(Object.keys(r.traductions), ['en'])
  assertEquals(r.erreur, 'traduction 503')
})

Deno.test('une traduction vide est un echec, jamais un texte vide', async () => {
  const vide: Traducteur = (t) => Promise.resolve(t.map(() => ''))
  const r = await traduireUne(ANNONCE, vide, () => Promise.resolve('fr'))
  assertEquals(r.traductions, {})
  assertEquals(r.erreur, 'traduction vide')
})

Deno.test('la langue deja connue n est pas redetectee', async () => {
  let detections = 0
  const r = await traduireUne({ ...ANNONCE, langue_source: 'ar', langues: ['en'] }, faux, () => {
    detections++
    return Promise.resolve('fr')
  })
  assertEquals(detections, 0)
  assertEquals(r.traductions.en.texte, '[ar>en] La rentrée est lundi.')
})

Deno.test('l arabe n est protege que si ni la source ni la cible ne sont l arabe', () => {
  assert(protegerArabe('fr', 'en'))
  assert(!protegerArabe('fr', 'ar'))
  assert(!protegerArabe('ar', 'fr'), 'une annonce ecrite en arabe se traduit')
})

Deno.test('la file est videe lot par lot et chaque annonce est consignee', async () => {
  const { db, consignes } = client([[ANNONCE, { ...ANNONCE, annonce_id: 'a2' }], [{ ...ANNONCE, annonce_id: 'a3' }]])
  const bilan = await traduireAnnonces(db, { traduire: faux, detecter: () => Promise.resolve('fr') })
  assertEquals(bilan, { traduites: 3, echecs: 0 })
  assertEquals(consignes.map((c) => c.p_annonce_id), ['a1', 'a2', 'a3'])
  assertEquals(consignes[0].p_langue_source, 'fr')
  assertEquals(consignes[0].p_erreur, null)
})

Deno.test('le budget de temps arrete la boucle', async () => {
  let t = 0
  const { db, consignes } = client([[ANNONCE], [ANNONCE], [ANNONCE]])
  await traduireAnnonces(db, {
    traduire: faux, detecter: () => Promise.resolve('fr'), budgetMs: 10, maintenant: () => (t += 6),
  })
  assertEquals(consignes.length, 1)
})

Deno.test('une reservation refusee remonte (courriels-envoi la journalise sans s arreter)', async () => {
  const db: ClientRpc = { rpc: () => Promise.resolve({ data: null, error: { message: 'permission denied' } }) }
  let erreur = ''
  try {
    await traduireAnnonces(db, { traduire: faux, detecter: () => Promise.resolve('fr') })
  } catch (e) {
    erreur = (e as Error).message
  }
  assertEquals(erreur, 'reserver les annonces : permission denied')
})
