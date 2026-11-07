// PUSH-1 : chiffrement (RFC 8291, vecteur de l'annexe A compris), VAPID
// (RFC 8292), envoi avec un fetch simule, textes et porte du travailleur.
// Aucun appel reseau.

import { assert, assertEquals, assertMatch, assertNotEquals } from 'jsr:@std/assert@1'
import {
  autorisationVapid,
  chiffrer,
  clePubliqueBrute,
  dechiffrer,
  depuisBase64Url,
  envoyerPush,
  type Fetch,
  hoteAutorise,
  jwkP256,
  topicDe,
  type Vapid,
  versBase64Url,
} from './web_push.ts'
import { GENERIQUE, nombreAr, TEXTES, texteDuPush } from './textes.ts'
import { chargeUtile, creerTravailleur, type LignePush, traiterLigne } from './travailleur.ts'
import { repondreCle } from './cle.ts'

const td = new TextDecoder()
const te = new TextEncoder()

async function paireEcdh() {
  const p = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']) as CryptoKeyPair
  return { prive: p.privateKey, publique: await clePubliqueBrute(p.publicKey) }
}

async function vapidDeTest(): Promise<Vapid> {
  const p = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']) as CryptoKeyPair
  const jwk = await crypto.subtle.exportKey('jwk', p.privateKey)
  return {
    publique: await clePubliqueBrute(p.publicKey),
    prive: depuisBase64Url(jwk.d!),
    sujet: 'mailto:direction@example.org',
  }
}

async function abonne() {
  const ua = await paireEcdh()
  const auth = crypto.getRandomValues(new Uint8Array(16))
  return { ua, auth, p256dh: versBase64Url(ua.publique), authB64: versBase64Url(auth) }
}

// ---------------------------------------------------------------------------
// VAPID

Deno.test('VAPID : JWT ES256 signe, verifie par Web Crypto, aud/exp/sub justes', async () => {
  const vapid = await vapidDeTest()
  const maintenant = Date.UTC(2026, 10, 7, 12, 0, 0)
  const entete = await autorisationVapid(vapid, 'https://fcm.googleapis.com/fcm/send/abc?x=1', maintenant)
  const m = entete.match(/^vapid t=([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+), k=([A-Za-z0-9_-]+)$/)
  assert(m, 'format de l en-tete Authorization')
  const [jwt, k] = [m[1], m[2]]
  assertEquals(k, versBase64Url(vapid.publique))

  const [h, c, s] = jwt.split('.')
  assertEquals(JSON.parse(td.decode(depuisBase64Url(h))), { typ: 'JWT', alg: 'ES256' })
  const charge = JSON.parse(td.decode(depuisBase64Url(c)))
  assertEquals(charge.aud, 'https://fcm.googleapis.com')
  assertEquals(charge.exp, maintenant / 1000 + 12 * 3600)
  assertEquals(charge.sub, 'mailto:direction@example.org')

  const signature = depuisBase64Url(s)
  assertEquals(signature.length, 64, 'signature brute r||s')
  const pub = await crypto.subtle.importKey('jwk', jwkP256(vapid.publique), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['verify'])
  assert(await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, pub, signature, te.encode(`${h}.${c}`)))
  // Une charge alteree ne verifie plus.
  assert(!(await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, pub, signature, te.encode(`${h}.${c}x`))))
})

// ---------------------------------------------------------------------------
// Chiffrement

Deno.test('chiffrement aes128gcm : l abonne dechiffre et retrouve le texte clair', async () => {
  const a = await abonne()
  const clair = te.encode(JSON.stringify({ titre: 'Rewayah Academy', texte: 'Un signalement attend votre décision dans l\'application.', destination: '/admin', tag: null }))
  const corps = await chiffrer(clair, a.p256dh, a.authB64)
  // En-tete : sel 16, rs 4096, idlen 65, keyid 65.
  assertEquals(new DataView(corps.buffer, corps.byteOffset + 16, 4).getUint32(0), 4096)
  assertEquals(corps[20], 65)
  assertEquals(corps[21], 0x04)
  assertEquals(corps.length, 16 + 4 + 1 + 65 + clair.length + 1 + 16)
  assertEquals(td.decode(await dechiffrer(corps, a.ua.prive, a.ua.publique, a.auth)), td.decode(clair))
  // Deux envois du meme message ne se ressemblent pas (sel et cle ephemere).
  assertNotEquals(versBase64Url(await chiffrer(clair, a.p256dh, a.authB64)), versBase64Url(corps))
})

