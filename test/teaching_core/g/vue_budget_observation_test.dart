import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/vue_budget_observation.dart';

import 'faux/faux_observation.dart';

/// L'instant de reference de tous les calculs de ce fichier.
///
/// Fige, jamais `DateTime.now()` : un compte a rebours cale sur l'horloge de la
/// machine change de resultat selon l'heure a laquelle la suite tourne.
final DateTime _recuA = DateTime.utc(2026, 9, 20, 10);

VueBudgetObservation _vue({
  Duration restant = const Duration(seconds: 120),
  Duration ecoule = Duration.zero,
}) => VueBudgetObservation.depuis(
  budget: unBudget(restant: restant),
  recuA: _recuA,
  maintenant: _recuA.add(ecoule),
);

void main() {
  group('Le compte a rebours est un affichage borne', () {
    test('a la reception, il vaut exactement ce que le serveur a dit', () {
      expect(_vue().restantAffiche, const Duration(seconds: 120));
      expect(_vue().secondesRestantes, 120);
      expect(_vue().epuise, isFalse);
    });

    test('il decroit du temps ecoule', () {
      expect(
        _vue(ecoule: const Duration(seconds: 30)).restantAffiche,
        const Duration(seconds: 90),
      );
    });

    test('il ne descend jamais sous zero', () {
      final VueBudgetObservation vue = _vue(
        ecoule: const Duration(minutes: 10),
      );

      expect(vue.restantAffiche, Duration.zero);
      expect(vue.secondesRestantes, 0);
      expect(vue.epuise, isTrue);
    });

    test('une horloge qui recule ne cree pas de temps', () {
      // Le coeur de l'invariant 11.4 cote client : reculer sa montre ne rend
      // pas une seconde. L'ecoule negatif est plancherise a zero, donc le
      // restant plafonne a la valeur serveur.
      final VueBudgetObservation vue = _vue(
        ecoule: const Duration(minutes: -10),
      );

      expect(vue.restantAffiche, const Duration(seconds: 120));
      expect(vue.restantAffiche, lessThanOrEqualTo(vue.restantServeur));
    });

    test('le restant affiche n\'excede jamais le restant serveur', () {
      for (final Duration ecart in <Duration>[
        const Duration(hours: -3),
        const Duration(seconds: -1),
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(hours: 3),
      ]) {
        final VueBudgetObservation vue = _vue(ecoule: ecart);
        expect(
          vue.restantAffiche,
          lessThanOrEqualTo(vue.restantServeur),
          reason: 'ecart $ecart',
        );
      }
    });

    test('les secondes sont arrondies vers le haut', () {
      // Sinon les neuf cent quatre-vingt-dix-neuf derniers millisecondes
      // afficheraient « 0 s restantes » et le decompte paraitrait bloque.
      final VueBudgetObservation vue = VueBudgetObservation.depuis(
        budget: unBudget(restant: const Duration(seconds: 2)),
        recuA: _recuA,
        maintenant: _recuA.add(const Duration(milliseconds: 1500)),
      );

      expect(vue.secondesRestantes, 1);
      expect(vue.epuise, isFalse);
    });

    test('le rang de visite ne vaut jamais zero', () {
      final VueBudgetObservation vue = VueBudgetObservation.depuis(
        budget: unBudget(visitesUtilisees: 0),
        recuA: _recuA,
        maintenant: _recuA,
      );

      expect(vue.rangVisite, 1);
    });
  });
}
