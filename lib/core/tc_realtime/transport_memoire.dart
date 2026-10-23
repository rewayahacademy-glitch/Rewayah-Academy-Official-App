import 'dart:async';

import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';

/// Le fil partage par les points de terminaison d'une meme seance simulee.
///
/// **C'est un double de test, et il est declare comme tel.** Il n'est employe
/// ni par un ecran, ni par un service de production : il existe pour que le
/// protocole du lot F soit prouve sans SDK, exactement comme
/// `test/features/salle_test.dart` prouve la salle avec un faux moteur.
///
/// Il vit dans `lib/` et non dans `test/` pour une seule raison : Agent Q et
/// Agent E en auront besoin pour leurs propres tests, et un double recopie
/// dans trois repertoires de test divergerait.
class BusMemoire {
  /// Cree un fil vide.
  BusMemoire();

  final List<TransportMemoire> _points = <TransportMemoire>[];

  /// Ce que le fil laisse tomber, pour eprouver la perte du canal ephemere.
  ///
  /// `null` ne perd rien. La fonction recoit le paquet et rend `true` pour le
  /// jeter. **Le canal fiable doit rester intact meme quand l'ephemere perd
  /// tout** : c'est l'invariant que la mission nomme.
  bool Function(PaquetRealtime paquet)? jeter;

  void _inscrire(TransportMemoire point) => _points.add(point);

  void _retirer(TransportMemoire point) => _points.remove(point);

  void _diffuser(
    TransportMemoire depuis,
    PaquetRealtime paquet,
    List<String> destinataires,
  ) {
    if (jeter?.call(paquet) ?? false) {
      return;
    }
    for (final TransportMemoire point in _points) {
      // Pas de retour a l'envoyeur : LiveKit ne relivre pas ses propres
      // paquets de donnees a l'emetteur, et un double qui le ferait masquerait
      // le fait que l'emetteur doit rendre son propre geste lui-meme.
      if (identical(point, depuis)) {
        continue;
      }
      if (destinataires.isNotEmpty &&
          !destinataires.contains(point.capacites.identiteLocale)) {
        continue;
      }
      point.recevoir(paquet);
    }
  }
}

/// Un point de terminaison du [BusMemoire], vu comme un transport complet.
///
/// Il honore les deux canaux, le ciblage et les capacites : c'est **le double
/// qui a toutes les capacites que le core n'a pas encore**, et c'est contre lui
/// que le lot F est ecrit et teste.
class TransportMemoire implements PortTransportDonnees {
  /// Cree un point de terminaison et l'inscrit sur [bus].
  TransportMemoire({required BusMemoire bus, required this._capacites})
    : _bus = bus {
    bus._inscrire(this);
  }

  final BusMemoire _bus;
  final CapacitesTransport _capacites;

  final StreamController<PaquetRealtime> _paquets =
      StreamController<PaquetRealtime>.broadcast();
  final StreamController<EtatTransport> _etats =
      StreamController<EtatTransport>.broadcast();

  /// Tout ce qui a ete emis par ce point, dans l'ordre. Pour les assertions.
  final List<PaquetRealtime> emis = <PaquetRealtime>[];

  @override
  DisponibiliteTransport get disponibilite => DisponibiliteTransport.complet;

  @override
  CapacitesTransport get capacites => _capacites;

  @override
  Stream<PaquetRealtime> paquets() => _paquets.stream;

  @override
  Stream<EtatTransport> etats() => _etats.stream;

  @override
  Future<void> envoyer({
    required String sujet,
    required List<int> charge,
    required CanalFiabilite canal,
    List<String> destinataires = const <String>[],
  }) async {
    if (!_capacites.peutPublierDonnees) {
      throw const EchecTransport(MotifEchecTransport.droitRefuse);
    }
    final PaquetRealtime paquet = PaquetRealtime(
      sujet: sujet,
      charge: charge,
      canal: canal,
      emetteurIdentite: _capacites.identiteLocale,
    );
    emis.add(paquet);
    _bus._diffuser(this, paquet, destinataires);
  }

  /// Livre un paquet a ce point, sans passer par le fil.
  ///
  /// C'est par la qu'un test fabrique un duplicata, un paquet hors ordre ou un
  /// paquet corrompu : ce sont des accidents de reseau, et un reseau ne se
  /// simule pas en demandant poliment a l'emetteur de les produire.
  void recevoir(PaquetRealtime paquet) {
    if (!_paquets.isClosed) {
      _paquets.add(paquet);
    }
  }

  /// Pose un etat de transport, pour eprouver reconnexion et retablissement.
  void poserEtat(EtatTransport etat) {
    if (!_etats.isClosed) {
      _etats.add(etat);
    }
  }

  @override
  Future<void> liberer() async {
    _bus._retirer(this);
    await _paquets.close();
    await _etats.close();
  }
}
