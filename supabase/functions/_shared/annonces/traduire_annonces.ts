// ANNONCES-SERVEUR (directeur, 21/11/2026, DECISION-ANNONCES-NOTIFS-2026-11-21.md, regle 6) : chaque annonce
// generale est traduite au serveur, a l'envoi, dans les langues de l'application (fr, en, ar).
//
// Le declencheur de la migration 20261130976000 met l'annonce en file des son insertion ; cette fonction,
// appelee par `courriels-envoi` a chaque passage de la tache unique (une fois par minute), reserve les
// annonces en attente, detecte la langue d'ecriture, traduit titre et texte vers les autres langues par
// Google (`GOOGLE_TRADUCTION_CLE`, memes protections que les courriels : la marque, et l'arabe d'un texte
// qui n'est ni ecrit ni traduit en arabe), puis consigne. Une langue qui echoue est rejouee plus tard par
// le serveur ; le lecteur recoit l'original en attendant, jamais un vide.

import { type Detecteur, detecteurGoogle, type Traducteur, traducteurGoogle } from '../courriel/traduction.ts'

/// Une annonce reservee par `com_annonce_traductions_reserver`.
export interface AnnonceAtraduire {
  annonce_id: string
  titre: string
  texte: string
  langues: string[]
  langue_source: string | null
}

/// Le strict necessaire du client Supabase (cle de service).
export interface ClientRpc {
  rpc(fonction: string, args: Record<string, unknown>): PromiseLike<{ data: unknown; error: { message: string } | null }>
}

export interface Bilan {
  traduites: number
  echecs: number
}

export interface Options {
  traduire?: Traducteur
  detecter?: Detecteur
  lot?: number
  budgetMs?: number
  maintenant?: () => number
}

const message = (e: unknown) => String((e as Error)?.message ?? e).slice(0, 300)

/// Traduit une annonce. Rend la langue source (ou null), les traductions obtenues et la premiere erreur.
export async function traduireUne(
  a: AnnonceAtraduire, traduire: Traducteur, detecter: Detecteur,
): Promise<{ source: string | null; traductions: Record<string, { titre: string; texte: string }>; erreur: string | null }> {
  const traductions: Record<string, { titre: string; texte: string }> = {}
  let source: string | null = a.langue_source
  try {
    if (!source) source = (await detecter(`${a.titre}\n${a.texte}`)).toLowerCase().split('-')[0]
  } catch (e) {
    return { source: null, traductions, erreur: message(e) }
  }
  let erreur: string | null = null
  for (const cible of a.langues) {
    if (cible === source) continue
    try {
      const [titre, texte] = await traduire([a.titre, a.texte], source, cible)
      if (!texte || texte.trim() === '') throw new Error('traduction vide')
      traductions[cible] = { titre: titre ?? '', texte }
    } catch (e) {
      erreur ??= message(e)
    }
  }
  return { source, traductions, erreur }
}

/// Vide la file des annonces a traduire, par lots, sans depasser le budget de temps.
export async function traduireAnnonces(db: ClientRpc, options: Options = {}): Promise<Bilan> {
  const traduire = options.traduire ?? traducteurGoogle
  const detecter = options.detecter ?? detecteurGoogle
  const maintenant = options.maintenant ?? Date.now
  const debut = maintenant()
  const budget = options.budgetMs ?? 10_000
  const bilan: Bilan = { traduites: 0, echecs: 0 }

  while (maintenant() - debut < budget) {
    const { data, error } = await db.rpc('com_annonce_traductions_reserver', { p_lot: options.lot ?? 5 })
    if (error) throw new Error(`reserver les annonces : ${error.message}`)
    const lot = (Array.isArray(data) ? data : []) as AnnonceAtraduire[]
    if (lot.length === 0) break
    for (const a of lot) {
      const r = await traduireUne(a, traduire, detecter)
      r.erreur ? bilan.echecs++ : bilan.traduites++
      const { error: e2 } = await db.rpc('com_annonce_traduction_consigner', {
        p_annonce_id: a.annonce_id, p_langue_source: r.source, p_traductions: r.traductions, p_erreur: r.erreur,
      })
      if (e2) console.error(`consigner l'annonce ${a.annonce_id} : ${e2.message}`)
    }
  }
  return bilan
}