Deno.test('chiffrement : vecteur de l annexe A de RFC 8291', async () => {
  const asPublique = depuisBase64Url('BP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A8')
  const asPrive = depuisBase64Url('yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw')
  const uaPublique = depuisBase64Url('BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4')
  const uaPrive = depuisBase64Url('q1dXpw3UpT5VOmu_cf_v6ih07Aems3njxI-JWgLcM94')
  const sel = depuisBase64Url('DGv6ra1nlYgDCS1FRnbzlw')
  const auth = 'BTBZMqHH6r4Tts7J_aSIgg'
  const attendu = 'DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN'

  const prive = await crypto.subtle.importKey('jwk', jwkP256(asPublique, asPrive), { name: 'ECDH', namedCurve: 'P-256' }, false, ['deriveBits'])
  const corps = await chiffrer(te.encode('When I grow up, I want to be a watermelon'), versBase64Url(uaPublique), auth, {
    sel, ephemere: { prive, publique: asPublique },
  })
  assertEquals(versBase64Url(corps), attendu)

  const uaCle = await crypto.subtle.importKey('jwk', jwkP256(uaPublique, uaPrive), { name: 'ECDH', namedCurve: 'P-256' }, false, ['deriveBits'])
  assertEquals(td.decode(await dechiffrer(depuisBase64Url(attendu), uaCle, uaPublique, depuisBase64Url(auth))), 'When I grow up, I want to be a watermelon')
})

Deno.test('Topic : etiquette courte gardee, longue ou hors alphabet hachee en 32 caracteres', async () => {
  assertEquals(await topicDe('candidatures'), 'candidatures')
  assertEquals(await topicDe(null), null)
  const long = await topicDe('une etiquette beaucoup trop longue pour un Topic')
  assertEquals(long!.length, 32)
  assertMatch(long!, /^[A-Za-z0-9_-]{32}$/)
  assertEquals(await topicDe('une etiquette beaucoup trop longue pour un Topic'), long)
})

// ---------------------------------------------------------------------------
// Envoi avec un fetch simule

function fetchSimule(statut: number | 'reseau', vus: { url: string; init: RequestInit }[] = []): Fetch {
  return (url, init) => {
    vus.push({ url, init })
    if (statut === 'reseau') return Promise.reject(new TypeError('connexion refusee'))
    return Promise.resolve(new Response(statut === 201 ? null : 'corps de reponse', { status: statut }))
  }
}

Deno.test('envoi : 201 ok, 404 et 410 mort, 500 et reseau en echec non mort', async () => {
  const vapid = await vapidDeTest()
  const a = await abonne()
  const ab = { id: 'a1', endpoint: 'https://fcm.googleapis.com/fcm/send/x', p256dh: a.p256dh, auth: a.authB64 }
  const clair = te.encode('{}')

  const vus: { url: string; init: RequestInit }[] = []
  assertEquals(await envoyerPush(ab, clair, vapid, { fetch: fetchSimule(201, vus), tag: 'candidatures' }), { etat: 'ok' })
  const h = vus[0].init.headers as Record<string, string>
  assertEquals(vus[0].url, ab.endpoint)
  assertEquals(vus[0].init.method, 'POST')
  assertEquals(h['Content-Encoding'], 'aes128gcm')
  assertEquals(h['TTL'], '86400')
  assertEquals(h['Urgency'], 'high')
  assertEquals(h['Topic'], 'candidatures')
  assertMatch(h['Authorization'], /^vapid t=.+, k=.+$/)

  assertEquals(await envoyerPush(ab, clair, vapid, { fetch: fetchSimule(404) }), { etat: 'mort', statut: 404 })
  assertEquals(await envoyerPush(ab, clair, vapid, { fetch: fetchSimule(410) }), { etat: 'mort', statut: 410 })
  assertEquals(await envoyerPush(ab, clair, vapid, { fetch: fetchSimule(500) }), { etat: 'echec', erreur: 'http 500' })
  assertEquals(await envoyerPush(ab, clair, vapid, { fetch: fetchSimule('reseau') }), { etat: 'echec', erreur: 'reseau' })

  const sansTopic: { url: string; init: RequestInit }[] = []
  await envoyerPush(ab, clair, vapid, { fetch: fetchSimule(201, sansTopic) })
  assertEquals((sansTopic[0].init.headers as Record<string, string>)['Topic'], undefined)
})

