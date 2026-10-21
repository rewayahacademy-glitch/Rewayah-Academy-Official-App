// Double du port des seances du foyer (contrat K2), horloge serveur figee.
//
// PROPRIETE : coordinateur (`test/fixtures/tuteur/`). Aucune ligne de
// production : les valeurs de fenetre (20 min) et de grace (15 min) ci-dessous
// imitent ce que le serveur rend, elles ne sont une regle nulle part.

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

/// L'instant serveur fige des tests du role Tuteur : lundi 21 septembre 2026,
/// 16 h UTC. Jamais `DateTime.now()` dans un test de temps.
final DateTime instantServeurFige = DateTime.utc(2026, 9, 21, 16);

/// Une heure rendue fictive, comme `horloge_seance()` la rendrait.
HorlogeAffichee heureRendue(
  String fuseauIana,
  String ville,
  String heure, {
  String date = 'Lundi 21 septembre',
}) => HorlogeAffichee(
  fuseauIana: fuseauIana,
  libelleVille: ville,
  heureLocaleRendue: heure,
  dateLocaleRendue: date,
);

/// Une seance fictive, avec ou sans horloge serveur.
///
/// [avecHorloge] faux simule l'absence d'horloge serveur : ni fenetre ni heure
/// rendue, donc `horaireIncertain` des que le statut ne tranche pas.
SeanceFamille seanceFictive({
  String seanceId = 's1',
  String eleveId = 'foyer-a-eleve-1',
  required DateTime debutUtc,
  Duration duree = const Duration(minutes: 45),
  StatutSeance? statut = StatutSeance.planifiee,
  bool avecHorloge = true,
  Duration ouvertureAvantDebut = const Duration(minutes: 20),
  Duration grace = const Duration(minutes: 15),
  HorlogeAffichee? heureFoyer,
  HorlogeAffichee? heureGroupe,
  String prenomEnseignant = 'Enseignant X',
}) => SeanceFamille(
  seanceId: seanceId,
  eleveId: eleveId,
  debutUtc: debutUtc,
  finPrevueUtc: debutUtc.add(duree),
  statutServeur: statut,
  fenetre: avecHorloge
      ? FenetreSeance(
          debutUtc: debutUtc,
          finPrevueUtc: debutUtc.add(duree),
          fenetreAcces: ouvertureAvantDebut,
          graceApresFin: grace,
        )
      : null,
  heureFoyer: avecHorloge ? heureFoyer : null,
  heureGroupe: avecHorloge ? heureGroupe : null,
  enseignant: EnseignantSeance(prenom: prenomEnseignant),
);

/// Le port des seances, en memoire.
class FauxSeancesFamille implements PortSeancesFamille {
  /// Cree le faux.
  FauxSeancesFamille({
    this.seances = const <SeanceFamille>[],
    DateTime? maintenant,
  }) : maintenant = maintenant ?? instantServeurFige;

  /// Les seances du foyer.
  List<SeanceFamille> seances;

  /// L'instant serveur rendu. `null` simule l'horloge serveur absente.
  DateTime? maintenant;

  /// Ce que la prochaine lecture doit jeter.
  Object? erreurAJeter;

  void _peutEchouer() {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  DateTime get _reference => maintenant ?? instantServeurFige;

  @override
  Future<SeanceFamille?> prochaine(String eleveId) async {
    _peutEchouer();
    return prochaineParmi(seances, eleveId: eleveId, referenceUtc: _reference);
  }

  @override
  Future<SeanceFamille?> derniere(String eleveId) async {
    _peutEchouer();
    return derniereParmi(seances, eleveId: eleveId, referenceUtc: _reference);
  }

  @override
  Future<List<SeanceFamille>> historique({
    String? eleveId,
    DateTimeRange? periode,
  }) async {
    _peutEchouer();
    return seances
        .where((SeanceFamille s) => eleveId == null || s.eleveId == eleveId)
        .toList();
  }

  @override
  Future<SeanceFamille?> seance(String seanceId, {String? eleveId}) async {
    _peutEchouer();
    for (final SeanceFamille s in seances) {
      if (s.seanceId == seanceId && (eleveId == null || s.eleveId == eleveId)) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  }) async => throw const CapaciteIndisponible('DB-CRS-03');

  @override
  Future<DateTime> maintenantServeurUtc() async {
    final DateTime? instant = maintenant;
    if (instant == null) {
      throw const CapaciteIndisponible('DB-TRV-07');
    }
    return instant;
  }

  @override
  Stream<SeanceFamille> suivre(String seanceId, {String? eleveId}) async* {
    final SeanceFamille? lue = await seance(seanceId, eleveId: eleveId);
    if (lue == null) {
      throw SeanceIntrouvable(seanceId);
    }
    yield lue;
  }
}
