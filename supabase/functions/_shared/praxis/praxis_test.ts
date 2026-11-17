// PX-1 (SEC-1) : tests Deno du connecteur MCP de Praxis. Aucun appel reseau : la base est un faux qui note ses appels.
// Ce qu'ils prouvent (SECURITE-PRAXIS.md R1, R2, §2 menace 9) :
//  - sans cle bien formee, la base n'est jamais appelee ;
//  - un parametre hors schema est refuse AVANT la base ;
//  - la liste des outils est exactement la liste blanche, et chaque outil appelle UNE fonction praxis_* ;
//  - une cle refusee par la base ressort comme une erreur d'outil, sans detail ;
//  - un appel trop long est coupe (delai), proprement ;
//  - la cle n'apparait dans aucune reponse.

import { assertEquals, assert } from 'jsr:@std/assert@1'
import { type PortePraxis, traiter, DELAI_MS, TAILLE_MAX } from './mcp.ts'
import { OUTILS, PUBLICS } from './outils.ts'

const CLE = 'prx_' + 'a'.repeat(64)
const UUID1 = '5c1acccc-0000-4000-8000-000000000001'
const UUID2 = '5c1a1111-0000-4000-8000-000000000050'

interface Appel { fonction: string; params: Record<string, unknown> }

function faux(reponse: unknown = { ok: true }): { porte: PortePraxis; appels: Appel[] } {
  const appels: Appel[] = []
  return {
    appels,
    porte: {
      appeler(fonction, params) {
        appels.push({ fonction, params })
        return Promise.resolve(reponse)
      },
    },
  }
}

function requete(corps: unknown, entetes: Record<string, string> = { Authorization: `Bearer ${CLE}` }, methode = 'POST'): Request {
  return new Request('https://exemple.test/praxis-mcp', {
    method: methode,
    headers: { 'Content-Type': 'application/json', ...entetes },
    body: methode === 'POST' ? (typeof corps === 'string' ? corps : JSON.stringify(corps)) : undefined,
  })
}

const appelOutil = (name: string, args?: unknown, id = 1) => ({
  jsonrpc: '2.0', id, method: 'tools/call', params: { name, arguments: args },
})

Deno.test('sans cle : refus 401 et la base n\'est jamais appelee', async () => {
  for (const entetes of <Record<string, string>[]>[{}, { Authorization: 'Bearer' }, { Authorization: 'Basic abc' }, { Authorization: 'Bearer prx_court' },
    { Authorization: 'Bearer rag_' + 'a'.repeat(64) }, { Authorization: 'Bearer ' + 'a'.repeat(64) }]) {
    const { porte, appels } = faux()
    const r = await traiter(requete(appelOutil('etat'), entetes), porte)
    assertEquals(r.status, 401)
    assertEquals(await r.json(), { error: 'cle_refusee' })
    assertEquals(appels.length, 0)
  }
})

Deno.test('methode, taille, JSON : refus propres, base non appelee', async () => {
  const { porte, appels } = faux()
  assertEquals((await traiter(requete(null, undefined, 'GET'), porte)).status, 405)
  assertEquals((await traiter(requete('x'.repeat(TAILLE_MAX + 1)), porte)).status, 413)
  const mal = await (await traiter(requete('pas du json'), porte)).json()
  assertEquals(mal.error.code, -32700)
  const nu = await (await traiter(requete({ jsonrpc: '1.0', method: 'etat', id: 1 }), porte)).json()
  assertEquals(nu.error.code, -32600)
  assertEquals(appels.length, 0)
})

