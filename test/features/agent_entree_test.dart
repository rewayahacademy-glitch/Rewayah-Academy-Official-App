// EA-HL-DOUBLE-1f (K-59, decide par delegation le 09/10, DIR-REP-1) :
// l'entree d'un agent dont l'ouverture de session n'a pas abouti ne dit plus
// « Service indisponible » ni « L'ouverture de session n'a pas repondu ».
// Hors ligne, c'est l'appareil qui n'a rien envoye : la cause probable est
// dite sans etre affirmee, dans la formulation unique de EA-HL-DOUBLE-1e.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/amorce_agent.dart';
import 'package:rewayah_academy/core/agent/session_agent.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/agent_entree/agent_entree_page.dart';

import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';

void main() {
  for (final EchecAgent echec in <EchecAgent>[
    EchecAgent.serviceIndisponible,
    EchecAgent.reponseIllisible,
  ]) {
    testWidgets('$echec : aucune cause cote service affirmee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const AgentEntreePage(),
          surcharges: <Override>[echecAgentProvider.overrideWithValue(echec)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.agent.indisponible), findsOneWidget);
      expect(find.text(t.agent.indisponibleDetail), findsOneWidget);
      expect(causesAffirmees(), findsNothing);
      expect(find.textContaining(formulationCauseProbable), findsOneWidget);
      // Sous le bandeau : la connexion n'est pas redite.
      expect(signauxHorsLigne(), findsNothing);
    });
  }
}
