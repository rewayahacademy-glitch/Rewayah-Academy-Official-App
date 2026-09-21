// Deposer une piece d'identite dans le coffre, sans jamais confier de
// credential R2 a l'application.
//
//   { profile_id?, doc_type, type_mime, taille_octets }
//     ->  { document_id, url, methode, en_tetes_exiges, expire_dans_secondes }
//
// Le client recoit une URL a usage unique, bornee a deux minutes, qui n'accepte
// qu'un PUT, qu'un type de contenu et qu'une taille -- les trois entrent dans la
// signature, donc les trois sont opposables par R2 et non par une politesse du
// client.
//
// Ce que le client ne fournit jamais :
//
//   * la cle d'objet. Elle est fabriquee par `preparer_depot_piece_identite()`
//     a partir d'un identifiant tire par la base, sous la forme
//     `identity/<profile_id>/<document_id>`. Un depot ou l'appelant choisit le
//     chemin est un depot ou l'appelant choisit d'ecraser autre chose ;
//   * son identite. Elle est lue dans le jeton ;
//   * le genre de la piece, qui decide QUI pourra l'ouvrir : le declencheur
//     `completer_kyc_document()` de `0004` l'ecrase par celui du profil.
//
// Ce que le serveur ne croit jamais sur parole : le type de contenu et la
// taille annonces. Ils sont verifies contre une liste fermee et un plafond,
// puis SIGNES -- un envoi qui annonce autre chose que ce qui a ete signe est
// refuse par R2, pas par nous.
//
// Ce point d'entree n'est encore appele par aucun ecran. Le depot Flutter
// actuel continue d'ecrire dans le seau Supabase `kyc`, et sa bascule est une
// decision d'exploitation, pas un effet de bord de ce lot.

import { enTetesCors, json, refus } from '../_shared/clients.ts'
import { appelantR2 } from '../_shared/r2/client_appelant.ts'
import { verifierCle } from '../_shared/r2/cles.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import {
  journaliser,
  messagePourClient,
  signerDepot,
  TAILLE_MAXIMALE_PIECE_OCTETS,
  TYPES_PIECE_IDENTITE,
} from '../_shared/r2/signature.ts'

const TYPES_PIECE = ['id_card', 'passport', 'residence_permit', 'other']

interface PreparationDepot {
  document_id: string
  object_key: string
}

Deno.serve(async (requete: Request) => {
  if (requete.method === 'OPTIONS') {
    return new Response('ok', { headers: enTetesCors })
  }
  if (requete.method !== 'POST') {
    return refus('methode non autorisee', 405)
  }

  if (!stockageConfigure('pieceIdentite')) {
    // Etat normal du produit tant que le trousseau n'est pas pose sur le
    // serveur. Le dire franchement vaut mieux qu'une erreur de signature
    // illisible.
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

  if ('object_key' in corps) {
    return refus('la cle d objet est fabriquee par le serveur', 400)
  }

  const typePiece = String(corps.doc_type ?? '').trim()
  if (!TYPES_PIECE.includes(typePiece)) {
    return refus('type de piece inconnu')
  }

  const typeMime = String(corps.type_mime ?? '').trim().toLowerCase()
  if (!TYPES_PIECE_IDENTITE.includes(typeMime)) {
    return refus('type de contenu refuse')
  }

  const taille = Number(corps.taille_octets ?? 0)
  if (!Number.isInteger(taille) || taille <= 0 || taille > TAILLE_MAXIMALE_PIECE_OCTETS) {
    return refus('taille annoncee invalide')
  }

  // Facultatif : un tuteur depose pour un enfant de son foyer. La base
  // reverifie la relation ; ce qui arrive ici n'est qu'une demande.
  const profilVise = corps.profile_id === undefined || corps.profile_id === null
    ? null
    : String(corps.profile_id).trim()

  const debut = Date.now()

  const { data, error } = await compte.sql.rpc('preparer_depot_piece_identite', {
    p_profile_id: profilVise,
    p_doc_type: typePiece,
  })

  if (error || !data) {
    console.error('preparation de depot refusee', { erreur: error?.message })
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'refuse',
      dureeMs: Date.now() - debut,
    })
    return refus('depot refuse', 403)
  }

  const preparation = data as unknown as PreparationDepot

  try {
    const cle = verifierCle('pieceIdentite', preparation.object_key)
    const signee = await signerDepot('pieceIdentite', cle, {
      typeMime,
      tailleOctets: taille,
      typesAutorises: TYPES_PIECE_IDENTITE,
      tailleMaximaleOctets: TAILLE_MAXIMALE_PIECE_OCTETS,
    })

    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'accorde',
      ressource: preparation.document_id,
      dureeMs: Date.now() - debut,
    })

    return json({
      document_id: preparation.document_id,
      url: signee.url,
      methode: 'PUT',
      // Le client DOIT renvoyer ces en-tetes a l'identique : ils sont signes.
      en_tetes_exiges: signee.enTetesExiges,
      expire_dans_secondes: signee.expireDansSecondes,
    })
  } catch (e) {
    const masque = messagePourClient(e)
    journaliser({
      domaine: 'pieceIdentite',
      operation: 'depot',
      statut: 'echec',
      ressource: preparation.document_id,
      classeErreur: (e as Error)?.name ?? 'inconnue',
      dureeMs: Date.now() - debut,
    })
    console.error('signature de depot impossible', {
      classe: (e as Error)?.name ?? 'inconnue',
      message: (e as Error)?.message ?? '',
    })
    return refus(masque.message, masque.statut)
  }
})
