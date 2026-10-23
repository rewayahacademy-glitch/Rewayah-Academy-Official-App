import 'dart:async';

import 'package:rewayah_academy/core/appairage/statut_code_appairage.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';

/// Le port de statut de code, en memoire (tests du lot D uniquement).
class FauxStatutCode implements PortStatutCodeAppairage {
  /// Le code vivant rendu a l'entree ; `null` : aucun.
  CodeVivant? vivant;

  /// Ce que [codeVivant] jette.
  Object? erreurVivant;

  /// Le statut rendu par [statut].
  StatutCode statutRendu = StatutCode.actif;

  /// Ce que [statut] jette.
  Object? erreurStatut;

  /// Nombre de lectures de statut.
  int lectures = 0;

  /// Tant qu'il n'est pas complete, [statut] ne rend pas la main.
  Completer<void>? attente;

  @override
  Future<CodeVivant?> codeVivant(String eleveId) async {
    final Object? erreur = erreurVivant;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return vivant;
  }

  @override
  Future<StatutCode> statut({
    required String eleveId,
    required DateTime expireA,
    required DateTime maintenant,
  }) async {
    lectures++;
    final Completer<void>? verrou = attente;
    if (verrou != null) {
      await verrou.future;
    }
    final Object? erreur = erreurStatut;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return statutRendu;
  }
}

/// Un reseau que le test coupe et retablit.
class ReseauPilote implements ServiceReseau {
  final StreamController<bool> _flux = StreamController<bool>.broadcast();
  bool _horsLigne = false;

  /// Coupe ou retablit le reseau.
  void poser({required bool horsLigne}) {
    _horsLigne = horsLigne;
    _flux.add(horsLigne);
  }

  @override
  Stream<bool> horsLigne() async* {
    yield _horsLigne;
    yield* _flux.stream;
  }
}

/// Une horloge que le test avance a la main.
class HorlogePilotee {
  /// Cree l'horloge a [depart].
  HorlogePilotee(this.maintenant);

  /// L'instant courant.
  DateTime maintenant;

  /// Avance de [duree].
  void avancer(Duration duree) => maintenant = maintenant.add(duree);

  /// Lit l'instant.
  DateTime lire() => maintenant;
}
