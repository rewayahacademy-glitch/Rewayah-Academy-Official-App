// IMAGES-MESSAGERIE (16/11/2026) : le depot d'une image dans un message, sur le
// modele de `bibliotheque-upload` : demande, lien PUT signe, confirmation HMAC.
// Ouverte avec jeton (config.toml, verify_jwt) ; l'appelant est lu dans son
// jeton, et c'est lui que la base juge (participation, droit d'ecrire, mineur,
// 20 images par heure). Contrat complet : docs/current/IMAGES-MESSAGERIE.md.
//
// action « demander »  { message_id, image: {mime, octets, largeur, hauteur,
//                        couleur_moyenne?}, miniature: {mime, octets} }
//   -> { image_id, expire_dans_secondes, image: {url, methode, en_tetes_exiges},
//        miniature: {...} } ; deux URL PUT de 10 minutes, vers R2_MESSAGING.
// action « confirmer » { image_id }
//   -> lit les 16 premiers octets des DEUX objets, compare au type annonce,
//      signe (HMAC) et la base passe l'image a « confirmee ».
// action « annuler »   { image_id } -> abandonne un depot en attente.
//
// Refus : { error, code } avec un code lisible (voir docs/current/IMAGES-MESSAGERIE.md).

import { enTetesCors, json } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import {
  journaliser,
  lireEnteteObjet,
  signerDepot,
  supprimerObjet,
} from '../_shared/r2/signature.ts'
import { sha256Hex } from '../_shared/r2/bibliotheque_upload.ts'
import { signatureConfirmationUpload } from '../_shared/r2/confirmation_hmac.ts'
import {
  cleImageValide,
  DOMAINE_CONFIRMATION_IMAGE,
  DUREE_DEPOT_IMAGE_S,
  enteteConforme,
  estRefus,
  estUuid,
  lireDemande,
  type Refus,
  refusBase,
  refusDe,
  TAILLE_IMAGE_MAX_OCTETS,
  TAILLE_MINIATURE_MAX_OCTETS,
  TYPES_IMAGE_MESSAGE,
} from '../_shared/r2/message_image.ts'

type Compte = NonNullable<Awaited<ReturnType<typeof appelantR2>>>

const DOMAINE = 'pieceJointeMessage' as const

function refuser(r: Refus): Response {
  return json({ error: r.message, code: r.code }, r.statut)
}

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') return new Response('ok', { headers: enTetesCors })
  if (requete.method !== 'POST') return json({ error: 'methode non autorisee' }, 405)

  let compte: Awaited<ReturnType<typeof appelantR2>>
  try {
    compte = await appelantR2(requete)
  } catch {
    return refuser(refusDe('stockage_indisponible'))
  }
  if (!compte) return json({ error: 'authentification requise' }, 401)

  let corps: Record<string, unknown>
  try {
    const donnees: unknown = await requete.json()
    if (!donnees || typeof donnees !== 'object' || Array.isArray(donnees)) {
      return refuser(refusDe('demande_invalide'))
    }
    corps = donnees as Record<string, unknown>
  } catch {
    return refuser(refusDe('demande_invalide'))
  }
  // Une cle ou un seau recus du client sont une demande, pas une designation.
  if ('object_key' in corps || 'cle_stockage' in corps || 'bucket' in corps || 'cle' in corps) {
    return refuser(refusDe('demande_invalide'))
  }

  switch (corps.action) {
    case 'demander':
      return await demander(compte, corps)
    case 'confirmer':
      return await confirmer(compte, corps)
    case 'annuler':
      return await annuler(compte, corps)
    default:
      return refuser(refusDe('demande_invalide'))
  }
})

