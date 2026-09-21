// Ouvrir une piece d'identite, sans jamais donner au client autre chose qu'une
// URL qui expire.
//
//   { document_id }  ->  { url, expire_dans_secondes }
//
// L'ordre des operations est le sujet entier de ce fichier :
//
//   1. l'appelant est identifie par SON jeton, jamais par un identifiant recu
//      dans le corps de la requete ;
//   2. `autoriser_lecture_piece_identite()` tranche en base, la ou le role, la
//      RLS, le cloisonnement par genre et le journal d'audit sont sous la main.
//      Elle ecrit la trace AVANT que quoi que ce soit ne soit signe ;
//   3. et seulement alors, la couche R2 signe une URL de soixante secondes.
//
// **Une URL signee n'est pas une autorisation.** C'est ce que l'etape 2
// produit. Inverser ces deux etapes donnerait un point d'acces qui signe
// d'abord et demande ensuite, ce qui n'est pas un controle mais une politesse.
//
// Ce que ce point d'entree n'accepte pas : une cle d'objet. Le client nomme un
// DOCUMENT, la base resout la cle. Un `object_key` recu du client permettrait
// de designer n'importe quel objet du coffre, et aucune verification faite plus
// tard ne rattraperait cela.
//
// Il sert les deux stockages, et c'est temporaire. Les dix-huit pieces deja
// deposees vivent dans le seau Supabase `kyc` ; les suivantes iront dans
// `rewayah-identity-vault`. `storage_backend` dit laquelle, et la bascule
// complete reste une decision d'exploitation.

import { enTetesCors, json, refus } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { verifierCle } from '../_shared/r2/cles.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import { signerLectureSupabase } from '../_shared/r2/stockage_historique.ts'
import {
  DUREE_LECTURE_SENSIBLE_S,
  journaliser,
  messagePourClient,
  signerLecture,
} from '../_shared/r2/signature.ts'

interface AutorisationPiece {
  document_id: string
  profile_id: string
  object_key: string
  storage_backend: string
  doc_type: string
}

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (requete.method !== 'POST') {
    return refus('methode non autorisee', 405)
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

  const document = String(corps.document_id ?? '').trim()
  if (!document) {
    return refus('document non precise')
  }
  // Un `object_key` dans le corps est toujours une tentative de designer un
  // objet directement. On le refuse franchement plutot que de l'ignorer : le
  // silence laisserait croire que la cle a ete prise en compte.
  if ('object_key' in corps) {
    return refus('la cle d objet est resolue par le serveur', 400)
  }

  const debut = Date.now()

  // La porte, l'audit et la resolution de la cle : tout en un appel, sous
  // l'identite de l'appelant pour que `audit_logs` porte le bon acteur.
  const { data, error } = await compte.sql.rpc('autoriser_lecture_piece_identite', {
    p_document_id: document,
  })

  if (error || !data) {
    // Le motif exact reste dans les journaux. Un appelant qui tente un dossier
    // qui n'est pas le sien n'a pas a apprendre s'il existe.
    console.error('lecture de piece refusee', { erreur: error?.message })
    // L'identifiant n'entre pas dans la trace d'un refus : il vient du client
    // et n'a pas ete reconnu. Journaliser une valeur non reconnue, c'est
    // laisser un appelant ecrire dans nos journaux.
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'lecture',
      statut: 'refuse',
      dureeMs: Date.now() - debut,
    })
    return refus('acces a la piece refuse', 403)
  }

  const autorisation = data as unknown as AutorisationPiece

  try {
    if (autorisation.storage_backend === 'r2') {
      if (!stockageConfigure('pieceIdentite')) {
        return refus('coffre d identite non configure', 503)
      }
      // La cle vient de la base, mais elle est confrontee a la convention avant
      // d'etre signee : une ligne ecrite par un chemin qu'on ne connait pas
      // encore ne doit pas pouvoir faire signer n'importe quoi.
      const cle = verifierCle('pieceIdentite', autorisation.object_key)
      const signee = await signerLecture('pieceIdentite', cle, {
        dureeSecondes: DUREE_LECTURE_SENSIBLE_S,
      })
      journaliser({
        domaine: 'pieceIdentite',
        operation: 'lecture',
        statut: 'accorde',
        ressource: autorisation.document_id,
        dureeMs: Date.now() - debut,
      })
      return json({ url: signee.url, expire_dans_secondes: signee.expireDansSecondes })
    }

    // Stockage historique : le seau Supabase `kyc`. La signature passe par le
    // client de service, et c'est ce qui deplace enfin cette generation du
    // navigateur de l'administrateur vers le serveur, comme `0004` l'annoncait.
    const url = await signerLectureSupabase(autorisation.object_key, DUREE_LECTURE_SENSIBLE_S)
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'lecture',
      statut: 'accorde',
      ressource: autorisation.document_id,
      dureeMs: Date.now() - debut,
    })
    return json({ url, expire_dans_secondes: DUREE_LECTURE_SENSIBLE_S })
  } catch (e) {
    const masque = messagePourClient(e)
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'lecture',
      statut: 'echec',
      ressource: autorisation.document_id,
      classeErreur: (e as Error)?.name ?? 'inconnue',
      dureeMs: Date.now() - debut,
    })
    console.error('signature de piece impossible', {
      classe: (e as Error)?.name ?? 'inconnue',
      message: (e as Error)?.message ?? '',
    })
    return refus(masque.message, masque.statut)
  }
})
