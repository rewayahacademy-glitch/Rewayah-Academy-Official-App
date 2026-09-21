// Ecouter une archive de seance.
//
//   { recording_id }  ->  { url, expire_dans_secondes, duree_secondes }
//
// L'ADR-002 tient en une phrase, et ce fichier n'en est que la transcription :
// << bucket prive, URL signee 60 secondes, generation serveur uniquement,
// chaque ecoute ecrite dans `audit_logs` avec l'identite de l'auditeur >>.
//
// Les quatre exigences se realisent dans cet ordre :
//
//   1. l'appelant est identifie par SON jeton ;
//   2. `autoriser_ecoute_archive()` verifie en base la relation a la seance
//      (administration, controle, enseignant de la seance, ou foyer d'un
//      participant), l'etat de l'archive et sa date d'expiration, puis ecrit la
//      trace d'audit. Elle est appelee SOUS l'identite de l'appelant : c'est ce
//      qui fait que `auth.uid()` -- donc l'acteur du journal -- designe
//      reellement celui qui ecoute ;
//   3. la couche R2 signe soixante secondes de lecture seule ;
//   4. rien de tout cela ne fait transiter un octet d'audio par ce serveur.
//
// Le binaire ne passe jamais par ici, ni a l'ecriture ni a la lecture : Egress
// depose directement dans le seau, et le client lit directement depuis le seau,
// en flux et par plages HTTP. Une fonction Edge qui relaierait des archives
// audio serait un goulot a dimensionner pour rien.
//
// Un gel de conservation ne prolonge l'acces que pour l'administration et le
// controle : il existe pour un litige, pas pour rendre une piece expiree
// reecoutable par la famille.

import { enTetesCors, json, refus } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { verifierCle } from '../_shared/r2/cles.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import {
  DUREE_LECTURE_SENSIBLE_S,
  journaliser,
  messagePourClient,
  signerLecture,
} from '../_shared/r2/signature.ts'

interface AutorisationArchive {
  recording_id: string
  session_id: string
  object_key: string
  duration_seconds: number
  expires_at: string
}

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (requete.method !== 'POST') {
    return refus('methode non autorisee', 405)
  }

  if (!stockageConfigure('archiveSeance')) {
    return refus('archives non configurees', 503)
  }

  const compte = await appelantR2(requete)
  if (!compte) {
    return refus('authentification requise', 401)
  }

  let corps: Record<string, unknown>
  try {
    corps = await requete.json()
  } catch {
    return refus('corps illisible')
  }

  const archive = String(corps.recording_id ?? '').trim()
  if (!archive) {
    return refus('archive non precisee')
  }
  if ('object_key' in corps) {
    return refus('la cle d objet est resolue par le serveur', 400)
  }

  const debut = Date.now()

  const { data, error } = await compte.sql.rpc('autoriser_ecoute_archive', {
    p_recording_id: archive,
  })

  if (error || !data) {
    // Refus, archive inexistante, archive expiree ou revoquee : le client
    // apprend qu'il n'ecoutera pas, et rien d'autre. Distinguer ces cas
    // renseignerait sur l'existence de seances auxquelles il n'a pas part.
    console.error('ecoute d archive refusee', { erreur: error?.message })
    // Pas d'identifiant dans la trace d'un refus : il vient du client et n'a
    // pas ete reconnu.
    journaliser({
      domaine: 'archiveSeance',
      operation: 'lecture',
      statut: 'refuse',
      dureeMs: Date.now() - debut,
    })
    return refus('acces a l archive refuse', 403)
  }

  const autorisation = data as unknown as AutorisationArchive

  try {
    const cle = verifierCle('archiveSeance', autorisation.object_key)
    const signee = await signerLecture('archiveSeance', cle, {
      dureeSecondes: DUREE_LECTURE_SENSIBLE_S,
    })

    journaliser({
      domaine: 'archiveSeance',
      operation: 'lecture',
      statut: 'accorde',
      ressource: autorisation.recording_id,
      dureeMs: Date.now() - debut,
    })

    return json({
      url: signee.url,
      expire_dans_secondes: signee.expireDansSecondes,
      duree_secondes: autorisation.duration_seconds,
    })
  } catch (e) {
    const masque = messagePourClient(e)
    journaliser({
      domaine: 'archiveSeance',
      operation: 'lecture',
      statut: 'echec',
      ressource: autorisation.recording_id,
      classeErreur: (e as Error)?.name ?? 'inconnue',
      dureeMs: Date.now() - debut,
    })
    console.error('signature d archive impossible', {
      classe: (e as Error)?.name ?? 'inconnue',
      message: (e as Error)?.message ?? '',
    })
    return refus(masque.message, masque.statut)
  }
})
