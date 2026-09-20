import 'dart:async';

import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

/// Un port de groupes qui rend exactement ce qu'on lui donne.
///
/// Sert aux etats que le jeu de demonstration ne couvre pas : la liste vide,
/// l'echec de lecture et le chargement qui ne se termine jamais.
class FauxPortGroupes implements PortGroupes {
  /// Cree un faux port.
  const FauxPortGroupes({
    this.groupes = const <GroupSummaryVM>[],
    this.echoue = false,
    this.jamaisPret = false,
  });

  /// Ce que [mesGroupes] rendra.
  final List<GroupSummaryVM> groupes;

  /// Vrai pour simuler un echec de lecture.
  final bool echoue;

  /// Vrai pour laisser la lecture en suspens indefiniment.
  final bool jamaisPret;

  Future<T> _reponse<T>(T valeur) {
    if (jamaisPret) {
      return Completer<T>().future;
    }
    if (echoue) {
      return Future<T>.error(StateError('lecture refusee'));
    }
    return Future<T>.value(valeur);
  }

  @override
  Future<List<GroupSummaryVM>> mesGroupes() => _reponse(groupes);

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) {
    for (final GroupSummaryVM candidat in groupes) {
      if (candidat.groupeId == groupeId) {
        return _reponse<GroupSummaryVM?>(candidat);
      }
    }
    return _reponse<GroupSummaryVM?>(null);
  }
}

/// Un port du temps qui n'emet rien.
///
/// L'Espace Groupe doit s'afficher **sans attendre un tic** : ce faux prouve
/// que la page rend sa premiere image a partir de l'horloge portee par la
/// carte, et non d'un flux.
class PortHorlogeMuet implements PortHorlogeSeance {
  /// Cree un port muet.
  const PortHorlogeMuet();

  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async => null;

  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) => const Stream<SessionClockVM>.empty();

  @override
  Future<DateTime> maintenantServeurUtc() async => DateTime.utc(2026, 9, 21);
}
