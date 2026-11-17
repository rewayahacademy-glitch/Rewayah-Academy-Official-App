// PX-BD-SUPPORT, etage 2 : l'outil `support_deposer` de Praxis. Praxis REDIGE un support avec la direction dans le chat ; ce module le
// DEPOSE comme BROUILLON de la Bibliotheque (jamais publie : la direction le publie elle-meme).
//
// Trois temps, un seul appel du modele :
//   1. analyser le texte (sous-ensemble Markdown FERME, `markdown_ferme.ts`) : tout ce qui sort de la liste est refuse, avec un code ;
//   2. `depot_support_preparer` (acte A du pont de PX-BD-0, sous l'identite de la direction emettrice) : cree le brouillon et l'intention ;
//   3. ecrire l'objet dans le coffre R2 a la cle finale rendue par la base, puis `depot_support_confirmer` : la base reverifie la signature
//      HMAC que SEULE cette fonction Edge sait fabriquer (le modele ne peut donc pas confirmer un depot qu'il n'a pas fait).
// Le texte n'est JAMAIS repris tel quel : ce qui est ecrit est l'UTF-8 de ce que l'analyseur a accepte, mesure et empreint ici.
// Les ports (la base, le coffre, le secret) sont injectes : le module se teste sans reseau.

import { analyser, OCTETS_MAX } from './markdown_ferme.ts'

export type Json = null | boolean | number | string | Json[] | { [cle: string]: Json }

export const MIME_TEXTE = 'text/markdown'

export interface EntreeDepot {
  titre: string
  langue: string
  corps: string
  rayon?: string | null
  description?: string | null
  cle_idempotence: string
}

export interface PortDepot {
  /// Le stockage et le secret de confirmation sont-ils regles ? Verifie AVANT de creer quoi que ce soit.
  pret(): boolean
  /// `praxis_agir` : la reponse brute de la base (`{ok, resultat}` ou `{erreur, ...}`).
  agir(acte: string, params: Record<string, Json>, cleIdempotence: string): Promise<unknown>
  /// Ecrit l'objet a sa cle finale. Rejette si l'ecriture echoue.
  ecrire(cle: string, octets: Uint8Array): Promise<void>
  /// Le HMAC de confirmation (intention, empreinte, taille).
  signer(intention: string, empreinte: string, taille: number): Promise<string>
}

async function sha256Hex(octets: Uint8Array): Promise<string> {
  const copie = new ArrayBuffer(octets.byteLength)
  new Uint8Array(copie).set(octets)
  const h = await crypto.subtle.digest('SHA-256', copie)
  return Array.from(new Uint8Array(h), (o) => o.toString(16).padStart(2, '0')).join('')
}

/// Une seconde cle d'idempotence, DERIVEE de la premiere : rejouer l'outil avec la meme cle rejoue les deux actes, jamais un second brouillon.
export async function cleDerivee(cle: string, etiquette: string): Promise<string> {
  const h = await sha256Hex(new TextEncoder().encode(`${cle.toLowerCase()}:${etiquette}`))
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-8${h.slice(17, 20)}-${h.slice(20, 32)}`
}

interface Lecture {
  ok: boolean
  resultat: Record<string, Json>
  cause: string
}

function lire(brut: unknown): Lecture {
  const r = (typeof brut === 'object' && brut !== null ? brut : {}) as Record<string, Json>
  const dedans = (typeof r.resultat === 'object' && r.resultat !== null && !Array.isArray(r.resultat) ? r.resultat : {}) as Record<string, Json>
  if (r.ok === true && typeof dedans.erreur !== 'string') return { ok: true, resultat: dedans, cause: '' }
  // Une cause FERMEE : le code du refus de l'acte, de la porte ou de la base, jamais un message.
  const cause = typeof dedans.erreur === 'string' ? dedans.erreur
    : typeof r.erreur === 'string' ? (typeof r.code === 'string' ? `${r.erreur}:${r.code}` : r.erreur)
    : 'inconnue'
  return { ok: false, resultat: dedans, cause }
}

export async function deposerSupport(e: EntreeDepot, port: PortDepot): Promise<Record<string, Json>> {
  const analyse = analyser(e.corps)
  if (!analyse.ok) return { erreur: 'format', code: analyse.code, ligne: analyse.ligne }
  const octets = new TextEncoder().encode(e.corps)
  if (octets.byteLength < 1 || octets.byteLength > OCTETS_MAX) return { erreur: 'format', code: 'trop_long', ligne: 0 }
  if (!port.pret()) return { erreur: 'stockage_indisponible' }

  const empreinte = await sha256Hex(octets)
  const params: Record<string, Json> = {
    titre: e.titre, langue: e.langue, octets: octets.byteLength, sha256: empreinte,
  }
  if (e.rayon) params.rayon = e.rayon
  if (e.description) params.description = e.description

  const prepare = lire(await port.agir('depot_support_preparer', params, e.cle_idempotence))
  if (!prepare.ok) return { erreur: 'preparation', cause: prepare.cause }
  const id = String(prepare.resultat.id ?? '')
  const intention = String(prepare.resultat.upload_id ?? '')
  const cle = String(prepare.resultat.cle_finale ?? '')
  if (!id || !intention || !cle) return { erreur: 'preparation', cause: 'reponse' }

  try {
    await port.ecrire(cle, octets)
  } catch {
    // Le brouillon existe, sans fichier : on le dit, la direction (ou support_retirer) le retire.
    return { erreur: 'stockage', id, message: 'Le brouillon existe sans fichier : il doit etre retire ou le depot repris.' }
  }

  let signature: string
  try {
    signature = await port.signer(intention, empreinte, octets.byteLength)
  } catch {
    return { erreur: 'confirmation', id, cause: 'signature' }
  }
  const confirme = lire(await port.agir(
    'depot_support_confirmer',
    { upload_id: intention, sha256: empreinte, octets: octets.byteLength, signature },
    await cleDerivee(e.cle_idempotence, 'confirmer'),
  ))
  if (!confirme.ok) return { erreur: 'confirmation', id, cause: confirme.cause }
  return {
    ok: true, id, version_id: String(prepare.resultat.version_id ?? ''), revision: prepare.resultat.revision ?? null,
    etat: 'brouillon', octets: octets.byteLength,
    message: 'Depose comme BROUILLON, reserve a la direction. La direction le relit et le publie dans la Bibliotheque ; rien n\'est visible des inscrits avant.',
  }
}
