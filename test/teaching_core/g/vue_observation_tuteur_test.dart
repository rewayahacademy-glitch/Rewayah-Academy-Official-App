import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/tc_observation_ui/vue_observation_tuteur.dart';

ParticipantSalle _personne({
  required String identite,
  required String role,
  bool local = false,
  bool camera = false,
}) => ParticipantSalle(
  identite: identite,
  nom: identite,
  role: role,
  estLocal: local,
  micro: false,
  camera: camera,
  parle: false,
  qualite: QualiteLien.bonne,
);

/// Une classe de cinq enfants, l'enseignant, et le tuteur qui observe.
List<ParticipantSalle> _classe() => <ParticipantSalle>[
  _personne(identite: 'tuteur-1', role: 'guardian_observer', local: true),
  _personne(identite: 'prof-1', role: 'teacher', camera: true),
  _personne(identite: 'enfant-1', role: 'student', camera: true),
  _personne(identite: 'enfant-2', role: 'student'),
  _personne(identite: 'enfant-3', role: 'student'),
  _personne(identite: 'enfant-4', role: 'student'),
  _personne(identite: 'enfant-5', role: 'student'),
];

void main() {
  group('La visite tuteur n\'expose que deux personnes (spec 11.2)', () {
    test('l\'enseignant et son propre enfant, et personne d\'autre', () {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: _classe(),
        enfantProfilId: 'enfant-1',
      );

      expect(vue.enseignant?.identite, 'prof-1');
      expect(vue.monEnfant?.identite, 'enfant-1');
      // Quatre camarades dans la salle, aucun expose : le roster complet
      // n'existe pas ici, il ne sort pas de la fonction.
      expect(vue.participantsNonExposes, 4);
    });

    test('un tuteur sans enfant identifie n\'en voit aucun', () {
      // Le cas qui compte : si le serveur n'a pas dit quel enfant ce tuteur a
      // le droit de regarder, le repli est de n'en montrer aucun, jamais le
      // premier venu.
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: _classe(),
        enfantProfilId: null,
      );

      expect(vue.monEnfant, isNull);
      expect(vue.participantsNonExposes, 5);
    });

    test('un enfant qui n\'est pas le sien reste non expose', () {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: _classe(),
        enfantProfilId: 'enfant-inconnu',
      );

      expect(vue.monEnfant, isNull);
      expect(vue.participantsNonExposes, 5);
    });

    test('le tuteur ne se regarde pas lui-meme', () {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: _classe(),
        enfantProfilId: 'enfant-1',
      );

      expect(vue.enseignant?.estLocal, isFalse);
      expect(vue.monEnfant?.estLocal, isFalse);
    });

    test('un enfant present sans image se dit, il ne se devine pas', () {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: _classe(),
        enfantProfilId: 'enfant-2',
      );

      expect(vue.monEnfant?.identite, 'enfant-2');
      // La politique camera d'un mineur vaut `forbidden` par defaut : le cas
      // le plus frequent est l'enfant present et sans image.
      expect(vue.mediaEnfantOuvert, isFalse);
    });

    test('une salle encore vide se dit aussi', () {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: const <ParticipantSalle>[],
        enfantProfilId: 'enfant-1',
      );

      expect(vue.salleVide, isTrue);
      expect(vue.participantsNonExposes, 0);
    });

    test('un second enseignant ne double pas la vignette', () {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: <ParticipantSalle>[
          ..._classe(),
          _personne(identite: 'prof-2', role: 'teacher'),
        ],
        enfantProfilId: 'enfant-1',
      );

      expect(vue.enseignant?.identite, 'prof-1');
      expect(vue.participantsNonExposes, 5);
    });
  });
}
