// Lot O1 (02/11/2026) : la coupure serveur des visites d'observation.
//
// Logique pure de la fonction `observation-coupure`, testee sans reseau
// (`coupure_observation_test.ts`) : la porte (secret partage du cron) et la
// lecture de ce que rend `couper_visites_observation_echues()`.
//
// **Rien n'est decide ici.** La base a deja clos chaque visite echue selon la
// politique (`politique_observation_effective`) ; ce module dit seulement qui
// faire sortir de quelle salle LiveKit.

import type { Fournisseur, RouteGeste } from './livekit.ts'

/// Compare deux chaines en temps constant (comme `courriels-envoi`).
export function egal(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a)
  const y = new TextEncoder().encode(b)
  let d = x.length ^ y.length
  for (let i = 0; i < Math.max(x.length, y.length); i++) d |= (x[i] ?? 0) ^ (y[i] ?? 0)
  return d === 0
}

/// Vrai seulement si le secret attendu existe et que l'en-tete le porte.
/// Un secret absent cote fonction ferme tout : jamais d'ouverture par defaut.
export function porteOuverte(entete: string | null, attendu: string | undefined): boolean {
  if (!attendu) return false
  return egal(entete ?? '', attendu)
}

/// Vrai quand LiveKit dit que le participant n'est plus la (deja sorti, salle
/// fermee) : une sortie sans objet, pas un echec. LiveKit le dit de deux
/// facons ; `appliquerGeste` ne reconnait que « not found », et le banc local
/// (O1, 02/11) a montre « participant does not exist ».
export function estAbsent(message: string): boolean {
  return /not found|does not exist/i.test(message)
}

/// Une sortie a faire : la route LiveKit du participant a ejecter.
export interface SortieObservation extends RouteGeste {
  visite_id: string
}

function estFournisseur(v: unknown): v is Fournisseur {
  return v === 'cloud' || v === 'self_hosted'
}

/// Lit le tableau rendu par la base. Une ligne incomplete est ecartee, jamais
/// devinee : mieux vaut ne faire sortir personne que la mauvaise personne.
export function lireSorties(donnees: unknown): SortieObservation[] {
  if (!Array.isArray(donnees)) return []
  const sorties: SortieObservation[] = []
  for (const l of donnees) {
    if (typeof l !== 'object' || l === null) continue
    const r = l as Record<string, unknown>
    if (
      typeof r.visite_id === 'string' && r.visite_id !== '' &&
      estFournisseur(r.provider) &&
      typeof r.ws_url === 'string' && r.ws_url !== '' &&
      typeof r.room_name === 'string' && r.room_name !== '' &&
      typeof r.identity === 'string' && r.identity !== ''
    ) {
      sorties.push({
        visite_id: r.visite_id,
        provider: r.provider,
        ws_url: r.ws_url,
        room_name: r.room_name,
        identity: r.identity,
      })
    }
  }
  return sorties
}
