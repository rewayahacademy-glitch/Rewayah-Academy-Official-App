// BOUTON-ATTENTE (garde-cap, 07/11/2026) : l'indicateur d'`enCours` d'
// `ActionPrincipale` etait un arc fige aux deux tiers (`value: 0.65`), qui se
// lisait « bloque ». Il est desormais indetermine et anime ; en mouvement
// reduit (`MediaQuery.disableAnimations`, pose par `ReglageMouvement`), il
// reste statique.
//
// Contrat : DESIGN-GOV-2026-09-26 §4 bis.5 (« `linear` seulement pour une
// progression indeterminee » ; en reduction de mouvement, duree 0) et §4 bis.6
// point 5 (« un indicateur local reste permis dans un bouton »), point 6 (ni
// shimmer, ni pulsation).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

import '../../support/hote_theme.dart';

Widget _hote({required bool reduit, bool enCours = true}) => hoteTheme(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
      child: Center(
        child: ActionPrincipale(
          libelle: 'Enregistrer',
          pleineLargeur: false,
          enCours: enCours,
          onPress: () {},
        ),
      ),
    ),
  ),
);

CircularProgressIndicator _indicateur(WidgetTester tester) => tester
    .widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));

void main() {
  group('BOUTON-ATTENTE : l indicateur d attente du bouton', () {
    testWidgets('en cours : indetermine (value null), donc anime', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_indicateur(tester).value, isNull);
      // Il bouge : deux images a 300 ms d'ecart ne sont pas la meme
      // (un arc fige laisserait le meme arbre de rendu, sans image planifiee).
      expect(tester.binding.hasScheduledFrame, isTrue);
      // Il ne se pose jamais : pumpAndSettle ne peut pas aboutir.
      await expectLater(
        () => tester.pumpAndSettle(const Duration(milliseconds: 100)),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('mouvement reduit : un arc statique, aucune image planifiee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: true));
      await tester.pumpAndSettle();
      expect(_indicateur(tester).value, isNotNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('au repos : aucun indicateur', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(reduit: false, enCours: false));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Enregistrer'), findsOneWidget);
    });
  });
}