Deno.test('initialize, ping, notification', async () => {
  const { porte, appels } = faux()
  const i = await (await traiter(requete({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-03-26' } }), porte)).json()
  assertEquals(i.result.protocolVersion, '2025-03-26')
  assertEquals(i.result.serverInfo.name, 'praxis')
  const p = await (await traiter(requete({ jsonrpc: '2.0', id: 2, method: 'ping' }), porte)).json()
  assertEquals(p.result, {})
  const n = await traiter(requete({ jsonrpc: '2.0', method: 'notifications/initialized' }), porte)
  assertEquals(n.status, 202)
  const inconnue = await (await traiter(requete({ jsonrpc: '2.0', id: 3, method: 'resources/list' }), porte)).json()
  assertEquals(inconnue.error.code, -32601)
  assertEquals(appels.length, 0)
})

Deno.test('R2 : tools/list est la liste blanche exacte, sans alerter_responsable', async () => {
  const { porte } = faux()
  const l = await (await traiter(requete({ jsonrpc: '2.0', id: 1, method: 'tools/list' }), porte)).json()
  const noms = l.result.tools.map((t: { name: string }) => t.name).sort()
  assertEquals(noms, ['acte_confirmer', 'acte_preparer', 'actes', 'agir', 'annoncer', 'boite', 'calendrier_ajouter', 'calendrier_lire', 'ecrire', 'etat', 'fil', 'lire', 'preparer', 'rendre_compte', 'support_deposer', 'terminer'])
  for (const t of l.result.tools) assertEquals(t.inputSchema.additionalProperties, false)
  const fonctions = OUTILS.map((o) => o.fonction).sort()
  assertEquals(new Set(fonctions).size, fonctions.length) // une fonction par outil
  assert(fonctions.every((f) => /^praxis_[a-z_]+$/.test(f)))
  assert(!fonctions.includes('praxis_alerter_responsable'))
})

Deno.test('R1 : tout parametre hors schema est refuse avant la base', async () => {
  const mauvais: [string, unknown][] = [
    ['ecrire', { fil: UUID1, texte: 'Bonjour', cle_idempotence: UUID2, destinataire: UUID1 }], // propriete inconnue
    ['ecrire', { fil: 'pas-un-uuid', texte: 'Bonjour', cle_idempotence: UUID2 }],
    ['ecrire', { fil: UUID1, texte: 'a'.repeat(1501), cle_idempotence: UUID2 }],
    ['ecrire', { fil: UUID1, texte: '   ', cle_idempotence: UUID2 }],
    ['ecrire', { fil: UUID1, texte: 'x\u0000y', cle_idempotence: UUID2 }],
    ['ecrire', { fil: UUID1, texte: 'Bonjour' }], // cle absente
    ['ecrire', { fil: UUID1, texte: 12, cle_idempotence: UUID2 }],
    ['ecrire', 'une requete SQL'],
    ['boite', { filtre: 'tout; DROP TABLE x', limite: 10 }],
    ['boite', { limite: 51 }],
    ['boite', { limite: 1.5 }],
    ['fil', { fil: UUID1, limite: 0 }],
    ['annoncer', { publics: ['eleves'], titre: 'T', texte: 'x', cle_idempotence: UUID2 }], // « eleves » : mineurs
    ['annoncer', { publics: [], titre: 'T', texte: 'x', cle_idempotence: UUID2 }],
    ['annoncer', { publics: ['familles'], titre: 'T'.repeat(121), texte: 'x', cle_idempotence: UUID2 }],
    ['annoncer', { publics: ['familles'], titre: 'T', texte: 'x'.repeat(3001), cle_idempotence: UUID2 }],
    ['annoncer', { publics: ['familles'], titre: 'T', texte: 'x', cle_idempotence: UUID2, courriel: true }], // jamais de courriel
    ['calendrier_lire', { du: '2026-13-45', au: '2026-12-01' }],
    ['calendrier_lire', { du: '2026-01-01' }],
    ['calendrier_ajouter', { sujet: 's', public: 'eleves', date: '2026-12-01', cle_idempotence: UUID2 }],
    ['rendre_compte', { heures: 169 }],
    // PX-2 : lire et preparer
    ['lire', { vue: 'profiles' }], // vue hors liste
    ['lire', { vue: 'candidatures', filtre: { courriel: 'x@y.z' } }], // pas d'objet libre : un argument `filtre` n'existe pas
    ['lire', { vue: 'candidatures', requete: 'select 1' }],
    ['lire', { vue: 'candidatures', etape: 'archivee' }],
    ['lire', { vue: 'candidatures', langue: 'FR; DROP' }],
    ['lire', { vue: 'candidatures', attente_min_jours: 366 }],
    ['lire', { vue: 'candidatures', limite: 51 }],
    ['lire', {}],
    ['preparer', { geste: 'refuser', candidature: 'CAND-00001', texte: 'x', cle_idempotence: UUID2 }], // geste hors liste fermee
    ['preparer', { geste: 'admettre_verifications', candidature: '00001', texte: 'x', cle_idempotence: UUID2 }],
    ['preparer', { geste: 'admettre_verifications', candidature: 'CAND-00001', texte: 'x', cle_idempotence: UUID2, courriel: 'a@b.c' }],
    ['preparer', { geste: 'demander_complement', candidature: 'CAND-00001', elements: ['Piece Identite'], motif: 'm', texte: 'x', cle_idempotence: UUID2 }],
    ['preparer', { geste: 'demander_complement', candidature: 'CAND-00001', elements: [], motif: 'm', texte: 'x', cle_idempotence: UUID2 }],
    ['preparer', { geste: 'planifier_entretien', candidature: 'CAND-00001', debut: 'demain', duree_minutes: 30, texte: 'x', cle_idempotence: UUID2 }],
    ['preparer', { geste: 'planifier_entretien', candidature: 'CAND-00001', debut: '2026-12-01T10:00:00Z', duree_minutes: 5, texte: 'x', cle_idempotence: UUID2 }],
    ['preparer', { geste: 'admettre_verifications', candidature: 'CAND-00001', texte: 'x'.repeat(1001), cle_idempotence: UUID2 }],
    // PRAXIS-ROUTINE : terminer
    ['terminer', { issue: 'zz', fils_lus: 0, messages_envoyes: 0, passes_equipe: 0, refus: 0 }],
    ['terminer', { issue: 'ok', fils_lus: 201, messages_envoyes: 0, passes_equipe: 0, refus: 0 }],
    ['terminer', { issue: 'ok', fils_lus: -1, messages_envoyes: 0, passes_equipe: 0, refus: 0 }],
    ['terminer', { issue: 'ok', fils_lus: 0, messages_envoyes: 0, passes_equipe: 0 }], // refus absent
    ['terminer', { issue: 'ok', fils_lus: 0, messages_envoyes: 0, passes_equipe: 0, refus: 0, note: 'x'.repeat(201) }],
    ['terminer', { issue: 'ok', fils_lus: 0, messages_envoyes: 0, passes_equipe: 0, refus: 0, courriel: 'a@b.c' }],
    ['alerter_responsable', {}], // outil non livre
    ['etat', { quoi: 'que ce soit' }],
  ]
  for (const [nom, args] of mauvais) {
    const { porte, appels } = faux()
    const r = await (await traiter(requete(appelOutil(nom, args)), porte)).json()
    assertEquals(r.error?.code, -32602, `${nom} ${JSON.stringify(args)} aurait du etre refuse`)
    // Le seul appel admis est la note de refus (M4) : jamais une fonction d'outil, jamais un parametre de l'appelant.
    assert(appels.every((a) => a.fonction === 'praxis_noter_refus' && Object.keys(a.params).sort().join() === 'p_cle,p_outil'),
      `${nom} : la base ne doit recevoir que la note de refus`)
    assert(appels.length <= 1)
  }
})

Deno.test('PX-2 : lire et preparer composent un objet jsonb ferme (jamais une requete)', async () => {
  {
    const { porte, appels } = faux({ ok: true })
    await traiter(requete(appelOutil('lire', { vue: 'candidatures', etape: 'verifications', attente_min_jours: 3 })), porte)
    assertEquals(appels.length, 1)
    assertEquals(appels[0].fonction, 'praxis_lire')
    assertEquals(appels[0].params, {
      p_cle: CLE, p_vue: 'candidatures', p_filtre: { etape: 'verifications', attente_min_jours: 3 }, p_limite: 20,
    })
  }
  {
    const { porte, appels } = faux({ ok: true })
    await traiter(requete(appelOutil('lire', { vue: 'demandes' })), porte)
    assertEquals(appels[0].params, { p_cle: CLE, p_vue: 'demandes', p_filtre: {}, p_limite: 20 }) // objet vide, jamais null
  }
  {
    const { porte, appels } = faux({ ok: true })
    await traiter(requete(appelOutil('preparer', {
      geste: 'demander_complement', candidature: 'CAND-00042', elements: ['langues', 'piece_identite'], motif: 'Il manque des informations.',
      texte: 'Le dossier est a completer.', cle_idempotence: UUID2,
    })), porte)
    assertEquals(appels[0].fonction, 'praxis_preparer')
    assertEquals(appels[0].params, {
      p_cle: CLE, p_geste: 'demander_complement', p_candidature: 'CAND-00042',
      p_parametres: { elements: ['langues', 'piece_identite'], motif: 'Il manque des informations.' },
      p_texte: 'Le dossier est a completer.', p_cle_idempotence: UUID2,
    })
  }
  {
    const { porte, appels } = faux({ ok: true })
    await traiter(requete(appelOutil('preparer', {
      geste: 'admettre_verifications', candidature: 'CAND-00042', texte: 'Admettre.', cle_idempotence: UUID2,
    })), porte)
    assertEquals(appels[0].params.p_parametres, {}) // objet vide
  }
})

Deno.test('appel nominal : une fonction praxis_*, la cle en premier, parametres types, defauts', async () => {
  {
    const { porte, appels } = faux({ ok: true, id: UUID1 })
    const r = await (await traiter(requete(appelOutil('ecrire', { fil: UUID1, texte: ' Bonjour ', cle_idempotence: UUID2 })), porte)).json()
    assertEquals(appels, [{ fonction: 'praxis_ecrire', params: { p_cle: CLE, p_fil: UUID1, p_texte: ' Bonjour ', p_cle_idempotence: UUID2 } }])
    assertEquals(r.result.isError, false)
    assertEquals(JSON.parse(r.result.content[0].text), { ok: true, id: UUID1 })
  }
  {
    const { porte, appels } = faux({ fils: [] })
    await traiter(requete(appelOutil('boite')), porte)
    assertEquals(appels, [{ fonction: 'praxis_boite', params: { p_cle: CLE, p_filtre: 'attend', p_limite: 20 } }])
  }
  {
    const { porte, appels } = faux({})
    await traiter(requete(appelOutil('annoncer', { publics: ['familles', 'enseignants'], titre: 'T', texte: 'x', cle_idempotence: UUID2 })), porte)
    assertEquals(appels[0].fonction, 'praxis_annoncer')
    assertEquals(appels[0].params.p_publics, ['familles', 'enseignants'])
  }
  {
    const { porte, appels } = faux({})
    await traiter(requete(appelOutil('etat')), porte)
    assertEquals(appels, [{ fonction: 'praxis_etat', params: { p_cle: CLE } }])
  }
  {
    const { porte, appels } = faux({ ok: true })
    await traiter(requete(appelOutil('terminer', { issue: 'ok', fils_lus: 7, messages_envoyes: 4, passes_equipe: 2, refus: 1, note: 'Tout va bien' })), porte)
    assertEquals(appels, [{ fonction: 'praxis_terminer', params: { p_cle: CLE, p_issue: 'ok', p_lus: 7, p_envoyes: 4, p_passes: 2, p_refus: 1, p_note: 'Tout va bien' } }])
  }
  for (const p of PUBLICS) assert(p !== ('eleves' as string))
})

Deno.test('un refus de la base (cle, plafond, mineur...) ressort comme erreur d\'outil, sans la cle', async () => {
  for (const cause of ['cle_refusee', 'eteint', 'plafond', 'mineur', 'repris_par_equipe']) {
    const { porte } = faux({ erreur: cause })
    const r = await traiter(requete(appelOutil('ecrire', { fil: UUID1, texte: 'x', cle_idempotence: UUID2 })), porte)
    const t = await r.text()
    assert(JSON.parse(t).result.isError)
    assert(t.includes(cause))
    assert(!t.includes(CLE), 'la cle ne doit apparaitre dans aucune reponse')
  }
})

Deno.test('une erreur de la base ne fuit aucun detail ; un appel trop long est coupe (delai)', async () => {
  const casse: PortePraxis = { appeler: () => Promise.reject(new Error('relation "secret.table" : mot de passe xyz')) }
  const r = await traiter(requete(appelOutil('etat')), casse)
  const t = await r.text()
  assertEquals(JSON.parse(t).result.isError, true)
  assert(!t.includes('secret.table') && !t.includes('xyz'))
  assert(t.includes('serveur'))

  // Delai : la porte ne repond jamais ; on raccourcit l'attente en simulant l'annulation du signal.
  const lent: PortePraxis = {
    appeler: (_f, _p, signal) => new Promise((_, rej) => {
      signal.addEventListener('abort', () => rej(Object.assign(new Error('abort'), { name: 'AbortError' })))
    }),
  }
  const vrai = globalThis.setTimeout
  // deno-lint-ignore no-explicit-any
  ;(globalThis as any).setTimeout = (f: () => void, _ms: number) => vrai(f, 5)
  try {
    const d = await traiter(requete(appelOutil('etat')), lent)
    assert(JSON.parse(await d.text()).result.content[0].text.includes('delai'))
  } finally {
    // deno-lint-ignore no-explicit-any
    ;(globalThis as any).setTimeout = vrai
  }
  assert(DELAI_MS <= 10000)
})

Deno.test('la cle ne peut etre remplacee par aucun parametre prepare', async () => {
  // (a) Aucun parametre de la liste fermee ne s'appelle p_cle.
  for (const o of OUTILS) for (const d of o.parametres) assert(d.param !== 'p_cle', `${o.nom} : ${d.param}`)
  // (b) Un appelant ne peut pas poser `p_cle` : propriete inconnue, refusee avant la base.
  {
    const { porte, appels } = faux()
    const r = await (await traiter(requete(appelOutil('etat', { p_cle: 'prx_' + 'b'.repeat(64) })), porte)).json()
    assertEquals(r.error?.code, -32602)
    // Seule la note de refus part, avec la cle de l'en-tete (jamais celle de l'appelant).
    assertEquals(appels, [{ fonction: 'praxis_noter_refus', params: { p_outil: 'etat', p_cle: CLE } }])
  }
  // (c) Meme si un parametre futur s'appelait p_cle, la cle de l'en-tete l'emporte (ordre : parametres, puis cle).
  const piege = {
    nom: 'piege', description: 'test', fonction: 'praxis_piege',
    parametres: [{ arg: 'x', param: 'p_cle', requis: true }],
    proprietes: { x: { type: 'string' as const, description: 'x', minLength: 1, maxLength: 80 } },
  }
  // La liste est en lecture seule dans le code ; le test la force pour simuler un futur parametre piege.
  const liste = OUTILS as unknown as unknown[]
  liste.push(piege)
  try {
    const { porte, appels } = faux()
    await traiter(requete(appelOutil('piege', { x: 'prx_' + 'c'.repeat(64) })), porte)
    assertEquals(appels.length, 1)
    assertEquals(appels[0].params.p_cle, CLE)
  } finally {
    liste.pop()
  }
})

Deno.test('AR-7 M1 : une propriete heritee (constructor, __proto__, toString) est refusee, pas acceptee', async () => {
  for (const cle of ['constructor', 'toString', 'hasOwnProperty', '__proto__']) {
    const { porte } = faux()
    const corps = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"etat","arguments":{"' + cle + '":1}}}'
    const r = await (await traiter(requete(corps), porte)).json()
    assertEquals(r.error?.code, -32602, `${cle} doit etre refusee`)
  }
})

Deno.test('AR-7 M2 : un corps trop grand sans content-length ni taille annoncee est coupe, la base non appelee', async () => {
  const { porte, appels } = faux()
  const flux = new ReadableStream<Uint8Array>({
    start(c) {
      const bloc = new TextEncoder().encode('x'.repeat(4096))
      for (let i = 0; i < 10; i++) c.enqueue(bloc)
      c.close()
    },
  })
  const req = new Request('https://exemple.test/praxis-mcp', {
    method: 'POST', body: flux, headers: { Authorization: `Bearer ${CLE}` },
    // deno-lint-ignore no-explicit-any
    ...({ duplex: 'half' } as any),
  })
  const r = await traiter(req, porte)
  assertEquals(r.status, 413)
  assertEquals(appels.length, 0)
})

Deno.test('AR-7 M4 : un refus de parametre appelle praxis_noter_refus avec la cle et le nom de l\'outil, rien d\'autre', async () => {
  const { porte, appels } = faux()
  await traiter(requete(appelOutil('ecrire', { fil: 'pas-un-uuid', texte: 'secret', cle_idempotence: UUID2 })), porte)
  assertEquals(appels, [{ fonction: 'praxis_noter_refus', params: { p_outil: 'ecrire', p_cle: CLE } }])
})

Deno.test('AR-7 M4 : une base en panne pendant la note de refus ne change pas la reponse', async () => {
  const porte: PortePraxis = { appeler: () => Promise.reject(new Error('base')) }
  const r = await (await traiter(requete(appelOutil('boite', { limite: 99 })), porte)).json()
  assertEquals(r.error?.code, -32602)
})

// ============ PX-BD-0 : les actes du mode chat ============

Deno.test('PX-BD-0 : actes, agir, acte_preparer, acte_confirmer composent des appels types, la cle en premier', async () => {
  const cas: Array<[string, Record<string, unknown>, string, Record<string, unknown>]> = [
    ['actes', {}, 'praxis_actes', { p_cle: CLE }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { nom: 'Document', rayon: 'cours', classes: ['a', 'b'], epingler: true, revision: 3 }, cle_idempotence: UUID1 },
      'praxis_agir', { p_cle: CLE, p_acte: 'bibliotheque_configurer', p_params: { nom: 'Document', rayon: 'cours', classes: ['a', 'b'], epingler: true, revision: 3 }, p_cle_idempotence: UUID1 }],
    ['acte_preparer', { acte: 'relance_candidat', lot: [{ reference: 'CAND-1' }, { reference: 'CAND-2', motif: 'x' }] },
      'praxis_acte_preparer', { p_cle: CLE, p_acte: 'relance_candidat', p_lot: [{ reference: 'CAND-1' }, { reference: 'CAND-2', motif: 'x' }] }],
    ['acte_confirmer', { jeton: UUID2, code: '012345' }, 'praxis_acte_confirmer', { p_cle: CLE, p_jeton: UUID2, p_code: '012345' }],
  ]
  for (const [outil, args, fonction, params] of cas) {
    const { porte, appels } = faux({ ok: true })
    await traiter(requete(appelOutil(outil, args)), porte)
    assertEquals(appels, [{ fonction, params }], outil)
  }
})

Deno.test('PX-BD-0 : tout ce qui sort du schema des actes est refuse AVANT la base', async () => {
  const mauvais: Array<[string, unknown]> = [
    ['agir', { acte: 'Majuscule', parametres: {}, cle_idempotence: UUID1 }],
    ['agir', { acte: 'a', parametres: {}, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: [], cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: 'texte', cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { Nom: 'x' }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { 'a b': 'x' }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { o: { imbrique: 1 } }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { n: null }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { n: 1.5 }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { t: 'x'.repeat(1001) }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { t: 'a\u0000b' }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: { l: [1] }, cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: Object.fromEntries(Array.from({ length: 21 }, (_, i) => [`k${i}`, 'x'])), cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: Object.fromEntries(Array.from({ length: 5 }, (_, i) => [`k${i}`, 'x'.repeat(900)])), cle_idempotence: UUID1 }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: {} }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: {}, cle_idempotence: 'pas-un-uuid' }],
    ['agir', { acte: 'bibliotheque_configurer', parametres: {}, cle_idempotence: UUID1, p_cle: CLE }],
    ['acte_preparer', { acte: 'relance_candidat', lot: [] }],
    ['acte_preparer', { acte: 'relance_candidat', lot: Array.from({ length: 51 }, () => ({})) }],
    ['acte_preparer', { acte: 'relance_candidat', lot: [{}, 'texte'] }],
    ['acte_preparer', { acte: 'relance_candidat', lot: [{ o: { x: 1 } }] }],
    ['acte_preparer', { acte: 'relance_candidat', lot: { reference: 'CAND-1' } }],
    ['acte_preparer', { acte: 'relance_candidat' }],
    ['acte_confirmer', { jeton: UUID2, code: '12345' }],
    ['acte_confirmer', { jeton: UUID2, code: '1234567' }],
    ['acte_confirmer', { jeton: UUID2, code: '12a456' }],
    ['acte_confirmer', { jeton: 'pas-un-uuid', code: '123456' }],
    ['acte_confirmer', { jeton: UUID2 }],
    ['acte_confirmer', { jeton: UUID2, code: '123456', force: true }],
    ['actes', { quoi: 'que ce soit' }],
  ]
  for (const [nom, args] of mauvais) {
    const { porte, appels } = faux()
    const r = await (await traiter(requete(appelOutil(nom, args)), porte)).json()
    assertEquals(r.error?.code, -32602, `${nom} ${JSON.stringify(args).slice(0, 80)} aurait du etre refuse`)
    assert(appels.every((a) => a.fonction === 'praxis_noter_refus'), `${nom} : la base ne doit recevoir que la note de refus`)
  }
})

