/// C-10 bis et C-11 bis : un jour de la semaine ET son heure.
///
/// Une demande (ou un regroupement de demandes) peut avoir une heure
/// differente selon le jour : le serveur stocke `jours[]` et
/// `heures_locales[]` en tableaux paralleles, parce qu'une semaine de
/// changement d'heure decale certains jours et pas d'autres (meme raison que
/// `CreneauVu`, `offre_horaire.dart`). Une heure unique pour tous les jours
/// mentirait un jour sur deux : le contrat porte donc une liste
/// d'occurrences, triee par jour, sans doublon de jour, et **aucune heure
/// n'est jamais remplacee par celle du premier jour**.
library;

import 'package:flutter/foundation.dart';

/// Un jour ISO et son heure murale, dans le fuseau du contrat qui la porte.
@immutable
class OccurrenceCreneau {
  /// Cree une occurrence. [jourIso] : 1 (lundi) a 7 (dimanche) ; [heure] :
  /// 0 a 23 ; [minute] : 0 a 59.
  const OccurrenceCreneau({
    required this.jourIso,
    required this.heure,
    this.minute = 0,
  }) : assert(jourIso >= 1 && jourIso <= 7, 'un jour ISO va de 1 a 7'),
       assert(heure >= 0 && heure <= 23, 'une heure va de 0 a 23'),
       assert(minute >= 0 && minute <= 59, 'une minute va de 0 a 59');

  /// Le jour ISO, 1 pour lundi, 7 pour dimanche.
  final int jourIso;

  /// L'heure pleine, de 0 a 23.
  final int heure;

  /// Les minutes, de 0 a 59.
  final int minute;

  /// Les minutes depuis minuit : la cle de comparaison des heures.
  int get minutesDuJour => heure * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceCreneau &&
      other.jourIso == jourIso &&
      other.heure == heure &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(jourIso, heure, minute);

  @override
  String toString() => 'OccurrenceCreneau($jourIso, $heure:$minute)';
}

/// Vrai quand aucun jour n'apparait deux fois.
bool joursDistincts(Iterable<OccurrenceCreneau> occurrences) {
  final List<int> jours = <int>[
    for (final OccurrenceCreneau o in occurrences) o.jourIso,
  ];
  return jours.toSet().length == jours.length;
}

/// Les occurrences triees par jour, en liste non modifiable. Le tri ne
/// touche a aucune heure : chaque jour garde la sienne.
List<OccurrenceCreneau> occurrencesTrieesParJour(
  Iterable<OccurrenceCreneau> occurrences,
) => List<OccurrenceCreneau>.unmodifiable(
  occurrences.toList()..sort(
    (OccurrenceCreneau a, OccurrenceCreneau b) =>
        a.jourIso.compareTo(b.jourIso),
  ),
);

/// Vrai quand toutes les occurrences commencent a la meme heure (et a la
/// meme minute). Vrai aussi pour une liste vide ou d'un seul jour.
bool heuresToutesEgalesDe(List<OccurrenceCreneau> occurrences) =>
    occurrences.every(
      (OccurrenceCreneau o) =>
          o.minutesDuJour == occurrences.first.minutesDuJour,
    );