function ligne(abonnements: LignePush['abonnements'], extra: Partial<LignePush> = {}): LignePush {
  return {
    id: 'n1', evenement: 'signalement_eleve_recu', portee: 'direction', langue: 'fr', nombre: 1,
    tag: null, destination: '/admin/signalements', abonnements, ...extra,
  }
}

Deno.test('ligne : ok si un abonnement recoit, morts listes, erreur courte sinon', async () => {
  const vapid = await vapidDeTest()
  const a = await abonne()
  const ab = (id: string, hote: string) => ({ id, endpoint: `https://${hote}/p`, p256dh: a.p256dh, auth: a.authB64 })
  const parHote: Fetch = (url) => {
    const s = url.includes('ok.') ? 201 : url.includes('parti.') ? 410 : 503
    return Promise.resolve(new Response(null, { status: s }))
  }
  const r1 = await traiterLigne(ligne([ab('x', 'ok.notify.windows.com'), ab('y', 'parti.notify.windows.com'), ab('z', 'panne.notify.windows.com')]), vapid, { fetch: parHote })
  assertEquals(r1, { ok: true, erreur: null, morts: ['y'] })

  const r2 = await traiterLigne(ligne([ab('y', 'parti.notify.windows.com'), ab('z', 'panne.notify.windows.com')]), vapid, { fetch: parHote })
  assertEquals(r2.ok, false)
  assertEquals(r2.morts, ['y'])
  assert(r2.erreur!.includes('http 503'))
  assert(!r2.erreur!.includes('panne.notify.windows.com'), 'aucun endpoint dans l erreur')

  assertEquals(await traiterLigne(ligne([]), vapid, { fetch: parHote }), { ok: false, erreur: 'aucun abonnement', morts: [] })
})

Deno.test('charge utile : titre, texte, destination, tag', () => {
  const c = JSON.parse(td.decode(chargeUtile(ligne([], { evenement: 'admission_recue', nombre: 3, tag: 'candidatures', destination: '/admin/personnes/candidatures' }))))
  assertEquals(c, { titre: 'Rewayah Academy', texte: '3 nouvelles candidatures à examiner.', destination: '/admin/personnes/candidatures', tag: 'candidatures' })
})

// ---------------------------------------------------------------------------
// Textes

const NOUVEAUX = [
  'admission_recue', 'candidature_enseignant_a_examiner', 'demande_horaire_recue', 'creneau_personnalise_demande',
  'piece_identite_deposee', 'signalement_eleve_recu', 'suppression_compte_demandee', 'remplacement_personne_en_salle',
  'paiement_echoue', 'versement_coordonnees_a_valider', 'versement_coordonnees_validees', 'remboursement_demande',
  'remboursement_echec', 'cahier_en_retard',
]
const EVENEMENTS = [
  'seance_annulee', 'seance_deplacee', 'enseignante_absente', 'remplacement_propose', 'remplacement_pris',
  'remplacement_designe_admin', 'remplacement_pre_alerte', 'remplacement_avertissement', 'remplacement_inutile',
  'creneau_change', 'titulaire_en_retard', 'seance_reportee', 'classe_validee', 'classe_creee', 'classe_changee',
  'classe_supprimee', 'enseignant_affecte', 'enseignant_change', 'eleve_inscrit', 'eleve_retire', 'demande_recue',
  'demande_close', 'demande_presentation', 'controle_mission_attribuee', 'controle_mission_non_controlee',
  'paiement_relance', 'acces_suspendu_paiement', 'acces_retabli_paiement', 'paiement_recu', 'remboursement_effectue',
  'litige_ouvert', 'litige_clos', 'message_academie_eleve', ...NOUVEAUX,
]
const PORTEES = ['direction', 'comptable', 'soi', 'foyer', 'classe', null]
const EMOJI = /\p{Extended_Pictographic}/u

