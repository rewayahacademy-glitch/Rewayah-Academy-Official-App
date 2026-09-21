// Le stockage d'avant R2, servi par le meme chemin serveur que R2.
//
// Dix-huit pieces d'identite vivent dans le seau Supabase Storage prive `kyc`,
// pose par la migration `0004`. Elles n'ont aucune raison de disparaitre parce
// qu'un coffre R2 est arrive, et les deplacer serait une migration de donnees
// -- une operation a part, qui se decide et se mesure, pas un effet de bord
// d'un branchement.
//
// Ce fichier existe pour que le point d'entree n'ait qu'UN comportement visible
// depuis l'appelant : il demande une piece, il recoit une URL courte. Lequel des
// deux stockages a repondu est un detail d'infrastructure, lu dans
// `kyc_documents.storage_backend`.
//
// Au passage, cela corrige une divergence ancienne. Le commentaire de `0004`
// annonce un apercu << par une URL signee generee cote serveur >> ; le code
// reel (`lib/core/dossier/service_validation.dart`) la genere depuis le
// navigateur de l'administrateur, avec sa propre session. Passer par ici met le
// comportement en accord avec la decision, pour les deux stockages a la fois.

import { clientService } from '../clients.ts'

/// Le seau historique des pieces d'identite. Prive depuis sa creation (`0004`),
/// sans aucune policy d'ecriture ni de suppression.
const SEAU_HISTORIQUE = 'kyc'

/// Signe une lecture sur le stockage historique, cote serveur.
///
/// Leve si Supabase refuse : l'appelant a deja ete autorise en base, un echec
/// ici est une panne d'infrastructure et non un refus d'acces.
export async function signerLectureSupabase(
  cleObjet: string,
  dureeSecondes: number,
): Promise<string> {
  const service = clientService()
  const { data, error } = await service.storage
    .from(SEAU_HISTORIQUE)
    .createSignedUrl(cleObjet, dureeSecondes)

  if (error || !data?.signedUrl) {
    // Le message de Supabase reste dans le journal du serveur : il peut citer
    // la cle de l'objet, qui n'a pas a repartir vers le client.
    console.error('signature Supabase Storage impossible', {
      seau: SEAU_HISTORIQUE,
      classe: error?.name ?? 'inconnue',
    })
    throw new Error('stockage historique indisponible')
  }

  return data.signedUrl
}
