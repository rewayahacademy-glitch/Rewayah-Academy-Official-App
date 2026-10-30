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
  });

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
    final DateTime debut = debutsParClasse[groupeId] ?? debutUtc;
    return _horlogeA(debut);
  }

  SessionClockVM _horlogeA(DateTime debut) => SessionClockVM.depuisFenetre(
    fenetre: FenetreSeance(
      debutUtc: debut,
      finPrevueUtc: debut.add(duree),
      fenetreAcces: const Duration(minutes: 20),
      graceApresFin: const Duration(minutes: 15),
    ),
    maintenantServeurUtc: maintenant().toUtc(),
    sessionId: sessionId,
    horlogeUtilisateur: const HorlogeAffichee(
      fuseauIana: 'Europe/Paris',
      libelleVille: 'Paris',
      heureLocaleRendue: '18:00',
      dateLocaleRendue: 'Vendredi 30 octobre',
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