function tousLesTextes(): { cle: string; titre: string; texte: string }[] {
  const r: { cle: string; titre: string; texte: string }[] = []
  for (const e of [...EVENEMENTS, 'inconnu']) {
    for (const p of PORTEES) {
      for (const l of ['fr', 'ar']) {
        for (const n of [1, 2, 3, 11, 100]) {
          const t = texteDuPush(e, p, l, n, n > 1 ? 'tag' : null)
          r.push({ cle: `${e}/${p}/${l}/${n}`, ...t })
        }
      }
    }
  }
  return r
}

Deno.test('textes : aucun mot interdit, aucun tiret long, aucun emoji, aucun code, longueurs tenues', () => {
  for (const { cle, titre, texte } of tousLesTextes()) {
    for (const s of [titre, texte]) {
      assert(!/groupe|admin|enseignante|mode enfant|échec/i.test(s), `${cle} : mot interdit dans « ${s} »`)
      assert(!/[—–]/.test(s), `${cle} : tiret long`)
      assert(!EMOJI.test(s), `${cle} : emoji`)
      assert(!/_/.test(s), `${cle} : code interne`)
      assert(!/[$€]|\d+[.,]\d\d/.test(s), `${cle} : montant`)
    }
    assert(titre.length <= 40, `${cle} : titre trop long`)
    assert(texte.length <= 120, `${cle} : texte trop long (${texte.length}) « ${texte} »`)
  }
})

Deno.test('textes : chaque evenement a son texte, non generique, en FR et en AR', () => {
  for (const e of EVENEMENTS) {
    assert(TEXTES[e], `${e} sans texte`)
    for (const p of PORTEES) {
      assertNotEquals(texteDuPush(e, p, 'fr', 1).texte, GENERIQUE.fr, e)
      assertNotEquals(texteDuPush(e, p, 'ar', 1).texte, GENERIQUE.ar, e)
    }
  }
  assertEquals(texteDuPush('evenement_inconnu', null, 'fr', 1).texte, 'Une nouvelle notification vous attend dans l\'application.')
  // Toute langue autre que l'arabe : francais.
  assertEquals(texteDuPush('seance_annulee', null, 'es', 1), texteDuPush('seance_annulee', null, 'fr', 1))
  assertEquals(texteDuPush('seance_annulee', null, 'ar', 1).titre, 'Rewayah Academy')
})

Deno.test('textes imposes : signalement, paiement echoue selon la portee', () => {
  assertEquals(texteDuPush('signalement_eleve_recu', 'direction', 'fr', 1).texte, 'Un signalement attend votre décision dans l\'application.')
  assert(texteDuPush('paiement_echoue', 'direction', 'fr', 1).texte.startsWith('Un paiement a échoué'))
  assert(texteDuPush('paiement_echoue', 'comptable', 'fr', 1).texte.startsWith('Un paiement a échoué'))
  const soi = texteDuPush('paiement_echoue', 'soi', 'fr', 1).texte
  assert(soi.startsWith('Votre paiement n\'a pas abouti') && soi.includes('Recharger'))
  assert(texteDuPush('enseignante_absente', 'foyer', 'fr', 1).texte.includes('enseignant est absent'))
})

Deno.test('regroupement : le nombre apparait, accord arabe 2 / 3-10 / 11-99 / 100', () => {
  assertEquals(texteDuPush('admission_recue', 'direction', 'fr', 3, 'candidatures').texte, '3 nouvelles candidatures à examiner.')
  assertEquals(texteDuPush('candidature_enseignant_a_examiner', 'direction', 'fr', 12, 'candidatures').texte, '12 nouvelles candidatures à examiner.')
  assertEquals(texteDuPush('admission_recue', 'direction', 'ar', 2, 'candidatures').texte, 'طلبان جديدان بانتظار الدراسة.')
  assertEquals(texteDuPush('admission_recue', 'direction', 'ar', 3, 'candidatures').texte, '3 طلبات جديدة بانتظار الدراسة.')
  assertEquals(texteDuPush('admission_recue', 'direction', 'ar', 11, 'candidatures').texte, '11 طلبًا جديدًا بانتظار الدراسة.')
  assertEquals(texteDuPush('admission_recue', 'direction', 'ar', 100, 'candidatures').texte, '100 طلب جديد بانتظار الدراسة.')
  assertEquals(texteDuPush('piece_identite_deposee', 'direction', 'fr', 4, 'pieces').texte, '4 pièces d\'identité à vérifier.')
  // Sans etiquette, pas de regroupement : le texte reste au singulier.
  assertEquals(texteDuPush('admission_recue', 'direction', 'fr', 3, null), texteDuPush('admission_recue', 'direction', 'fr', 1))
  // Un evenement sans pluriel propre prend le pluriel generique, avec le nombre.
  assert(texteDuPush('seance_annulee', 'foyer', 'fr', 5, 'seances').texte.startsWith('5 '))
  assertEquals(nombreAr(110, { deux: 'd', pluriel: () => 'p', accusatif: () => 'a', genitif: () => 'g' }), 'p')
  assertEquals(nombreAr(115, { deux: 'd', pluriel: () => 'p', accusatif: () => 'a', genitif: () => 'g' }), 'a')
})

