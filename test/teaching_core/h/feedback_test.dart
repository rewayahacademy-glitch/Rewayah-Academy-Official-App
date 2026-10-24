import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_parcours/feedback_memoire.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';

const String _groupe = 'g1';

FeedbackMemoire _depot({int cadence = 1, int seuil = 3, int seances = 12}) =>
    FeedbackMemoire(
      cadence: cadence,
      seuilTendance: seuil,
      seances: <String, ContexteSeanceFeedback>{
        for (int rang = 1; rang <= seances; rang++)
          's$rang': ContexteSeanceFeedback(groupeId: _groupe, rangSeance: rang),
      },
    );

void main() {
  group('echantillonnage', () {
    test('une seance non echantillonnee ne pose aucune question', () async {
      final FeedbackMemoire depot = _depot(cadence: 4);

      expect(await depot.questionPour('s1'), isNull);
      expect(await depot.questionPour('s2'), isNull);
      expect(await depot.questionPour('s3'), isNull);
      expect(await depot.questionPour('s4'), isNotNull);
    });

    test('une seance inconnue ne pose aucune question', () async {
      expect(await _depot().questionPour('inconnue'), isNull);
    });

    test('une seance deja notee ne redemande rien', () async {
      final FeedbackMemoire depot = _depot();
      final QuestionFeedback question = (await depot.questionPour('s1'))!;

      await depot.soumettre(
        sessionId: 's1',
        questionId: question.id,
        reponse: ReponseFeedback.bien,
      );

      expect(await depot.questionPour('s1'), isNull);
    });

    test('un second depot est refuse, et il est nomme', () async {
      final FeedbackMemoire depot = _depot();
      await depot.soumettre(
        sessionId: 's1',
        questionId: 'cours',
        reponse: ReponseFeedback.bien,
      );

      expect(
        () => depot.soumettre(
          sessionId: 's1',
          questionId: 'cours',
          reponse: ReponseFeedback.tresBien,
        ),
        throwsA(
          isA<EchecFeedback>().having(
            (EchecFeedback e) => e.motif,
            'motif',
            MotifEchecFeedback.dejaDepose,
          ),
        ),
      );
    });
  });

  group('rotation dans le depot', () {
    test('la question change a chaque seance notee', () async {
      final FeedbackMemoire depot = _depot();
      final List<String> posees = <String>[];

      for (int rang = 1; rang <= 5; rang++) {
        final QuestionFeedback question = (await depot.questionPour('s$rang'))!;
        posees.add(question.id);
        await depot.soumettre(
          sessionId: 's$rang',
          questionId: question.id,
          reponse: ReponseFeedback.bien,
        );
      }

      expect(posees.toSet().length, posees.length);
    });

    test('une carte ignoree ne consomme pas une question', () async {
      final FeedbackMemoire depot = _depot();
      final QuestionFeedback premiere = (await depot.questionPour('s1'))!;
      // Personne ne repond a s1 : s2 doit reposer la meme question, sinon un
      // eleve silencieux ferait defiler le catalogue de tout son groupe.
      final QuestionFeedback seconde = (await depot.questionPour('s2'))!;

      expect(seconde.id, premiere.id);
    });
  });

  group('tendance : agregee, et seulement au-dessus du seuil', () {
    test('sous le seuil, aucune repartition ne sort', () async {
      final FeedbackMemoire depot = _depot(seuil: 3);
      await depot.soumettre(
        sessionId: 's1',
        questionId: 'cours',
        reponse: ReponseFeedback.difficile,
      );
      await depot.soumettre(
        sessionId: 's2',
        questionId: 'rythme',
        reponse: ReponseFeedback.difficile,
      );

      final TendanceFeedback tendance = await depot.tendance(groupeId: _groupe);

      expect(tendance.nombreEchantillons, 2);
      expect(tendance.visibleParEnseignant, isFalse);
      expect(
        tendance.repartition,
        isNull,
        reason:
            'deux reponses ne sont pas une tendance, et un enseignant ne doit '
            'pas pouvoir deviner qui a repondu quoi',
      );
    });

    test('au seuil, la repartition sort et somme a 1', () async {
      final FeedbackMemoire depot = _depot(seuil: 3);
      await depot.soumettre(
        sessionId: 's1',
        questionId: 'cours',
        reponse: ReponseFeedback.difficile,
      );
      await depot.soumettre(
        sessionId: 's2',
        questionId: 'rythme',
        reponse: ReponseFeedback.bien,
      );
      await depot.soumettre(
        sessionId: 's3',
        questionId: 'confiance',
        reponse: ReponseFeedback.tresBien,
      );

      final TendanceFeedback tendance = await depot.tendance(groupeId: _groupe);

      expect(tendance.visibleParEnseignant, isTrue);
      expect(tendance.repartition, isNotNull);
      final double somme = tendance.repartition!.values.reduce(
        (double a, double b) => a + b,
      );
      expect(somme, closeTo(1, 0.000001));
    });

    test('un groupe sans reponse ne montre rien', () async {
      final TendanceFeedback tendance = await _depot().tendance(
        groupeId: 'autre',
      );

      expect(tendance.nombreEchantillons, 0);
      expect(tendance.visibleParEnseignant, isFalse);
      expect(tendance.repartition, isNull);
    });

    test('une tendance visible ne peut pas etre construite sans seuil', () {
      // L'assertion du contrat est la garantie : une repartition ne peut pas
      // voyager avec `visibleParEnseignant` a faux. C'est ce qui empeche un
      // futur appelant de construire a la main la tendance que le seuil
      // refusait.
      expect(
        () => TendanceFeedback(
          groupeId: _groupe,
          nombreEchantillons: 1,
          seuilMinimum: 5,
          visibleParEnseignant: false,
          repartition: const <ReponseFeedback, double>{ReponseFeedback.bien: 1},
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
