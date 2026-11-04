/// SNT (03/11/2026) : les seances reportees, et la nouvelle date que la
/// direction fixe (decision du directeur du 03/11 : une seance ou aucun
/// enseignant n'a rejoint la salle a T+30 est reportee, puis tenue avec
/// l'enseignant de la classe a une nouvelle date).
///
/// Le serveur decide de tout : il pose le report (passage de chaque minute),
/// cree la nouvelle seance avec le titulaire et la meme duree, refuse un
/// chevauchement de l'enseignant (le refus nomme de C1). L'ecran ne fait que
/// dire.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creation_classe_refusee.dart' show ConflitHoraire;

/// Une seance reportee, sans nouvelle date.
@immutable
class SeanceReportee {
  /// Cree la ligne.
  const SeanceReportee({
    required this.id,
    required this.seanceId,
    required this.classe,
    required this.debut,
    required this.fin,
    required this.fuseau,
    required this.enseignant,
  });

  /// L'identifiant du report (la ligne `seances_reportees`).
  final String id;

  /// La seance non tenue.
  final String seanceId;

  /// Le nom de la classe.
  final String classe;

  /// Le debut prevu de la seance non tenue (UTC).
  final DateTime debut;

  /// Sa fin prevue (UTC) : la nouvelle seance garde cette duree.
  final DateTime fin;

  /// Le fuseau IANA de la classe.
  final String fuseau;

  /// Le nom de l'enseignant de la classe ; vide si le serveur ne le dit pas.
  final String enseignant;

  /// La duree de la seance, que la nouvelle garde.
  Duration get duree => fin.difference(debut);
}

/// Pourquoi le serveur a refuse la nouvelle date.
enum MotifNouvelleDateRefusee {
  /// L'enseignant a deja une seance a ce moment.
  chevauchement,

  /// La date n'est pas a venir.
  datePassee,

  /// La nouvelle date est deja fixee (un autre geste, un autre appareil).
  dejaFixee,

  /// La classe est close.
  classeClose,

  /// La personne connectee ne peut pas fixer de date.
  nonAutorisee,

  /// Un refus que le client ne connait pas.
  inconnu,
}

/// Le refus du serveur, en motif ferme ; [conflit] nomme la seance en
/// conflit quand le serveur la donne.
class NouvelleDateRefusee implements Exception {
  /// Cree le refus.
  const NouvelleDateRefusee(this.motif, {this.conflit});

  /// Le motif.
  final MotifNouvelleDateRefusee motif;

  /// La seance en conflit, lue dans le DETAIL (C1) ; nulle sinon.
  final ConflitHoraire? conflit;

  @override
  String toString() => 'NouvelleDateRefusee(${motif.name})';
}

/// Le port.
abstract interface class PortSeancesReportees {
  /// Les seances reportees sans nouvelle date (100 au plus, les plus
  /// anciennes d'abord).
  Future<List<SeanceReportee>> lister();

  /// Fixe la nouvelle date de [reportId] a [debut] ; rend l'identifiant de
  /// la nouvelle seance. Leve [NouvelleDateRefusee] sur un refus du serveur.
  Future<String> fixer({required String reportId, required DateTime debut});
}

/// Le port : absent tant que `main.dart` ne le pose pas ; sans lui, la
/// section n'est pas montree.
final Provider<PortSeancesReportees?> portSeancesReporteesProvider =
    Provider<PortSeancesReportees?>((Ref _) => null);

/// Les seances reportees ; `null` sans port.
final FutureProvider<List<SeanceReportee>?> seancesReporteesProvider =
    FutureProvider<List<SeanceReportee>?>((Ref ref) {
      final PortSeancesReportees? port = ref.watch(
        portSeancesReporteesProvider,
      );
      if (port == null) return Future<List<SeanceReportee>?>.value();
      return port.lister();
    }, retry: (int _, Object _) => null);
