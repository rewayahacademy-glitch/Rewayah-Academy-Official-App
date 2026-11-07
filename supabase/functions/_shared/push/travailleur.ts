// PUSH-1 : le travailleur qui vide la file des push. Meme porte que
// courriels-envoi (secret partage `COURRIELS_ENVOI_SECRET`, en-tete
// `x-courriels-secret`, compare en temps constant), memes lots de 20 pendant
// 40 s au plus. Ses dependances (environnement, base, fetch, horloge) sont
// injectees : `push-envoi/index.ts` ne fait que les brancher.

import { json, refus } from '../clients.ts'
import { texteDuPush } from './textes.ts'
import { type Abonnement, envoyerPush, type Fetch, lireVapid, type Vapid } from './web_push.ts'

/// Comparaison en temps constant (reprise de courriels-envoi).
export function egal(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a)
  const y = new TextEncoder().encode(b)
  let d = x.length ^ y.length
  for (let i = 0; i < Math.max(x.length, y.length); i++) d |= (x[i] ?? 0) ^ (y[i] ?? 0)
  return d === 0
}

/// Une ligne rendue par `push_reserver`.
export interface LignePush {
  id: string
  evenement: string
  portee: string | null
  langue: string | null
  nombre: number
  tag: string | null
  destination: string
  abonnements: Abonnement[]
}

export interface Resultat {
  ok: boolean
  erreur: string | null
  morts: string[]
}

/// La charge utile en clair : { titre, texte, destination, tag }.
export function chargeUtile(l: LignePush): Uint8Array {
  const { titre, texte } = texteDuPush(l.evenement, l.portee, l.langue, l.nombre ?? 1, l.tag)
  return new TextEncoder().encode(JSON.stringify({ titre, texte, destination: l.destination, tag: l.tag ?? null }))
}

/// Envoie une ligne a tous ses abonnements. ok : au moins un 2xx ; morts : les
/// 404 et 410 ; l'erreur, courte et sans donnee personnelle, quand rien n'est
/// passe.
export async function traiterLigne(
  l: LignePush, vapid: Vapid, options: { fetch?: Fetch; maintenantMs?: number } = {},
): Promise<Resultat> {
  const abonnements = Array.isArray(l.abonnements) ? l.abonnements : []
  if (abonnements.length === 0) return { ok: false, erreur: 'aucun abonnement', morts: [] }
  const clair = chargeUtile(l)
  let ok = false
  const morts: string[] = []
  const erreurs = new Set<string>()
  for (const a of abonnements) {
    const r = await envoyerPush(a, clair, vapid, { tag: l.tag, fetch: options.fetch, maintenantMs: options.maintenantMs })
    if (r.etat === 'ok') ok = true
    else if (r.etat === 'mort') {
      morts.push(a.id)
      erreurs.add(`abonnement retire (${r.statut})`)
    } else erreurs.add(r.erreur)
  }
  return { ok, erreur: ok ? null : [...erreurs].join('; ').slice(0, 200), morts }
}

export interface Base {
  rpc(nom: string, args: Record<string, unknown>): PromiseLike<{ data: unknown; error: { message: string } | null }>
}

export interface Dependances {
  env: (nom: string) => string | undefined
  base: () => Base
  fetch?: Fetch
  maintenant?: () => number
  lot?: number
  dureeMs?: number
}

export function creerTravailleur(dep: Dependances): (req: Request) => Promise<Response> {
  const maintenant = dep.maintenant ?? (() => Date.now())
  return async (req) => {
    if (req.method !== 'POST') return refus('methode', 405)
    const secret = dep.env('COURRIELS_ENVOI_SECRET')
    if (!secret || !egal(req.headers.get('x-courriels-secret') ?? '', secret)) return refus('acces refuse', 401)

    // Les secrets VAPID avant toute reservation : sans eux, rien n'est consomme.
    let vapid: Vapid | null
    try {
      vapid = lireVapid(dep.env)
    } catch {
      return refus('vapid invalide', 500)
    }
    if (!vapid) return refus('vapid absent', 500)

    const db = dep.base()
    const debut = maintenant()
    let envoyes = 0
    let echecs = 0
    let retires = 0

    while (maintenant() - debut < (dep.dureeMs ?? 40_000)) {
      const { data, error } = await db.rpc('push_reserver', { p_lot: dep.lot ?? 20 })
      if (error) return refus(`reserver : ${error.message}`, 500)
      const lot = (data ?? []) as LignePush[]
      if (lot.length === 0) break

      for (const l of lot) {
        let r: Resultat
        try {
          r = await traiterLigne(l, vapid, { fetch: dep.fetch, maintenantMs: maintenant() })
        } catch (e) {
          r = { ok: false, erreur: String((e as Error).message ?? e).slice(0, 200), morts: [] }
        }
        r.ok ? envoyes++ : echecs++
        retires += r.morts.length
        const { error: e2 } = await db.rpc('push_consigner', {
          p_id: l.id, p_ok: r.ok, p_erreur: r.erreur, p_abonnements_morts: r.morts,
        })
        if (e2) console.error(`consigner ${l.id} : ${e2.message}`)
      }
    }
    return json({ envoyes, echecs, abonnements_retires: retires })
  }
}
