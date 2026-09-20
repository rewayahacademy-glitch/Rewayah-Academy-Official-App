import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/rotation_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';

QuestionFeedback _question(String id) => QuestionFeedback(
  id: id,
  intitule: id,
  libelles: const <ReponseFeedback, String>{
    ReponseFeedback.difficile: 'Difficile',
    ReponseFeedback.bien: 'Bien',
    ReponseFeedback.tresBien: 'Tres bien',
  },
);

final List<QuestionFeedback> _catalogue = <QuestionFeedback>[
  _question('a'),
  _question('b'),
  _question('c'),
];

void main() {
  group('rotation : une question ne revient qu apres les autres', () {
    test('le premier cycle parcourt tout le catalogue sans repetition', () {
      final List<String> posees = <String>[];

      for (int i = 0; i < _catalogue.length; i++) {
        final QuestionFeedback? question = RotationFeedback.prochaineQuestion(
          catalogue: _catalogue,
          dejaPosees: posees,
        );
        expect(question, isNotNull);
        expect(
          posees,
          isNot(contains(question!.id)),
          reason: 'une question posee deux fois dans le meme cycle',
        );
        posees.add(question.id);
      }

      expect(posees, <String>['a', 'b', 'c']);
    });

    test('la quatrieme question rouvre le cycle, jamais avant', () {
      // C'est l'exigence de la spec section 12.1, celle qu'on oublie : « la
      // meme question peut revenir apres, mais apres avoir affiche les autres
      // d'abord ».
      expect(
        RotationFeedback.prochaineQuestion(
          catalogue: _catalogue,
          dejaPosees: const <String>['a', 'b'],
        )!.id,
        'c',
      );
      expect(
        RotationFeedback.prochaineQuestion(
          catalogue: _catalogue,
          dejaPosees: const <String>['a', 'b', 'c'],
        )!.id,
        'a',
      );
    });

    test('trois cycles complets ne repetent jamais dans un cycle', () {
      final List<String> posees = <String>[];
      for (int i = 0; i < _catalogue.length * 3; i++) {
        posees.add(
          RotationFeedback.prochaineQuestion(
            catalogue: _catalogue,
            dejaPosees: posees,
          )!.id,
        );
      }

      for (int debut = 0; debut < posees.length; debut += _catalogue.length) {
        final Set<String> cycle = posees
            .sublist(debut, debut + _catalogue.length)
            .toSet();
        expect(cycle.length, _catalogue.length);
      }
    });

    test('un identifiant inconnu ne gele pas la rotation', () {
      // Une question retiree du catalogue entre deux versions laisse une trace
      // dans l'historique : elle est ignoree, sinon la rotation resterait
      // bloquee sur place.
      expect(
        RotationFeedback.prochaineQuestion(
          catalogue: _catalogue,
          dejaPosees: const <String>['disparue', 'a'],
        )!.id,
        'b',
      );
    });

    test('un catalogue vide ne pose aucune question', () {
      expect(
        RotationFeedback.prochaineQuestion(
          catalogue: const <QuestionFeedback>[],
          dejaPosees: const <String>[],
        ),
        isNull,
      );
    });

    test('le catalogue du produit couvre cinq volets distincts', () {
      final Set<String> identifiants = <String>{
        for (final QuestionFeedback q in CatalogueFeedback.questions) q.id,
      };
      expect(identifiants.length, CatalogueFeedback.questions.length);
      expect(identifiants.length, greaterThanOrEqualTo(3));

      for (final QuestionFeedback question in CatalogueFeedback.questions) {
        // Chaque question porte SES trois libelles : une rotation ou les mots
        // ne changent pas est un decor.
        expect(question.libelles.length, ReponseFeedback.values.length);
      }
      final Set<String> intitules = <String>{
        for (final QuestionFeedback q in CatalogueFeedback.questions)
          q.intitule,
      };
      expect(intitules.length, CatalogueFeedback.questions.length);
    });
  });

  group('echantillonnage : occasionnel, jamais systematique', () {
    test('une seance sur quatre par defaut', () {
      expect(RotationFeedback.estEchantillonnee(rangSeance: 1), isFalse);
      expect(RotationFeedback.estEchantillonnee(rangSeance: 3), isFalse);
      expect(RotationFeedback.estEchantillonnee(rangSeance: 4), isTrue);
      expect(RotationFeedback.estEchantillonnee(rangSeance: 8), isTrue);
    });

    test('une cadence nulle eteint le feedback', () {
      expect(
        RotationFeedback.estEchantillonnee(rangSeance: 4, cadence: 0),
        isFalse,
      );
      expect(
        RotationFeedback.estEchantillonnee(rangSeance: 4, cadence: -1),
        isFalse,
      );
    });

    test('un rang de seance nul ou negatif ne declenche rien', () {
      expect(
        RotationFeedback.estEchantillonnee(rangSeance: 0, cadence: 1),
        isFalse,
      );
    });
  });
}