// ---------------------------------------------------------------------------
// Porte du travailleur

function requete(secret?: string, methode = 'POST'): Request {
  const h = new Headers()
  if (secret !== undefined) h.set('x-courriels-secret', secret)
  return new Request('http://local/push-envoi', { method: methode, headers: h })
}

function baseEspion(lots: LignePush[][] = []) {
  const appels: { nom: string; args: Record<string, unknown> }[] = []
  return {
    appels,
    base: () => ({
      rpc(nom: string, args: Record<string, unknown>) {
        appels.push({ nom, args })
        if (nom === 'push_reserver') return Promise.resolve({ data: lots.shift() ?? [], error: null })
        return Promise.resolve({ data: null, error: null })
      },
    }),
  }
}

async function envVapid(): Promise<Record<string, string>> {
  const v = await vapidDeTest()
  return {
    COURRIELS_ENVOI_SECRET: 'secret-de-test',
    VAPID_PUBLIC_KEY: versBase64Url(v.publique),
    VAPID_PRIVATE_KEY: versBase64Url(v.prive),
    VAPID_SUBJECT: v.sujet,
  }
}

Deno.test('porte : sans secret, mauvais secret ou secret non configure : 401', async () => {
  const env = await envVapid()
  const espion = baseEspion()
  const t = creerTravailleur({ env: (n) => env[n], base: espion.base })
  assertEquals((await t(requete())).status, 401)
  assertEquals((await t(requete('mauvais'))).status, 401)
  assertEquals((await t(requete('secret-de-test', 'GET'))).status, 405)
  const sansSecret = creerTravailleur({ env: (n) => (n === 'COURRIELS_ENVOI_SECRET' ? undefined : env[n]), base: espion.base })
  assertEquals((await sansSecret(requete(''))).status, 401)
  assertEquals(espion.appels.length, 0)
})

Deno.test('porte : VAPID absent ou invalide : 500, rien n est reserve', async () => {
  const env = await envVapid()
  for (const manque of ['VAPID_PUBLIC_KEY', 'VAPID_PRIVATE_KEY', 'VAPID_SUBJECT']) {
    const espion = baseEspion()
    const t = creerTravailleur({ env: (n) => (n === manque ? undefined : env[n]), base: espion.base })
    const r = await t(requete('secret-de-test'))
    assertEquals(r.status, 500)
    assertEquals((await r.json()).error, 'vapid absent')
    assertEquals(espion.appels.length, 0)
  }
  const espion = baseEspion()
  const t = creerTravailleur({ env: (n) => (n === 'VAPID_PRIVATE_KEY' ? 'abc' : env[n]), base: espion.base })
  assertEquals((await t(requete('secret-de-test'))).status, 500)
  assertEquals(espion.appels.length, 0)
})

