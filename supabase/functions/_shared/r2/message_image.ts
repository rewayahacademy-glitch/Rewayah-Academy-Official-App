// IMAGES-MESSAGERIE (16/11/2026) : la logique pure des fonctions Edge
// `message-image-depot`, `message-images-lecture` et `message-images-purge`,
// testee sans reseau (`message_image_test.ts`).
//
// Le seau est celui de la messagerie (domaine `pieceJointeMessage`, secrets
// R2_MESSAGING_*) ; aucun seau ni secret nouveau. Les cles sont fabriquees par la
// BASE (`message_image_demander`), jamais par le client : `fils/<fil>/<uuid>.<ext>`
// pour l'image et `fils/<fil>/<uuid>-min.<ext>` pour sa miniature. Cette
// convention n'est pas celle de `cles.ts` (`messages/<conversation>/<piece>`, qui
// n'a aucun emploi) : elle a son propre verificateur ici, strict.

import { contenuConforme } from './contenu_piece.ts'

/// Les types acceptes, et rien d'autre. Un GIF, un HEIC ou un SVG est refuse.
export const TYPES_IMAGE_MESSAGE: readonly string[] = ['image/jpeg', 'image/png', 'image/webp']

/// Limites serveur, apres la compression faite sur l'appareil.
export const TAILLE_IMAGE_MAX_OCTETS = 2 * 1024 * 1024
export const TAILLE_MINIATURE_MAX_OCTETS = 100 * 1024

/// Validite des liens : depot 10 minutes, lecture 1 heure.
export const DUREE_DEPOT_IMAGE_S = 600
export const DUREE_LECTURE_IMAGE_S = 3600

/// Lots de la purge : 200 lignes par lot, 25 lots au plus par invocation.
export const LOT_PURGE = 200
export const LOTS_PURGE_MAX = 25

/// Nom de domaine du message signe a la confirmation, ecrit a l'identique dans
/// `public.message_image_confirmer`.
export const DOMAINE_CONFIRMATION_IMAGE = 'message-image-v1'

const UUID = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
const UUID_RE = new RegExp(`^${UUID}$`, 'i')
const CLE_RE = new RegExp(`^fils/(${UUID})/(${UUID})(-min)?\\.(jpg|png|webp)$`)

export function estUuid(valeur: unknown): valeur is string {
  return typeof valeur === 'string' && UUID_RE.test(valeur.trim())
}

export function extensionDe(mime: string): 'jpg' | 'png' | 'webp' | null {
  switch (mime) {
    case 'image/jpeg':
      return 'jpg'
    case 'image/png':
      return 'png'
    case 'image/webp':
      return 'webp'
    default:
      return null
  }
}

/// Confronte une cle rendue par la base a la convention, et au fil attendu.
/// Rend la cle, ou `null` : une cle etrangere n'est jamais signee.
export function cleImageValide(cle: unknown, filId: string, miniature: boolean): string | null {
  if (typeof cle !== 'string') return null
  const m = CLE_RE.exec(cle)
  if (!m) return null
  if (m[1] !== filId.toLowerCase()) return null
  if ((m[3] === '-min') !== miniature) return null
  return cle
}

/// Webp : `RIFF` + taille + `WEBP` (12 octets). `contenu_piece.ts` ne connait
/// pas webp et sert a la piece d'identite : on ne l'elargit pas, on complete ici.
function estWebp(octets: Uint8Array): boolean {
  if (octets.length < 12) return false
  const ascii = (a: number, b: number) => String.fromCharCode(...octets.subarray(a, b))
  return ascii(0, 4) === 'RIFF' && ascii(8, 12) === 'WEBP'
}

/// Vrai quand les premiers octets sont bien ceux du type annonce (JPEG, PNG par
/// `contenuConforme`, WebP par le complement ci-dessus).
export function enteteConforme(mime: string, octets: Uint8Array): boolean {
  if (mime === 'image/webp') return estWebp(octets)
  if (mime === 'image/jpeg' || mime === 'image/png') return contenuConforme(mime, octets)
  return false
}

export interface DemandeImage {
  readonly messageId: string
  readonly mime: string
  readonly octets: number
  readonly largeur: number
  readonly hauteur: number
  readonly couleurMoyenne: string | null
  readonly mimeMiniature: string
  readonly octetsMiniature: number
}

