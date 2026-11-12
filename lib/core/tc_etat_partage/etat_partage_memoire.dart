import 'port_etat_partage_persistant.dart';
import 'shared_content_state.dart';

/// Le double local de [PortEtatPartagePersistant], en memoire du processus.
///
/// **Ce n'est pas une implementation, c'est un bouchon declare.** La table
/// `session_shared_content` n'existe pas : la migration est interdite en phase
/// parallele (decision D-12) et la demande SQL est ecrite dans
/// `TC_CONTRACT_REQUEST_F.md`. Ce double permet au lot F d'etre construit et
/// **prouve** entre-temps ; il ne survit ni a un redemarrage, ni a un second
/// appareil, ni a un second processus.
///
/// Ce qu'il reproduit fidelement, et c'est tout ce qu'on lui demande :
/// **le refus d'une revision qui ne progresse pas**. C'est la contrainte que
/// la base devra tenir, et l'ecrire ici permet de tester des maintenant le
/// comportement de l'appelant quand il perd une course.
class EtatPartageMemoire implements PortEtatPartagePersistant {
  /// Cree un magasin vide.
  EtatPartageMemoire();

  final Map<String, SharedContentState> _parSeance = <String, SharedContentState>{};

  /// Le nombre d'ecritures acceptees, pour les tests d'ordre d'appel.
  int ecritures = 0;

  @override
  Future<SharedContentState?> lire(String sessionId) async =>
      _parSeance[sessionId];

  @override
  Future<SharedContentState> enregistrer(SharedContentState etat) async {
    final SharedContentState? stocke = _parSeance[etat.sessionId];
    if (stocke != null && etat.revision <= stocke.revision) {
      throw EchecEtatPartage(
        MotifEchecEtatPartage.revisionObsolete,
        revisionStockee: stocke.revision,
      );
    }
    _parSeance[etat.sessionId] = etat;
    ecritures++;
    return etat;
  }

  @override
  Future<void> effacer(String sessionId) async {
    _parSeance.remove(sessionId);
  }
}
