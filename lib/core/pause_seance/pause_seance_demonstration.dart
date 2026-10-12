// DEMONSTRATION de la pause programmee (LIVE-PAUSE-01). **Fictive, en memoire.**
//
// Branchee uniquement par `portPauseSeanceSelon(demo: true)`, c'est-a-dire sous
// `PLAYGROUND=true`, que le deploiement force a `false`. Elle suit les memes
// regles que le contrat : un reglage versionne, une pause horodatee a son
// debut et a sa fin, jamais une donnee de presence.

import 'port_pause_seance.dart';

/// La pause de demonstration, avec une horloge injectable.
class PauseSeanceDemonstration implements PortPauseSeance {
  /// Cree la demonstration ; [maintenant] rend l'instant UTC courant.
  PauseSeanceDemonstration({DateTime Function()? maintenant})
    : _maintenant = maintenant ?? (() => DateTime.now().toUtc());

  final DateTime Function() _maintenant;

  int _version = 1;
  ReglagePause _reglage = const ReglagePause(
    actif: true,
    apresMinutes: 30,
    dureeMinutes: 10,
    version: 'demo-v1',
    peutModifier: true,
  );
  final Map<String, String> _cles = <String, String>{};
  final Map<String, PauseSeance> _seances = <String, PauseSeance>{};

  @override
  Future<ReglagePause> reglage(String groupeId) async => _reglage;

  @override
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  }) async {
    final String empreinte = '$actif/$apresMinutes/$dureeMinutes';
    if (_cles[cleIdempotence] == empreinte) return _reglage;
    if (versionAttendue != _reglage.version) {
      throw const ReglagePauseObsolete();
    }
    _cles[cleIdempotence] = empreinte;
    _version++;
    return _reglage = ReglagePause(
      actif: actif,
      apresMinutes: apresMinutes,
      dureeMinutes: dureeMinutes,
      version: 'demo-v$_version',
      peutModifier: true,
    );
  }

  PauseSeance _courante(String seanceId) =>
      _seances[seanceId] ??
      PauseSeance(
        statut: _reglage.actif ? StatutPause.programmee : StatutPause.nonPrevue,
        dureePrevueMinutes: _reglage.dureeMinutes,
        debutPrevuUtc: _maintenant().add(
          Duration(minutes: _reglage.apresMinutes),
        ),
        peutPiloter: true,
      );

  @override
  Future<PauseSeance> etat(String seanceId) async => _courante(seanceId);

  @override
  Future<PauseSeance> demarrer({
    required String seanceId,
    required String cleIdempotence,
  }) async {
    final PauseSeance p = _courante(seanceId);
    if (p.statut == StatutPause.enCours) return p;
    return _seances[seanceId] = PauseSeance(
      statut: StatutPause.enCours,
      dureePrevueMinutes: p.dureePrevueMinutes,
      debutPrevuUtc: p.debutPrevuUtc,
      debutUtc: _maintenant(),
      peutPiloter: true,
    );
  }

  @override
  Future<PauseSeance> terminer({
    required String seanceId,
    required String cleIdempotence,
  }) async {
    final PauseSeance p = _courante(seanceId);
    if (p.statut != StatutPause.enCours) return p;
    return _seances[seanceId] = PauseSeance(
      statut: StatutPause.prise,
      dureePrevueMinutes: p.dureePrevueMinutes,
      debutPrevuUtc: p.debutPrevuUtc,
      debutUtc: p.debutUtc,
      finUtc: _maintenant(),
      peutPiloter: true,
    );
  }
}
