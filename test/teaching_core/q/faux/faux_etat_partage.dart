// Faux backend d'etat partage, et faux canal temps reel.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// LE POINT DU DOUBLE. La spec (ligne 1200) exige qu'un late joiner recupere
// l'etat courant **sans dependre de l'historique des messages realtime** :
// LiveKit n'est jamais une base de donnees. Le double separe donc franchement
// les deux chemins -- un magasin backend d'un cote, un canal sans memoire de
// l'autre -- pour qu'un test puisse vider le second et interroger le premier.

import 'dart:async';

import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';

import '../../fixtures/fixtures_etat_partage.dart';

/// Le magasin backend : **l'etat durable minimal**, un enregistrement par
/// seance.
class FauxBackendEtatPartage {
  final Map<String, SharedContentState> _parSeance =
      <String, SharedContentState>{};

  /// Le nombre de lectures du magasin, pour verifier qu'on s'en sert.
  int lectures = 0;

  /// Publie un etat. Une revision plus ancienne ou egale est ignoree.
  void publier(SharedContentState etat) {
    final SharedContentState? courant = _parSeance[etat.sessionId];
    _parSeance[etat.sessionId] = appliquerRevision(courant, etat);
  }

  /// L'etat courant d'une seance.
  SharedContentState? etatCourant(String sessionId) {
    lectures++;
    return _parSeance[sessionId];
  }

  /// Restauration apres reconnexion ou arrivee tardive.
  ///
  /// **Lit le backend, jamais l'historique realtime.**
  Future<SharedContentState?> restaurer(String sessionId) async =>
      etatCourant(sessionId);
}

/// Le canal temps reel, **sans memoire**.
///
/// Il ne rejoue rien : un abonne arrive en retard ne recoit que ce qui passe
/// apres lui. C'est la realite d'un canal de donnees, et c'est precisement
/// pourquoi la restauration ne peut pas en dependre.
class FauxCanalPedagogique {
  final StreamController<SharedContentState> _fiables =
      StreamController<SharedContentState>.broadcast();
  final StreamController<SharedContentState> _ephemeres =
      StreamController<SharedContentState>.broadcast();

  /// Les messages fiables et ordonnes.
  Stream<SharedContentState> get messagesFiables => _fiables.stream;

  /// Les messages ephemeres, perte acceptee.
  Stream<SharedContentState> get messagesEphemeres => _ephemeres.stream;

  /// Emet un paquet fiable.
  void emettreFiable(SharedContentState etat) => _fiables.add(etat);

  /// Emet un paquet ephemere.
  void emettreEphemere(SharedContentState etat) => _ephemeres.add(etat);

  /// Ferme les deux canaux. A appeler en fin de test.
  Future<void> liberer() async {
    await _fiables.close();
    await _ephemeres.close();
  }
}

/// Le reducteur d'un participant : ce que son ecran affiche.
///
/// Il applique la meme regle que le backend -- revision strictement
/// croissante -- et garde la trace des revisions **effectivement retenues**,
/// pour qu'un test puisse verifier qu'aucune page n'a recule.
class VueParticipantEtatPartage {
  SharedContentState? _courant;

  /// Les revisions retenues, dans l'ordre.
  final List<int> revisionsRetenues = <int>[];

  /// L'etat affiche.
  SharedContentState? get courant => _courant;

  /// Applique un paquet entrant.
  void appliquer(SharedContentState entrant) {
    final SharedContentState retenu = appliquerRevision(_courant, entrant);
    if (!identical(retenu, _courant)) {
      _courant = retenu;
      revisionsRetenues.add(retenu.revision);
    }
  }

  /// Pose l'etat restaure depuis le backend.
  void restaurerDepuis(SharedContentState? etat) {
    if (etat == null) return;
    appliquer(etat);
  }
}