async function demander(compte: Compte, corps: Record<string, unknown>): Promise<Response> {
  const demande = lireDemande(corps)
  if (estRefus(demande)) return refuser(demande)
  if (!stockageConfigure(DOMAINE)) return refuser(refusDe('stockage_indisponible'))

  const { data, error } = await compte.sql.rpc('message_image_demander', {
    p_message_id: demande.messageId,
    p_mime: demande.mime,
    p_octets: demande.octets,
    p_mime_miniature: demande.mimeMiniature,
    p_octets_miniature: demande.octetsMiniature,
    p_largeur: demande.largeur,
    p_hauteur: demande.hauteur,
    p_couleur_moyenne: demande.couleurMoyenne,
  })
  if (error) return refuser(refusBase(error))
  const ligne = data as Record<string, unknown> | null
  if (!ligne || !estUuid(ligne.image_id) || !estUuid(ligne.fil_id)) {
    return refuser(refusDe('depot_impossible'))
  }
  // Les cles viennent de la base ; on les confronte quand meme a la convention.
  const cleImage = cleImageValide(ligne.cle_r2, ligne.fil_id, false)
  const cleMiniature = cleImageValide(ligne.cle_miniature, ligne.fil_id, true)
  if (!cleImage || !cleMiniature) return refuser(refusDe('depot_impossible'))
  try {
    const image = await signerDepot(DOMAINE, cleImage, {
      typeMime: demande.mime,
      tailleOctets: Number(ligne.octets),
      typesAutorises: TYPES_IMAGE_MESSAGE,
      tailleMaximaleOctets: TAILLE_IMAGE_MAX_OCTETS,
      dureeSecondes: DUREE_DEPOT_IMAGE_S,
    })
    const miniature = await signerDepot(DOMAINE, cleMiniature, {
      typeMime: demande.mimeMiniature,
      tailleOctets: Number(ligne.octets_miniature),
      typesAutorises: TYPES_IMAGE_MESSAGE,
      tailleMaximaleOctets: TAILLE_MINIATURE_MAX_OCTETS,
      dureeSecondes: DUREE_DEPOT_IMAGE_S,
    })
    journaliser({ domaine: DOMAINE, operation: 'depot', statut: 'accorde', ressource: ligne.image_id })
    return json({
      image_id: ligne.image_id,
      expire_dans_secondes: DUREE_DEPOT_IMAGE_S,
      image: { url: image.url, methode: 'PUT', en_tetes_exiges: image.enTetesExiges },
      miniature: { url: miniature.url, methode: 'PUT', en_tetes_exiges: miniature.enTetesExiges },
    })
  } catch (erreur) {
    journaliser({
      domaine: DOMAINE,
      operation: 'depot',
      statut: 'echec',
      ressource: ligne.image_id,
      classeErreur: (erreur as Error)?.name ?? 'inconnue',
    })
    return refuser(refusDe('stockage_indisponible'))
  }
}