export type CodeRefus =
  | 'demande_invalide'
  | 'type_refuse'
  | 'image_trop_lourde'
  | 'miniature_trop_lourde'
  | 'non_autorise'
  | 'mineur_refuse'
  | 'limite_horaire'
  | 'deja_une_image'
  | 'depot_indisponible'
  | 'confirmation_mal_reglee'
  | 'confirmation_indisponible'
  | 'contenu_different'
  | 'objet_introuvable'
  | 'stockage_indisponible'
  | 'depot_impossible'

export interface Refus {
  readonly code: CodeRefus
  readonly message: string
  readonly statut: number
}

const TEXTES: Record<CodeRefus, [string, number]> = {
  demande_invalide: ['demande invalide', 400],
  type_refuse: ['format non autorise : JPEG, PNG ou WebP seulement', 415],
  image_trop_lourde: ['image de plus de 2 Mo', 413],
  miniature_trop_lourde: ['miniature de plus de 100 Ko', 413],
  non_autorise: ['envoi d\'image non autorise', 403],
  mineur_refuse: ['un compte eleve de moins de 18 ans n\'envoie pas d\'image', 403],
  limite_horaire: ['20 images par heure au plus', 429],
  deja_une_image: ['une seule image par message', 409],
  depot_indisponible: ['depot inconnu, deja confirme ou expire', 410],
  confirmation_mal_reglee: ['confirmation mal reglee', 503],
  confirmation_indisponible: ['confirmation indisponible', 503],
  contenu_different: ['le contenu n\'est pas du type annonce', 422],
  objet_introuvable: ['objet depose introuvable', 422],
  stockage_indisponible: ['stockage indisponible', 503],
  depot_impossible: ['depot impossible', 500],
}

export function refusDe(code: CodeRefus): Refus {
  const [message, statut] = TEXTES[code]
  return { code, message, statut }
}

/// Le motif vrai d'un refus de la base : le NOM de l'exception, jamais un 403
/// pour tout. Un message inconnu est une panne (500), pas un refus qui accuserait
/// la personne.
export function refusBase(erreur: { message?: string; code?: string } | null | undefined): Refus {
  const message = erreur?.message ?? ''
  if (message.includes('ImageMineurRefuse')) return refusDe('mineur_refuse')
  if (message.includes('ImageLimiteHoraire')) return refusDe('limite_horaire')
  if (message.includes('ImageDejaPourMessage')) return refusDe('deja_une_image')
  if (message.includes('ImageIntentionIndisponible')) return refusDe('depot_indisponible')
  if (message.includes('ImageConfirmationNonAutorisee')) return refusDe('confirmation_mal_reglee')
  if (message.includes('ImageParametresInvalides')) return refusDe('demande_invalide')
  if (message.includes('ImageNonAutorise') || message.includes('ImageMessageIntrouvable')) {
    return refusDe('non_autorise')
  }
  if (erreur?.code === '42501') return refusDe('non_autorise')
  return refusDe('depot_impossible')
}

function entier(v: unknown): number {
  return typeof v === 'number' && Number.isSafeInteger(v) ? v : Number.NaN
}

