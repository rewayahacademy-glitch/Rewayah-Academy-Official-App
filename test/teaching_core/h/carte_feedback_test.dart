import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/tc_flux_academique/carte_feedback_seance.dart';

import 'support/faux_feedback.dart';
import 'support/hote_h.dart';

const String _seance = 's1';
// La seance hors echantillon : le serveur ne rend aucune question.
FauxFeedback _depot({required bool echantillonnee}) =>
    FauxFeedback(question: echantillonnee ? questionCours() : null);

List<Override> _surcharges(FauxFeedback depot) => <Override>[
  portFeedbackProvider.overrideWithValue(depot),
];

void main() {
  group('carte de micro-feedback', () {
    testWidgets('hors echantillon, la carte n existe pas du tout', (
      WidgetTester tester,
    ) async {
      telephone(tester);

      await tester.pumpWidget(
        hoteH(
          const CarteFeedbackSeance(sessionId: _seance),
          surcharges: _surcharges(_depot(echantillonnee: false)),
        ),
      );
      await tester.pumpAndSettle();

      // Pas de carte, pas de squelette, pas d'emplacement vide : un avis
      // facultatif ne se signale pas quand il n'est pas demande.
      expect(find.byType(AppCard), findsNothing);
      expect(
        find.text(t.tc.parcours.feedback.cours.intitule),
        findsNothing,
      );
    });

    testWidgets('echantillonnee, elle pose une question et trois choix', (
      WidgetTester tester,
    ) async {
      telephone(tester);

      await tester.pumpWidget(
        hoteH(
          const CarteFeedbackSeance(sessionId: _seance),
          surcharges: _surcharges(_depot(echantillonnee: true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.tc.parcours.feedback.cours.intitule),
        findsOneWidget,
      );
      expect(find.text(t.tc.parcours.feedback.cours.difficile), findsOneWidget);
      expect(find.text(t.tc.parcours.feedback.cours.bien), findsOneWidget);
      expect(find.text(t.tc.parcours.feedback.cours.tresBien), findsOneWidget);
      // Aucun champ de commentaire : « pas de commentaire obligatoire » se
      // tient mieux en n'offrant pas de champ du tout.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('un seul tap suffit, et la carte remercie', (
      WidgetTester tester,
    ) async {
      telephone(tester);
      final FauxFeedback depot = _depot(echantillonnee: true);

      await tester.pumpWidget(
        hoteH(
          const CarteFeedbackSeance(sessionId: _seance),
          surcharges: _surcharges(depot),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.tc.parcours.feedback.cours.tresBien));
      await tester.pumpAndSettle();

      expect(find.text(t.tc.parcours.feedback.merci), findsOneWidget);
      expect(
        find.text(t.tc.parcours.feedback.cours.intitule),
        findsNothing,
      );

      final TendanceFeedback tendance = await depot.tendance(
        groupeId: 'g1',
      );
      expect(tendance.nombreEchantillons, 1);
    });
  });
}
