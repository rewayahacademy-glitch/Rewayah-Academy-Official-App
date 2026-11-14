// Directeur, test en production du 26/10/2026 (09:15) : le jeton LiveKit ne
// porte aucun nom ; l'annuaire de la seance nomme chaque participant et
// donne sa photo, l'identite technique n'est jamais un nom.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/annuaire_seance.dart';
import 'package:rewayah_academy/features/salle/seance_vivante.dart'
    show nomArrivant;
import 'package:rewayah_academy/features/salle/vue_salle.dart' show estStaff;

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
        enseignant: (
          id: _idProf,
          prenom: 'Amina',
          titre: titre,
          clePhoto: '$_idProf/amina.webp',
          pays: null,
        ),
      );
      final ParticipantSalle nomme = annuaire.nommer(_p(_idProf));
      expect(nomme.nom, attendu);
      expect(nomme.clePhotoEnseignant, '$_idProf/amina.webp');
      expect(annuaire.enseignant, attendu);
    });
  }

  test('enseignant sans titre connu : le prenom seul', () {
    final AnnuaireSeance annuaire = AnnuaireSeance(presence: presence);
    expect(annuaire.nommer(_p(_idProf)).nom, 'Amina');
    // Un titre absent de la fiche ne se devine pas.
    final AnnuaireSeance sansTitre = AnnuaireSeance(
      enseignant: (
        id: _idProf,
        prenom: 'Amina',
        titre: null,
        clePhoto: null,
        pays: null,
      ),
    );
    expect(sansTitre.nommer(_p(_idProf)).nom, 'Amina');
  });

  test('eleve : son prenom, sans photo connue', () {
    final ParticipantSalle nomme = AnnuaireSeance(presence: presence)
        .nommer(_p(_idEleve));
    expect(nomme.nom, 'Yasmine');
    expect(nomme.clePhotoEnseignant, isNull);
  });

  test('inconnu : « Participant », jamais l identite', () {
    final AnnuaireSeance vide = AnnuaireSeance();
    expect(vide.nommer(_p(_idEleve)).nom, t.salle.participant);
    expect(vide.nommer(_p(_idEleve, nom: _idEleve)).nom, t.salle.participant);
    // Un nom porte par le jeton reste, s'il n'est pas l'identite.
    expect(vide.nommer(_p(_idEleve, nom: 'Ilyes')).nom, 'Ilyes');
  });

  // PHOTOS-2b (pilote, 04/11/2026) : chez l'eleve et le tuteur, un camarade
  // inconnu n'a aucun nom (ni « Participant », ni l'identite) ; la photo
  // ouverte par K-44 ou un cercle neutre le montre.
  test('eleve ou tuteur : un camarade inconnu reste sans nom', () {
    final AnnuaireSeance annuaire = AnnuaireSeance(nommerLesInconnus: false);
    expect(annuaire.nommer(_p(_idEleve)).nom, isEmpty);
    expect(annuaire.nommer(_p(_idEleve, nom: _idEleve)).nom, isEmpty);
    expect(annuaire.nommer(_p(_idEleve, nom: 'Ilyes')).nom, 'Ilyes');
  });

  test('eleve adulte : ses camarades par sa Classe, la presence devant', () {
    const String idCamarade = '7c1e9a40-1b2d-4c55-9e1a-000000000003';
    final AnnuaireSeance annuaire = AnnuaireSeance(
      presence: presence,
      nommerLesInconnus: false,
      camarades: const <CamaradeSeance>[
        (id: idCamarade, prenom: 'Nora'),
        (id: _idEleve, prenom: 'Autre'),
        (id: '', prenom: 'Sans identifiant'),
      ],
    );
    expect(annuaire.nommer(_p(idCamarade)).nom, 'Nora');
    expect(annuaire.nommer(_p(_idEleve)).nom, 'Yasmine');
  });

  group('RA-STAFF (directeur, 14/11/2026)', () {
    ParticipantSalle personne(String role, String nom) => ParticipantSalle(
      identite: 'id-$role',
      nom: nom,
      role: role,
      estLocal: false,
      micro: true,
      camera: true,
      parle: false,
      qualite: QualiteLien.bonne,
    );

    test('la direction visible et qui mene un entretien sont du staff ; '
        'jamais l incognito, le controleur, l enseignant, l eleve, le '
        'candidat', () {
      expect(estStaff('admin_visible'), isTrue);
      expect(estStaff('intervieweur'), isTrue);
      for (final String r in <String>[
        'admin_masked',
        'masked_controller',
        'teacher',
        'student',
        'guardian_observer',
        'candidat',
        'inconnu',
      ]) {
        expect(estStaff(r), isFalse, reason: r);
      }
      expect(estStaff(null), isFalse);
    });

    test('nommee : la designation remplace le nom, meme connu de l '
        'annuaire ; sans designation branchee, rien ne change', () {
      final AnnuaireSeance a = AnnuaireSeance(
        presence: <PresenceParticipant>[
          _ligne('id-intervieweur', 'Hafsa', 'intervieweur'),
        ],
      );
      final ParticipantSalle staff = personne('intervieweur', 'Hafsa');
      expect(a.nommer(staff, designationStaff: '#Ra_staff').nom, '#Ra_staff');
      expect(a.nommer(staff).nom, 'Hafsa');
      expect(
        a
            .nommer(
              personne('admin_visible', 'Administration Rewayah'),
              designationStaff: '#Ra_staff',
            )
            .nom,
        '#Ra_staff',
      );
      final ParticipantSalle candidat = personne('candidat', 'Khadija');
      expect(a.nommer(candidat, designationStaff: '#Ra_staff').nom, 'Khadija');
    });

    test('arrivees : la direction arrive sous la designation', () {
      expect(
        nomArrivant(
          personne('admin_visible', 'Administration Rewayah'),
          '#Ra_staff',
        ),
        '#Ra_staff',
      );
      expect(
        nomArrivant(personne('student', 'Yasmine'), '#Ra_staff'),
        'Yasmine',
      );
      expect(nomArrivant(personne('admin_visible', 'X'), null), 'X');
    });
  });
}