/// Lit et borne le corps d'une demande de depot. Rend la demande ou le refus.
/// Les bornes sont celles de la base (ceinture et bretelles) : un depot refuse
/// ici ne cree aucune ligne.
export function lireDemande(corps: Record<string, unknown>): DemandeImage | Refus {
  const image = objet(corps.image)
  const mini = objet(corps.miniature)
  const messageId = typeof corps.message_id === 'string' ? corps.message_id.trim().toLowerCase() : ''
  if (!estUuid(messageId) || !image || !mini) return refusDe('demande_invalide')

  const mime = typeof image.mime === 'string' ? image.mime.trim().toLowerCase() : ''
  const mimeMiniature = typeof mini.mime === 'string' ? mini.mime.trim().toLowerCase() : ''
  if (!TYPES_IMAGE_MESSAGE.includes(mime) || !TYPES_IMAGE_MESSAGE.includes(mimeMiniature)) {
    return refusDe('type_refuse')
  }
  const octets = entier(image.octets)
  const octetsMiniature = entier(mini.octets)
  const largeur = entier(image.largeur)
  const hauteur = entier(image.hauteur)
  if (!(octets > 0) || !(octetsMiniature > 0) || !(largeur >= 1 && largeur <= 20000) ||
    !(hauteur >= 1 && hauteur <= 20000)) {
    return refusDe('demande_invalide')
  }
  if (octets > TAILLE_IMAGE_MAX_OCTETS) return refusDe('image_trop_lourde')
  if (octetsMiniature > TAILLE_MINIATURE_MAX_OCTETS) return refusDe('miniature_trop_lourde')

  let couleurMoyenne: string | null = null
  if (image.couleur_moyenne !== undefined && image.couleur_moyenne !== null) {
    if (typeof image.couleur_moyenne !== 'string' || !/^#?[0-9a-fA-F]{6}$/.test(image.couleur_moyenne.trim())) {
      return refusDe('demande_invalide')
    }
    couleurMoyenne = '#' + image.couleur_moyenne.trim().replace(/^#/, '').toLowerCase()
  }
  return { messageId, mime, octets, largeur, hauteur, couleurMoyenne, mimeMiniature, octetsMiniature }
}

export function estRefus(v: DemandeImage | Refus): v is Refus {
  return 'code' in v && 'statut' in v
}

function objet(v: unknown): Record<string, unknown> | null {
  return v && typeof v === 'object' && !Array.isArray(v) ? v as Record<string, unknown> : null
}

/// Un enregistrement de la purge : les deux cles d'objets d'une image a retirer.
export interface ImageAPurger {
  readonly id: string
  readonly cle_r2: string
  readonly cle_miniature: string
}

export function lireLotPurge(donnees: unknown): ImageAPurger[] {
  if (!Array.isArray(donnees)) return []
  const lot: ImageAPurger[] = []
  for (const l of donnees) {
    const r = objet(l)
    if (!r) continue
    const m = typeof r.cle_r2 === 'string' ? CLE_RE.exec(r.cle_r2) : null
    // Une ligne dont les cles sortent de la convention est ecartee, jamais
    // devinee : mieux vaut ne rien retirer que retirer le mauvais objet.
    if (
      estUuid(r.id) && m && cleImageValide(r.cle_r2, m[1], false) &&
      cleImageValide(r.cle_miniature, m[1], true)
    ) {
      lot.push({ id: r.id, cle_r2: r.cle_r2 as string, cle_miniature: r.cle_miniature as string })
    }
  }
  return lot
}

export interface BilanPurge {
  retirees: number
  echecs: number
  lots: number
}

export interface DependancesPurge {
  /** Lit un lot d'images a retirer (RPC `message_images_purge_lire`). */
  lire: (lot: number) => Promise<unknown>
  /** Retire un objet R2 ; un objet deja absent n'est pas une erreur. */
  supprimer: (cle: string) => Promise<void>
  /** Marque ces images « supprimee » (RPC `message_images_purge_marquer`). */
  marquer: (ids: string[]) => Promise<void>
}

/// La purge : un lot de 200, puis un autre tant qu'il en reste, au plus 25 lots.
/// Une ligne n'est marquee « supprimee » que si LES DEUX objets sont partis ; sinon
/// elle reste due et la nuit suivante la reprend. Un lot sans aucune reussite
/// arrete la boucle (sinon elle relirait les memes lignes en echec).
export async function purger(dep: DependancesPurge): Promise<BilanPurge> {
  const bilan: BilanPurge = { retirees: 0, echecs: 0, lots: 0 }
  for (let i = 0; i < LOTS_PURGE_MAX; i++) {
    const lot = lireLotPurge(await dep.lire(LOT_PURGE))
    if (lot.length === 0) break
    bilan.lots++
    const faits: string[] = []
    for (const image of lot) {
      try {
        await dep.supprimer(image.cle_r2)
        await dep.supprimer(image.cle_miniature)
        faits.push(image.id)
      } catch {
        bilan.echecs++
      }
    }
    if (faits.length > 0) {
      await dep.marquer(faits)
      bilan.retirees += faits.length
    }
    if (faits.length === 0 || lot.length < LOT_PURGE) break
  }
  return bilan
}
