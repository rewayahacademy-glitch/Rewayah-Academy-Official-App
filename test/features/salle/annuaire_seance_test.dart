// Directeur, test en production du 26/10/2026 (09:15) : le jeton LiveKit ne
// porte aucun nom ; l'annuaire de la seance nomme chaque participant et
// donne sa photo, l'identite technique n'est jamais un nom.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/annuaire_seance.dart';

PresenceParticipant _ligne(String profil, String prenom, String role) =>
    PresenceParticipant(
      seanceId: 's1',
      profilId: profil,
      role: role,
      prenom: prenom,
      identifiantImmuable: '',
      etat: EtatPresence.presente,
      consolide: false,
    );

ParticipantSalle _p(String identite, {String nom = ''}) => ParticipantSalle(
  identite: identite,
  nom: nom,
  role: 'student',
  estLocal: false,
  micro: true,
  camera: false,
  parle: false,
  qualite: QualiteLien.bonne,
);

const String _idProf = '7c1e9a40-1b2d-4c55-9e1a-000000000001';
const String _idEleve = '7c1e9a40-1b2d-4c55-9e1a-000000000002';

void main() {
  final List<PresenceParticipant> presence = <PresenceParticipant>[
    _ligne(_idProf, 'Amina', 'teacher'),
    _ligne(_idEleve, 'Yasmine', 'student'),
  ];

  for (final (TitreEnseignant titre, String attendu)
      in <(TitreEnseignant, String)>[
        (TitreEnseignant.sayyida, 'Sayyida Amina'),
        (TitreEnseignant.sayyid, 'Sayyid Amina'),
      ]) {
    test('enseignant : $attendu, selon son titre', () {
      final AnnuaireSeance annuaire = AnnuaireSeance(
        presence: presence,
        enseignant: EnseignantVM(
          enseignantId: _idProf,
          titre: titre,
          nomAffichage: 'Amina',
          photoUrlOuCle: 'avatars/amina.webp',
        ),
      );
      final ParticipantSalle nomme = annuaire.nommer(_p(_idProf));
      expect(nomme.nom, attendu);
      expect(nomme.cleAvatar, 'avatars/amina.webp');
      expect(annuaire.enseignant, attendu);
    });
  }

  test('enseignant sans titre connu : le prenom seul', () {
    final AnnuaireSeance annuaire = AnnuaireSeance(presence: presence);
    expect(annuaire.nommer(_p(_idProf)).nom, 'Amina');
  });

  test('eleve : son prenom, sans photo connue', () {
    final ParticipantSalle nomme = AnnuaireSeance(presence: presence)
        .nommer(_p(_idEleve));
    expect(nomme.nom, 'Yasmine');
    expect(nomme.cleAvatar, isNull);
  });

  test('inconnu : « Participant », jamais l identite', () {
    final AnnuaireSeance vide = AnnuaireSeance();
    expect(vide.nommer(_p(_idEleve)).nom, t.salle.participant);
    expect(vide.nommer(_p(_idEleve, nom: _idEleve)).nom, t.salle.participant);
    // Un nom porte par le jeton reste, s'il n'est pas l'identite.
    expect(vide.nommer(_p(_idEleve, nom: 'Ilyes')).nom, 'Ilyes');
  });
}
