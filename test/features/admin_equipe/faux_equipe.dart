// Le faux port de l'ecran « Equipe » (BE-2b) et ses lignes de test.

import 'package:rewayah_academy/core/equipe/modeles_equipe.dart';
import 'package:rewayah_academy/core/equipe/port_equipe.dart';

class FauxEquipe implements PortEquipe {
  FauxEquipe({
    this.missionsRendues = const <Mission>[],
    this.attributionsRendues = const <Attribution>[],
    this.invitationsRendues = const <InvitationAssocie>[],
    this.erreur,
  });

  final List<Mission> missionsRendues;
  final List<Attribution> attributionsRendues;
  final List<InvitationAssocie> invitationsRendues;
  final Exception? erreur;

  Future<T> _lire<T>(T v) async {
    if (erreur != null) throw erreur!;
    return v;
  }

  @override
  Future<List<Mission>> missions() => _lire(missionsRendues);

  @override
  Future<List<Attribution>> attributions() => _lire(attributionsRendues);

  @override
  Future<List<InvitationAssocie>> invitations() => _lire(invitationsRendues);

  @override
  Future<List<PersonneMission>> personnes() => _lire(const <PersonneMission>[
    PersonneMission(id: 'p1', nom: 'Karim', role: 'associe', cote: 'hommes'),
  ]);

  @override
  Future<List<String>> gestesOuverts() =>
      _lire(const <String>['lire', 'consigner_prevenu']);

  @override
  Future<String> creerMission({
    required String nom,
    required List<String> gestes,
    required String cle,
  }) async => 'm-nouvelle';

  @override
  Future<void> archiverMission({
    required String id,
    required String motif,
    required String cle,
  }) async {}

  @override
  Future<String> accorder({
    required String profil,
    required String mission,
    required List<String> langues,
    required List<String> etapes,
    required DateTime? debut,
    required DateTime? fin,
    required String cle,
  }) async => 'a-nouvelle';

  @override
  Future<void> retirer({
    required String attribution,
    required String motif,
    required String cle,
  }) async {}

  @override
  Future<ResultatInvitation> inviter({
    required String courriel,
    required String? nom,
    required String cle,
  }) async => const ResultatInvitation(statut: StatutInvitation.emailInvalide);

  @override
  Future<void> revoquer({
    required String id,
    required String motif,
    required String cle,
  }) async {}
}

final Attribution attributionKarim = Attribution(
  id: 'a1',
  missionId: 'm1',
  mission: 'Lecture des candidatures',
  profil: 'p1',
  nom: 'Karim',
  role: 'associe',
  perimetre: const PerimetreMission(),
  debut: DateTime.utc(2026, 11, 1),
  fin: null,
  active: true,
  retiree: false,
);

const Mission missionLecture = Mission(
  id: 'm1',
  nom: 'Lecture des candidatures',
  gestes: <String>['lire'],
  porteurs: 1,
  archivee: false,
);
