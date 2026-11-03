// La cause d'un depot de piece qui n'a pas abouti (N4, regle K-59).
//
// L'ecran du depot disait une seule phrase pour tous les echecs. Le seau
// `kyc` borne desormais les formats et la taille (migration 20261108400000) :
// un refus de format ou de taille n'est plus une panne passagere, et
// « Reessayez dans un instant » ferait reessayer en vain. On lit donc la
// reponse du stockage pour dire la cause et le geste utile.

import 'package:supabase_flutter/supabase_flutter.dart';

/// Pourquoi un depot n'a pas abouti.
enum CauseEchecDepot {
  /// Le seau refuse ce type de fichier (HTTP 415).
  format,

  /// Le fichier depasse le plafond du seau (HTTP 413).
  taille,

  /// La requete n'a pas atteint le serveur : connexion coupee.
  reseau,

  /// Toute autre cause : on ne pretend pas la connaitre.
  autre,
}

/// La cause lue dans l'erreur levee par le depot.
CauseEchecDepot causeEchecDepot(Object erreur) {
  if (erreur is StorageException) {
    final String code = erreur.statusCode ?? '';
    final String detail = '${erreur.error ?? ''} ${erreur.message}'
        .toLowerCase();
    if (code == '415' || detail.contains('mime')) return CauseEchecDepot.format;
    if (code == '413' || detail.contains('too large')) {
      return CauseEchecDepot.taille;
    }
    // Sans reponse HTTP, `storage_client` range le type de l'erreur dans
    // `statusCode` (ClientException, SocketException...).
    if (int.tryParse(code) == null) return CauseEchecDepot.reseau;
    return CauseEchecDepot.autre;
  }
  final String type = erreur.runtimeType.toString();
  if (type.contains('ClientException') || type.contains('SocketException')) {
    return CauseEchecDepot.reseau;
  }
  return CauseEchecDepot.autre;
}
