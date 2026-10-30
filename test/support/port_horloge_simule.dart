// Mes classes (30/10/2026) : un port d'horloge dont le serveur suit une heure
// simulee, pour prouver « Rejoindre » a T-20 pile sans recharger.

import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

/// Le serveur simule : une seance de [duree] a [debutUtc], fenetre de 20 min
/// (`join_window_minutes` lu en production le 30/10/2026), grace de 15 min.
/// [maintenant] est l'heure serveur, avancee par le test ; [lectures] compte
/// les appels a `horloge_classe`.
class PortHorlogeSimule implements PortHorlogeSeance {
  /// Cree le serveur simule.
  PortHorlogeSimule({
    required this.debutUtc,
    required this.maintenant,
    this.duree = const Duration(minutes: 45),
    this.sessionId = 'seance-simulee',
    this.debutsParClasse = const <String, DateTime>{},
    this.creneaux = const <(DateTime, String)>[],
  });

  /// Les creneaux d'une Classe a plusieurs creneaux par semaine (debut UTC,
  /// date locale rendue) : comme `horloge_classe`, le serveur rend le plus
  /// proche qui n'est pas fini, grace comprise. Vide : [debutUtc].
  final List<(DateTime, String)> creneaux;

  /// Le debut propre a une Classe, sinon [debutUtc].
  final Map<String, DateTime> debutsParClasse;

  /// Le debut de la seance.
  final DateTime debutUtc;

  /// Sa duree prevue.
  final Duration duree;

  /// L'identifiant de seance rendu.
  final String? sessionId;

  /// L'heure serveur.
  DateTime Function() maintenant;

  /// Les lectures faites.
  int lectures = 0;

  SessionClockVM _horloge([String? groupeId]) {
    final DateTime m = maintenant().toUtc();
    final List<(DateTime, String)> restants =
        <(DateTime, String)>[
          for (final (DateTime, String) c in creneaux)
            if (c.$1.add(duree + const Duration(minutes: 15)).isAfter(m)) c,
        ]..sort(
          ((DateTime, String) a, (DateTime, String) b) => a.$1.compareTo(b.$1),
        );
    if (restants.isNotEmpty) {
      return _horlogeA(restants.first.$1, restants.first.$2);
    }
    final DateTime debut = debutsParClasse[groupeId] ?? debutUtc;
    return _horlogeA(debut);
  }

  SessionClockVM _horlogeA(
    DateTime debut, [
    String dateRendue = 'Vendredi 30 octobre',
  ]) => SessionClockVM.depuisFenetre(
    fenetre: FenetreSeance(
      debutUtc: debut,
      finPrevueUtc: debut.add(duree),
      fenetreAcces: const Duration(minutes: 20),
      graceApresFin: const Duration(minutes: 15),
    ),
    maintenantServeurUtc: maintenant().toUtc(),
    sessionId: sessionId,
    horlogeUtilisateur: HorlogeAffichee(
      fuseauIana: 'Europe/Paris',
      libelleVille: 'Paris',
      heureLocaleRendue: '18:00',
      dateLocaleRendue: dateRendue,
    ),
  );

  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async {
    lectures++;
    return _horloge(groupeId);
  }

  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) async* {
    lectures++;
    yield _horloge(groupeId);
  }

  @override
  Future<DateTime> maintenantServeurUtc() async => maintenant().toUtc();
}