Deno.test('PX-BD-0 : un lot de cinquante lignes est accepte, et le schema MCP des actes est decrit', async () => {
  const { porte, appels } = faux({ ok: true })
  await traiter(requete(appelOutil('acte_preparer', { acte: 'relance_candidat', lot: Array.from({ length: 50 }, (_, i) => ({ reference: `CAND-${i}` })) })), porte)
  assertEquals(appels.length, 1)
  assertEquals((appels[0].params.p_lot as unknown[]).length, 50)
  const r = await (await traiter(requete({ jsonrpc: '2.0', id: 1, method: 'tools/list' }), faux().porte)).json()
  const outils = r.result.tools as Array<{ name: string; inputSchema: { properties: Record<string, { type: string }>; required: string[] } }>
  const agir = outils.find((o) => o.name === 'agir')!
  assertEquals(agir.inputSchema.properties.parametres.type, 'object')
  assertEquals(agir.inputSchema.required.sort(), ['acte', 'cle_idempotence', 'parametres'])
  assertEquals(outils.find((o) => o.name === 'acte_preparer')!.inputSchema.properties.lot.type, 'array')
})

Deno.test('PX-BD-0 : aucun outil des actes ne rend ni ne prend le code autrement que par acte_confirmer', () => {
  for (const o of OUTILS) {
    const prendUnCode = o.parametres.some((d) => d.arg === 'code')
    assertEquals(prendUnCode, o.nom === 'acte_confirmer', o.nom)
  }
})
