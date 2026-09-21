// Confirmer qu'une piece d'identite a bien ete deposee.
//
//   { document_id }  ->  { confirme: true }
//
// Pourquoi cette etape existe, alors qu'elle allonge le flux d'un appel.
//
// `preparer_depot_piece_identite()` cree la ligne AVANT l'envoi, parce que la
// cle doit exister pour etre signee. Une ligne creee avant l'envoi est une
// ligne qui peut n'avoir jamais d'objet : reseau coupe, application fermee,
// envoi refuse par R2. Laissee visible, elle entrerait dans la file de
// validation et l'administration ouvrirait un document inexistant.
//
// La reservation nait donc invisible, et c'est ce point d'entree qui la rend
// vivante. **Il ne croit pas le client sur parole** : il demande a R2, par un
// HEAD, si l'objet est reellement la. Sans cette verification, << j'ai fini
// d'envoyer >> ne serait qu'une affirmation, et la confirmation ne vaudrait
// pas mieux que l'absence de confirmation.
//
// Un HEAD ne rend que des en-tetes : aucun octet de piece d'identite ne
// transite par ce serveur.
//
// La cle n'est pas recue, elle est relue en base : `autoriser_lecture_piece_identite()`
// la resout depuis le `document_id` et rejoue au passage la porte de lecture,
// qui exige `admin` ou `controller`. Ce n'est pas ce qu'il faut ici -- c'est le
// DEPOSANT qui confirme -- donc la cle est reconstruite selon la convention a
// partir du document et de son profil, exactement comme la base l'a fabriquee.

import { enTetesCors, json, refus } from '../_shared/clients.ts'
import { clientService } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { cleDe } from '../_shared/r2/cles.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import { journaliser, messagePourClient, objetExiste } from '../_shared/r2/signature.ts'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (requete.method !== 'POST') {
    return refus('methode non autorisee', 405)
  }

  if (!stockageConfigure('pieceIdentite')) {
    return refus('coffre d identite non configure', 503)
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

  const document = String(corps.document_id ?? '').trim().toLowerCase()
  if (!UUID.test(document)) {
    return refus('document non precise')
  }
  if ('object_key' in corps) {
    return refus('la cle d objet est resolue par le serveur', 400)
  }

  const debut = Date.now()
  const service = clientService()

  // Quelle reservation, et pour quel profil ? Lu en base sous la cle de
  // service, mais borne aux reservations R2 non encore confirmees -- une
  // reservation appartient a celui qui l'a demandee, et personne d'autre n'a
  // de raison de la confirmer.
  const { data, error } = await service
    .from('kyc_documents')
    .select('id, profile_id, storage_backend, status, deleted_at')
    .eq('id', document)
    .eq('storage_backend', 'r2')
    .eq('status', 'pending')
    .not('deleted_at', 'is', null)
    .maybeSingle()

  if (error || !data) {
    console.error('reservation introuvable', { erreur: error?.message })
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'refuse',
      dureeMs: Date.now() - debut,
    })
    return refus('aucune reservation a confirmer', 403)
  }

  const reservation = data as { id: string; profile_id: string }

  // La cle de service contourne la RLS, elle ne remplace pas le controle :
  // seul quelqu'un qui aurait eu le droit de DEPOSER pour ce profil a le droit
  // de confirmer. La porte est la meme fonction que celle de la reservation,
  // appelee SOUS LE JETON de l'appelant -- et elle est sans effet de bord,
  // donc la rejouer ne cree rien.
  const { data: autorise, error: erreurPorte } = await compte.sql.rpc(
    'peut_deposer_piece_identite',
    { p_profile_id: reservation.profile_id },
  )
  if (erreurPorte || autorise !== true) {
    console.error('confirmation refusee : porte de depot fermee', { erreur: erreurPorte?.message })
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'refuse',
      dureeMs: Date.now() - debut,
    })
    return refus('confirmation refusee', 403)
  }

  try {
    const cle = cleDe('pieceIdentite', reservation.profile_id, reservation.id)
    if (!(await objetExiste('pieceIdentite', cle))) {
      journaliser({
        domaine: 'pieceIdentite',
        operation: 'depot',
        statut: 'refuse',
        ressource: reservation.id,
        dureeMs: Date.now() - debut,
      })
      return refus('aucun objet depose sous cette reservation', 409)
    }

    const { error: erreurConfirmation } = await service.rpc('confirmer_depot_piece_identite', {
      p_document_id: reservation.id,
    })
    if (erreurConfirmation) {
      console.error('confirmation impossible', { erreur: erreurConfirmation.message })
      return refus('confirmation refusee', 403)
    }

    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'accorde',
      ressource: reservation.id,
      dureeMs: Date.now() - debut,
    })
    return json({ confirme: true, document_id: reservation.id })
  } catch (e) {
    const masque = messagePourClient(e)
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'echec',
      ressource: reservation.id,
      classeErreur: (e as Error)?.name ?? 'inconnue',
      dureeMs: Date.now() - debut,
    })
    console.error('verification de depot impossible', {
      classe: (e as Error)?.name ?? 'inconnue',
      message: (e as Error)?.message ?? '',
    })
    return refus(masque.message, masque.statut)
  }
})
