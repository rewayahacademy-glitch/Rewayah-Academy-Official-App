// Les en-tetes d'un envoi et le lien de desinscription en un clic
// (COURRIELS-1), sans dependance : `transport.ts` les applique, les tests les
// lisent sans charger le client SMTP.

export interface Envoi {
  de: string
  deNom: string
  repondreA: string
  a: string
  sujet: string
  html: string
  texte: string
  /// URL HTTPS de desinscription en un clic (RFC 8058), categories non essentielles.
  desinscriptionUnClic?: string
  /// Identifiant stable : Gmail regroupe sans doublon un message renvoye.
  idMessage: string
}

/// Les en-tetes ajoutes au message ; ceux de liste seulement avec un lien de
/// desinscription en un clic (jamais pour une lettre : [lienUnClic]).
export function entetes(e: Envoi): Record<string, string> {
  const h: Record<string, string> = { 'X-Entity-Ref-ID': e.idMessage }
  if (e.desinscriptionUnClic) {
    h['List-Unsubscribe'] = `<${e.desinscriptionUnClic}>`
    h['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'
  }
  return h
}

/// Le lien de desinscription en un clic d'un message (RFC 8058), ou
/// `undefined` : categorie essentielle, pas de jeton, ou lettre personnelle
/// (pilote, 25/10/2026 : les en-tetes de liste sont un signal « promotion »
/// pour Gmail ; la lettre garde son lien en corps).
export function lienUnClic(
  o: { lettre?: boolean; essentielle: boolean; jeton: string | null; base: string },
): string | undefined {
  if (o.lettre === true || o.essentielle || !o.jeton) return undefined
  return `${o.base}?jeton=${encodeURIComponent(o.jeton)}`
}
