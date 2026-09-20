import 'package:rewayah_academy/core/tc_etat_partage/port_etat_partage_persistant.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';

/// Une persistance qui rend toujours le meme etat, aussi vieux soit-il.
///
/// Elle simule ce qu'`EtatPartageMemoire` ne peut pas simuler : **une lecture
/// servie par une replique en retard**. C'est la situation ou le backend, qui
/// fait autorite sur le contenu, ne fait pas autorite sur le sens du temps -- et
/// ou une restauration naive ferait reculer une classe qui a deja vu plus
/// recent.
class PersistanceFigee implements PortEtatPartagePersistant {
  /// Cree une persistance qui rend [_fige] a chaque lecture.
  PersistanceFigee(this._fige);

  final SharedContentState? _fige;

  /// Le nombre de lectures, pour prouver qu'une restauration a bien eu lieu.
  int lectures = 0;

  @override
  Future<SharedContentState?> lire(String sessionId) async {
    lectures++;
    return _fige;
  }

  @override
  Future<SharedContentState> enregistrer(SharedContentState etat) async => etat;

  @override
  Future<void> effacer(String sessionId) async {}
}

/// Une persistance en panne : toute lecture echoue.
///
/// « Rien n'est presente » et « je n'ai pas pu lire » conduisent a deux ecrans
/// differents : le port ne rend jamais un etat vide pour masquer une erreur.
class PersistanceEnPanne implements PortEtatPartagePersistant {
  /// Cree une persistance qui echoue.
  PersistanceEnPanne();

  @override
  Future<SharedContentState?> lire(String sessionId) async =>
      throw const EchecEtatPartage(MotifEchecEtatPartage.reseau);

  @override
  Future<SharedContentState> enregistrer(SharedContentState etat) async =>
      throw const EchecEtatPartage(MotifEchecEtatPartage.reseau);

  @override
  Future<void> effacer(String sessionId) async {}
}
