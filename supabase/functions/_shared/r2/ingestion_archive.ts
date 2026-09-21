// L'entree des metadonnees d'une archive, quand Egress annonce avoir termine.
//
// Ce module est le seul point ou une archive passe du monde LiveKit au schema
// Rewayah. Il ne touche JAMAIS le binaire : l'audio est depose directement par
// Egress dans `rewayah-session-recordings` (ADR-002, ADR-006), et ce qui arrive
// ici n'en est que le constat -- salle, cle, duree, taille, codec.
//
// Etat du branchement, et il faut le dire franchement : aucun Egress n'est
// demarre par ce depot aujourd'hui. `_shared/livekit.ts` n'importe du SDK que
// `AccessToken` et `WebhookReceiver` ; il n'existe ni `EgressClient`, ni appel
// a `startRoomCompositeEgress`. Ce module est donc le CONTRAT D'ARRIVEE, pose
// pour que le jour ou Egress sera configure, l'archive entre toute seule. Tant
// que rien ne demarre d'Egress, aucun evenement `egress_ended` n'arrive et ce
// code reste inerte.
//
// Le contrat que la configuration Egress devra respecter tient en une ligne :
//
//   filepath = recordings/<session_id>/<uuid>.ogg
//
// C'est exactement ce que `cleDe('archiveSeance', sessionId, uuid)` fabrique.
// Le gabarit doit etre calcule par le serveur au demarrage de l'Egress, et non
// laisse aux variables de LiveKit : `{room_name}` est opaque et ne permettrait
// pas de retrouver la seance sans une jointure de plus, et surtout un gabarit
// qui n'est pas calcule par nous n'est pas un gabarit que nous controlons.
//
// Ce que ce module ne croit pas : le chemin annonce par l'evenement. Un webhook
// est signe, donc authentique, mais une signature atteste l'emetteur et non le
// contenu. La cle est confrontee a la convention avant d'entrer en base -- sans
// quoi un champ `filename` deciderait de ce qui se retrouve dans une colonne
// que la lecture signera plus tard.

import type { SupabaseClient } from 'jsr:@supabase/supabase-js@2'
import { ErreurCleObjet, verifierCle } from './cles.ts'
import { seauAttendu } from './domaines.ts'

/// Ce que le webhook rapporte au sujet de l'archive, pour la reponse et les
/// journaux. Jamais d'URL, jamais de cle complete.
export type ResultatIngestion =
  | 'sans_objet'
  | 'entree'
  | 'ignoree_egress_echoue'
  | 'ignoree_sans_fichier'
  | 'refusee_cle_hors_convention'
  | 'echec_base'

interface FichierEgress {
  filename?: unknown
  location?: unknown
  duration?: unknown
  size?: unknown
}

/// Traite un evenement LiveKit s'il annonce la fin d'un Egress, sinon ne fait
/// rien.
///
/// Ne leve jamais : le webhook doit repondre 200 a LiveKit pour l'evenement de
/// presence qu'il vient de traiter, et un renvoi provoque par une archive
/// rejouerait aussi cette presence.
export async function entrerArchiveSiEgressTermine(
  service: SupabaseClient,
  type: string,
  evenement: Record<string, unknown>,
): Promise<ResultatIngestion> {
  if (type !== 'egress_ended') {
    return 'sans_objet'
  }

  const info = evenement.egressInfo as Record<string, unknown> | undefined
  if (!info) {
    return 'ignoree_sans_fichier'
  }

  // `EGRESS_COMPLETE` est le seul etat qui garantit un objet depose. Un Egress
  // avorte annonce lui aussi sa fin, et enregistrer ses metadonnees creerait
  // une archive que personne ne pourrait lire.
  const etat = String(info.status ?? '')
  if (etat !== 'EGRESS_COMPLETE' && etat !== '3') {
    console.error('egress termine sans succes', { etat })
    return 'ignoree_egress_echoue'
  }

  const fichiers = Array.isArray(info.fileResults) ? (info.fileResults as FichierEgress[]) : []
  const fichier = fichiers[0]
  if (!fichier) {
    return 'ignoree_sans_fichier'
  }

  const salle = String(info.roomName ?? '').trim()
  const egress = String(info.egressId ?? '').trim()
  const chemin = String(fichier.filename ?? '').trim()
  if (!salle || !egress || !chemin) {
    return 'ignoree_sans_fichier'
  }

  let cle: string
  try {
    // Selon le mode de sortie, Egress annonce parfois un chemin prefixe du nom
    // du seau. Le prefixe est retire depuis `domaines.ts`, jamais recopie ici :
    // un nom de seau ecrit en dur dans un deuxieme fichier est un nom de seau
    // qui divergera.
    const prefixe = `${seauAttendu('archiveSeance')}/`
    const sansPrefixe = chemin.startsWith(prefixe) ? chemin.slice(prefixe.length) : chemin
    cle = verifierCle('archiveSeance', sansPrefixe)
  } catch (e) {
    // Un chemin hors convention signifie que le gabarit Egress ne correspond
    // pas au contrat. C'est une faute de configuration a corriger, pas une
    // ligne a inserer : une cle qu'on ne reconnait pas est une cle qu'on ne
    // saura pas autoriser ensuite.
    console.error('archive refusee : cle hors convention', {
      motif: e instanceof ErreurCleObjet ? e.motif : 'inconnu',
      egress,
    })
    return 'refusee_cle_hors_convention'
  }

  // LiveKit exprime la duree en nanosecondes.
  const dureeNs = Number(fichier.duration ?? 0)
  const duree = Number.isFinite(dureeNs) && dureeNs > 0 ? Math.round(dureeNs / 1_000_000_000) : 0
  const taille = Number(fichier.size ?? 0)

  const { error } = await service.rpc('enregistrer_archive_seance', {
    p_room_name: salle,
    p_egress_id: egress,
    p_object_key: cle,
    p_duration_seconds: duree,
    p_size_bytes: Number.isFinite(taille) && taille > 0 ? Math.round(taille) : 0,
    // `EgressInfo` ne porte pas de champ `codec` : le format demande vit dans
    // la requete d'origine (`request.options`), que l'evenement de fin ne
    // reprend pas. Plutot que de lire un champ qui n'existe pas et de croire
    // l'avoir renseigne, la colonne reste nulle -- elle est nullable depuis
    // `0001` -- et sera remplie par le code qui DEMARRE l'Egress, puisque
    // c'est lui qui choisit le format.
    p_codec: null,
  })

  if (error) {
    console.error('entree de l archive impossible', { egress, erreur: error.message })
    return 'echec_base'
  }

  return 'entree'
}
