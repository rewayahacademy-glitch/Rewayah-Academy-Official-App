// PX-KYC-1 : le client du fournisseur (API Messages d'Anthropic). Mince, sans outil, sans rien d'autre que la consigne
// fixe et UNE piece. Injectable (`fetchImpl`) pour que les tests n'appellent jamais le reseau.
//
// Ce que ce fichier ne fait jamais : envoyer le nom du dossier, un identifiant, une cle d'objet ; declarer un outil ;
// journaliser la reponse, l'image ou la cle (une erreur ne porte que sa CLASSE).
//
// JAMAIS execute contre l'API reelle dans ce lot : il n'y a pas de cle. Le premier essai reel se fait sur le projet de
// STAGING, avec des images fictives, apres que le directeur a pose une cle d'essai (plan, section 5.2).

import { CONSIGNE, ErreurFournisseur, type Fournisseur } from './lecture.ts'

export const ADRESSE_API = 'https://api.anthropic.com/v1/messages'
export const VERSION_API = '2023-06-01'
/// Delai d'un appel : une piece qui ne repond pas en une minute est une panne, pas une attente sans fin.
export const DELAI_APPEL_MS = 60_000

function base64(octets: Uint8Array): string {
  let s = ''
  const pas = 0x8000
  for (let i = 0; i < octets.length; i += pas) {
    s += String.fromCharCode(...octets.subarray(i, i + pas))
  }
  return btoa(s)
}

export function creerFournisseurAnthropic(cle: string, fetchImpl: typeof fetch = fetch): Fournisseur {
  return {
    async lire({ modele, octets, format }) {
      const bloc = format.type === 'image'
        ? { type: 'image', source: { type: 'base64', media_type: format.mime, data: base64(octets) } }
        : { type: 'document', source: { type: 'base64', media_type: format.mime, data: base64(octets) } }
      const corps = {
        model: modele,
        max_tokens: 700,
        temperature: 0,
        system: CONSIGNE,
        messages: [{ role: 'user', content: [bloc, { type: 'text', text: 'Read this document. Answer with the JSON object only.' }] }],
      }
      let reponse: Response
      try {
        reponse = await fetchImpl(ADRESSE_API, {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-api-key': cle, 'anthropic-version': VERSION_API },
          body: JSON.stringify(corps),
          signal: AbortSignal.timeout(DELAI_APPEL_MS),
        })
      } catch {
        throw new ErreurFournisseur('panne')
      }
      if (reponse.status === 401 || reponse.status === 403) throw new ErreurFournisseur('configuration')
      if (reponse.status === 400 || reponse.status === 413 || reponse.status === 422) throw new ErreurFournisseur('refus')
      if (!reponse.ok) throw new ErreurFournisseur('panne')
      let donnees: unknown
      try {
        donnees = await reponse.json()
      } catch {
        throw new ErreurFournisseur('panne')
      }
      const d = donnees as { stop_reason?: unknown; content?: unknown }
      if (d.stop_reason === 'refusal') throw new ErreurFournisseur('refus')
      if (!Array.isArray(d.content)) throw new ErreurFournisseur('panne')
      const texte = d.content
        .filter((b): b is { type: string; text: string } =>
          typeof b === 'object' && b !== null && (b as { type?: unknown }).type === 'text' &&
          typeof (b as { text?: unknown }).text === 'string')
        .map((b) => b.text)
        .join('')
      return texte
    },
  }
}
