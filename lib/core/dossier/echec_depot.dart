// La cause d'un depot de fichier qui n'a pas abouti (N4, regle K-59), pour la
// piece d'identite ET la photo du candidat (PE-B10, 20/11/2026).
//
// L'ecran du depot disait une seule phrase pour tous les echecs. Le seau
// `kyc` borne les formats et la taille (migration 20261108400000) : un refus
// de format ou de taille n'est pas une panne passagere, et « Reessayez dans un
// instant » ferait reessayer en vain. PE-B10 (lu dans les journaux de
// production, 14-20/11/2026) : les seuls echecs serveur de la semaine sont des
// 544, 504, 500, 520, 429 (seau) et des 401, 403 (fonction `kyc-confirme`),
// tous tombes dans la meme phrase. On lit donc la reponse pour dire la cause
// vraie, et le geste utile ; une panne passagere est d'abord reessayee seule
// (`depot_resilient.dart`).

import 'package:supabase_flutter/supabase_flutter.dart';

/// Pourquoi un depot n'a pas abouti.
enum CauseEchecDepot {
  /// Le seau refuse ce type de fichier (HTTP 415).
  format,

  /// Le fichier depasse le plafond du seau (HTTP 413).
  taille,

  /// FN-101 : le serveur a lu le debut du fichier, qui ne correspond pas a
  /// son type (fonction `kyc-confirme`, HTTP 422).
  contenu,

  /// La requete n'a pas atteint Rewayah : connexion coupee ou trop lente.
  reseau,

  /// Rewayah a repondu qu'il ne pouvait pas traiter la demande pour le
  /// moment (HTTP 429, 5xx, 520 a 544) : passager, a reessayer plus tard.
  indisponible,

  /// La session du compte n'est plus valable (HTTP 401, jeton expire ou
  /// absent) : reessayer ne sert a rien, il faut se reconnecter.
  session,

  /// Rewayah refuse ce depot pour ce compte (HTTP 403, droit refuse par la
  /// base, `42501`) : reessayer ne sert a rien, la direction doit regarder.
  refuse,

  /// Toute autre cause : on ne pretend pas la connaitre.
  autre,
}

/// Vrai pour une cause qu'un nouvel essai peut lever seul.
bool causePassagere(CauseEchecDepot cause) =>
    cause == CauseEchecDepot.reseau || cause == CauseEchecDepot.indisponible;

/// Le compte n'a plus de session au moment du depot.
class SessionAbsente implements Exception {
  /// Cree l'erreur.
  const SessionAbsente();

  @override
  String toString() => 'SessionAbsente';
}

/// FN-101 : le contenu de la piece deposee ne correspond pas a son type, dit
/// par la fonction `kyc-confirme` (HTTP 422). La ligne `kyc_documents` n'est
/// pas inseree : la policy exige la confirmation (migration 20261110800000).
class ContenuPieceNonConforme implements Exception {
  /// Cree l'erreur.
  const ContenuPieceNonConforme();
}

CauseEchecDepot? _depuisStatut(int statut) {
  if (statut == 401) return CauseEchecDepot.session;
  if (statut == 403) return CauseEchecDepot.refuse;
  if (statut == 413) return CauseEchecDepot.taille;
  if (statut == 415) return CauseEchecDepot.format;
  if (statut == 422) return CauseEchecDepot.contenu;
  if (statut == 408 || statut == 429 || statut >= 500) {
    return CauseEchecDepot.indisponible;
  }
  return null;
}

bool _jeton(String detail) =>
    detail.contains('jwt') ||
    detail.contains('invalid token') ||
    detail.contains('token expired') ||
    detail.contains('not authenticated');

/// La cause lue dans l'erreur levee par le depot.
CauseEchecDepot causeEchecDepot(Object erreur) {
  if (erreur is ContenuPieceNonConforme) return CauseEchecDepot.contenu;
  if (erreur is SessionAbsente || erreur is AuthException) {
    return CauseEchecDepot.session;
  }
  if (erreur is StorageException) {
    final String code = erreur.statusCode ?? '';
    final String detail = '${erreur.error ?? ''} ${erreur.message}'
        .toLowerCase();
    if (detail.contains('mime')) return CauseEchecDepot.format;
    if (detail.contains('too large')) return CauseEchecDepot.taille;
    if (_jeton(detail)) return CauseEchecDepot.session;
    if (detail.contains('row-level security') ||
        detail.contains('unauthorized')) {
      return CauseEchecDepot.refuse;
    }
    // Sans reponse HTTP, `storage_client` range le type de l'erreur dans
    // `statusCode` (ClientException, SocketException, TimeoutException...).
    final int? statut = int.tryParse(code);
    if (statut == null) return CauseEchecDepot.reseau;
    return _depuisStatut(statut) ?? CauseEchecDepot.autre;
  }
  if (erreur is FunctionException) {
    // `FunctionsFetchException` : aucune reponse n'est arrivee (statut 0).
    if (erreur.status == 0) return CauseEchecDepot.reseau;
    return _depuisStatut(erreur.status) ?? CauseEchecDepot.autre;
  }
  if (erreur is PostgrestException) {
    final String code = erreur.code ?? '';
    final String detail = erreur.message.toLowerCase();
    if (code == '42501' || detail.contains('row-level security')) {
      return CauseEchecDepot.refuse;
    }
    if (code.startsWith('PGRST30') || _jeton(detail)) {
      return CauseEchecDepot.session;
    }
    final int? statut = int.tryParse(code);
    if (statut != null) {
      return _depuisStatut(statut) ?? CauseEchecDepot.autre;
    }
    return CauseEchecDepot.autre;
  }
  final String type = erreur.runtimeType.toString();
  if (type.contains('ClientException') ||
      type.contains('SocketException') ||
      type.contains('TimeoutException')) {
    return CauseEchecDepot.reseau;
  }
  return CauseEchecDepot.autre;
}

/// Vrai quand [erreur] dit que l'objet existe deja sous cette cle : un
/// nouvel essai d'envoi apres une reponse perdue. Le premier envoi a donc
/// abouti ; on ne cree pas un second fichier.
bool dejaDepose(Object erreur) {
  if (erreur is StorageException) {
    final String detail = '${erreur.error ?? ''} ${erreur.message}'
        .toLowerCase();
    return erreur.statusCode == '409' ||
        detail.contains('duplicate') ||
        detail.contains('already exists');
  }
  if (erreur is PostgrestException) return erreur.code == '23505';
  return false;
}