async function confirmer(compte: Compte, corps: Record<string, unknown>): Promise<Response> {
  const id = typeof corps.image_id === 'string' ? corps.image_id.trim().toLowerCase() : ''
  if (!estUuid(id)) return refuser(refusDe('demande_invalide'))
  let secret = ''
  try {
    secret = Deno.env.get('LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY') ?? ''
  } catch {
    return refuser(refusDe('confirmation_indisponible'))
  }
  if (new TextEncoder().encode(secret).byteLength < 32 || secret.trim() !== secret) {
    return refuser(refusDe('confirmation_indisponible'))
  }
  if (!stockageConfigure(DOMAINE)) return refuser(refusDe('stockage_indisponible'))

  const lu = await compte.sql.rpc('message_image_lire_depot', { p_image_id: id })
  if (lu.error) return refuser(refusBase(lu.error))
  const depot = lu.data as Record<string, unknown> | null
  if (!depot || !estUuid(depot.fil_id)) return refuser(refusDe('depot_impossible'))
  const cleImage = cleImageValide(depot.cle_r2, depot.fil_id, false)
  const cleMiniature = cleImageValide(depot.cle_miniature, depot.fil_id, true)
  if (!cleImage || !cleMiniature) return refuser(refusDe('depot_impossible'))
  const mime = String(depot.mime)
  const mimeMiniature = String(depot.mime_miniature)

  const debut = Date.now()
  try {
    // Les 16 premiers octets de chaque objet, jamais l'objet entier. La taille
    // exacte est tenue par le Content-Length SIGNE du depot : R2 refuse un envoi
    // d'une autre taille que celle accordee.
    const teteImage = await lireEnteteObjet(DOMAINE, cleImage)
    const teteMiniature = await lireEnteteObjet(DOMAINE, cleMiniature)
    if (!teteImage || !teteMiniature) return refuser(refusDe('objet_introuvable'))
    if (!enteteConforme(mime, teteImage.octets) || !enteteConforme(mimeMiniature, teteMiniature.octets)) {
      // Un contenu qui n'est pas l'image annoncee : les deux objets sont retires
      // et le depot est abandonne. Si le retrait echoue, le depot reste « en
      // attente » et la purge de nuit le reprend.
      try {
        await supprimerObjet(DOMAINE, cleImage)
        await supprimerObjet(DOMAINE, cleMiniature)
        await compte.sql.rpc('message_image_annuler', { p_image_id: id })
      } catch { /* la purge reprendra */ }
      journaliser({ domaine: DOMAINE, operation: 'depot', statut: 'refuse', ressource: id, dureeMs: Date.now() - debut })
      return refuser(refusDe('contenu_different'))
    }
    const tete = new Uint8Array(teteImage.octets.length + teteMiniature.octets.length)
    tete.set(teteImage.octets, 0)
    tete.set(teteMiniature.octets, teteImage.octets.length)
    const empreinte = await sha256Hex(tete)
    const signature = await signatureConfirmationUpload(
      secret,
      id,
      empreinte,
      Number(depot.octets),
      DOMAINE_CONFIRMATION_IMAGE,
    )
    const confirme = await compte.sql.rpc('message_image_confirmer', {
      p_image_id: id,
      p_tete_sha256: empreinte,
      p_mime_reel: mime,
      p_mime_miniature_reel: mimeMiniature,
      p_confirmation_signature: signature,
    })
    if (confirme.error) return refuser(refusBase(confirme.error))
    journaliser({ domaine: DOMAINE, operation: 'depot', statut: 'accorde', ressource: id, dureeMs: Date.now() - debut })
    return json({ phase: 'pret', image_id: id, etat: 'confirmee' })
  } catch (erreur) {
    journaliser({
      domaine: DOMAINE,
      operation: 'depot',
      statut: 'echec',
      ressource: id,
      classeErreur: (erreur as Error)?.name ?? 'inconnue',
      dureeMs: Date.now() - debut,
    })
    return refuser(refusDe('stockage_indisponible'))
  }
}

async function annuler(compte: Compte, corps: Record<string, unknown>): Promise<Response> {
  const id = typeof corps.image_id === 'string' ? corps.image_id.trim().toLowerCase() : ''
  if (!estUuid(id)) return refuser(refusDe('demande_invalide'))
  const lu = await compte.sql.rpc('message_image_lire_depot', { p_image_id: id })
  if (lu.error) return refuser(refusBase(lu.error))
  const depot = lu.data as Record<string, unknown> | null
  if (!depot || !estUuid(depot.fil_id)) return refuser(refusDe('depot_impossible'))
  const cleImage = cleImageValide(depot.cle_r2, depot.fil_id, false)
  const cleMiniature = cleImageValide(depot.cle_miniature, depot.fil_id, true)
  if (!cleImage || !cleMiniature) return refuser(refusDe('depot_impossible'))
  try {
    if (stockageConfigure(DOMAINE)) {
      await supprimerObjet(DOMAINE, cleImage)
      await supprimerObjet(DOMAINE, cleMiniature)
    }
  } catch {
    // Le depot reste en attente : la purge de nuit retirera les objets.
    return refuser(refusDe('stockage_indisponible'))
  }
  const { data, error } = await compte.sql.rpc('message_image_annuler', { p_image_id: id })
  if (error) return refuser(refusBase(error))
  return json({ annule: data === true })
}