Deno.test('liste blanche : aucun envoi hors des services de push connus', async () => {
  const vapid = await vapidDeTest()
  const a = await abonne()
  for (const ok of [
    'https://fcm.googleapis.com/fcm/send/abc',
    'https://updates.push.services.mozilla.com/wpush/v2/abc',
    'https://web.push.apple.com/QGx',
    'https://wns2-par02p.notify.windows.com/w/?token=abc',
  ]) assert(hoteAutorise(ok), ok)
  for (const non of [
    'https://attaquant.example/collecte',
    'https://fcm.googleapis.com.attaquant.example/x',
    'https://notify.windows.com.attaquant.example/x',
    'http://fcm.googleapis.com/x',
    'https://fcm.googleapis.com:8443/x',
    'https://user@fcm.googleapis.com/x',
    'https://169.254.169.254/latest/meta-data',
    'pas une adresse',
  ]) assert(!hoteAutorise(non), non)

  let appels = 0
  const f: Fetch = () => {
    appels++
    return Promise.resolve(new Response(null, { status: 201 }))
  }
  const r = await envoyerPush(
    { id: 'x', endpoint: 'https://attaquant.example/collecte', p256dh: a.p256dh, auth: a.authB64 },
    new TextEncoder().encode('{}'), vapid, { fetch: f },
  )
  assertEquals(r, { etat: 'echec', erreur: 'hote refuse' })
  assertEquals(appels, 0, 'aucune requete vers un hote hors liste')
})

Deno.test('travailleur : reserve par lots de 20, envoie, consigne ok et morts', async () => {
  const env = await envVapid()
  const a = await abonne()
  const lots = [[
    ligne([{ id: 'vivant', endpoint: 'https://ok.notify.windows.com/p', p256dh: a.p256dh, auth: a.authB64 },
      { id: 'parti', endpoint: 'https://parti.notify.windows.com/p', p256dh: a.p256dh, auth: a.authB64 }]),
  ]]
  const espion = baseEspion(lots)
  const f: Fetch = (url) => Promise.resolve(new Response(null, { status: url.includes('ok.') ? 201 : 410 }))
  const t = creerTravailleur({ env: (n) => env[n], base: espion.base, fetch: f })
  const r = await t(requete('secret-de-test'))
  assertEquals(r.status, 200)
  assertEquals(await r.json(), { envoyes: 1, echecs: 0, abonnements_retires: 1 })
  assertEquals(espion.appels.map((x) => x.nom), ['push_reserver', 'push_consigner', 'push_reserver'])
  assertEquals(espion.appels[0].args, { p_lot: 20 })
  assertEquals(espion.appels[1].args, { p_id: 'n1', p_ok: true, p_erreur: null, p_abonnements_morts: ['parti'] })
})

// ---------------------------------------------------------------------------
// push-cle

Deno.test('push-cle : GET rend la cle, OPTIONS en CORS, sans cle 503, format faux 500', async () => {
  const env = await envVapid()
  const ok = repondreCle(new Request('http://local/push-cle'), (n) => env[n])
  assertEquals(ok.status, 200)
  assertEquals(await ok.json(), { cle: env.VAPID_PUBLIC_KEY })
  const corps = JSON.stringify(await repondreCle(new Request('http://local/push-cle'), (n) => env[n]).json())
  assert(!corps.includes(env.VAPID_PRIVATE_KEY), 'la cle privee ne sort jamais')
  for (const faux of [
    { ...env, VAPID_PUBLIC_KEY: 'BCle' },
    { ...env, VAPID_PRIVATE_KEY: 'AAAA' },
    { ...env, VAPID_SUBJECT: 'directeur@exemple' },
  ]) {
    const r = repondreCle(new Request('http://local/push-cle'), (n) => (faux as Record<string, string>)[n])
    assertEquals(r.status, 500)
    assertEquals(await r.json(), { error: 'vapid invalide' })
  }
  const moitie = repondreCle(new Request('http://local/push-cle'), (n) => (n === 'VAPID_PUBLIC_KEY' ? env[n] : undefined))
  assertEquals(moitie.status, 503)
  await moitie.body?.cancel()
  assertMatch(ok.headers.get('Access-Control-Allow-Methods')!, /GET/)
  const o = repondreCle(new Request('http://local/push-cle', { method: 'OPTIONS' }), () => undefined)
  assertEquals(o.status, 200)
  assertMatch(o.headers.get('Access-Control-Allow-Methods')!, /GET/)
  const sans = repondreCle(new Request('http://local/push-cle'), () => undefined)
  assertEquals(sans.status, 503)
  assertEquals(await sans.json(), { error: 'push indisponible' })
  assertEquals(repondreCle(new Request('http://local/push-cle', { method: 'POST' }), () => 'x').status, 405)
})
