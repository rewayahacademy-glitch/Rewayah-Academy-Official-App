// IMAGES-MESSAGERIE (16/11/2026) : les liens de lecture des images d'un fil.
// Ouverte avec jeton (config.toml, verify_jwt) ; la participation au fil est
// jugee par la base (`message_images_a_signer`). Contrat : docs/current/IMAGES-MESSAGERIE.md.
//
//   { fil_id }                  -> TOUTES les miniatures du fil, en un appel
//   { fil_id, image_id }        -> l'image complete demandee
//
// Reponse : { images: [{ id, message_id, etat, url?, mime?, expire_dans_secondes? }] }
// Les URL sont des GET signes valables 1 heure. Une image « supprimee » (retiree
// ou expiree a 90 jours) rend son etat SANS url. Jamais un appel par image.

import { enTetesCors, json } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import { journaliser, signerLecture } from '../_shared/r2/signature.ts'
import {
  cleImageValide,
  DUREE_LECTURE_IMAGE_S,
  estUuid,
  refusBase,
  refusDe,
  type Refus,
} from '../_shared/r2/message_image.ts'

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
  if ('object_key' in corps || 'cle_stockage' in corps || 'bucket' in corps || 'cle' in corps) {
    return refuser(refusDe('demande_invalide'))
  }
  const filId = typeof corps.fil_id === 'string' ? corps.fil_id.trim().toLowerCase() : ''
  const imageId = corps.image_id === undefined || corps.image_id === null
    ? null
    : typeof corps.image_id === 'string' ? corps.image_id.trim().toLowerCase() : ''
  if (!estUuid(filId) || (imageId !== null && !estUuid(imageId))) {
    return refuser(refusDe('demande_invalide'))
  }

  const { data, error } = await compte.sql.rpc('message_images_a_signer', {
    p_fil_id: filId,
    p_image_id: imageId,
  })
  if (error) return refuser(refusBase(error))
  const lignes = Array.isArray(data) ? data as Record<string, unknown>[] : []
  const aSigner = lignes.some((l) => typeof l.cle === 'string')
  if (aSigner && !stockageConfigure(DOMAINE)) return refuser(refusDe('stockage_indisponible'))

  try {
    const images = await Promise.all(lignes.map(async (l) => {
      const base: Record<string, unknown> = { id: l.id, message_id: l.message_id, etat: l.etat }
      if (typeof l.cle !== 'string') return base
      const cle = cleImageValide(l.cle, filId, imageId === null)
      if (!cle) return { ...base, etat: 'supprimee' }
      const signee = await signerLecture(DOMAINE, cle, { dureeSecondes: DUREE_LECTURE_IMAGE_S })
      return {
        ...base,
        url: signee.url,
        mime: l.mime,
        expire_dans_secondes: signee.expireDansSecondes,
      }
    }))
    journaliser({ domaine: DOMAINE, operation: 'lecture', statut: 'accorde', ressource: filId })
    return json({ images })
  } catch (erreur) {
    journaliser({
      domaine: DOMAINE,
      operation: 'lecture',
      statut: 'echec',
      ressource: filId,
      classeErreur: (erreur as Error)?.name ?? 'inconnue',
    })
    return refuser(refusDe('stockage_indisponible'))
  }
})
