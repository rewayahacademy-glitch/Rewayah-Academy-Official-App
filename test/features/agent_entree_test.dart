// EA-HL-DOUBLE-1f (K-59, decide par delegation le 09/10, DIR-REP-1) :
// l'entree d'un agent dont l'ouverture de session n'a pas abouti ne dit plus
// « Service indisponible » ni « L'ouverture de session n'a pas repondu ».
// Hors ligne, c'est l'appareil qui n'a rien envoye : la cause probable est
// dite sans etre affirmee, dans la formulation unique de EA-HL-DOUBLE-1e.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/agent/amorce_agent.dart';
import 'package:rewayah_academy/core/agent/session_agent.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/agent_entree/agent_entree_page.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
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

  // EA-HL-DOUBLE-1f : le libelle du champ du jeton etait tronque a 320 px
  // en texte x2 ; il est pose au-dessus du champ et passe a la ligne.
  group('320 texte x2 (polices du depot)', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 texte x2, ${sens.name} : aucun mot coupe ni tronque', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(320, 1700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteRoutant(
            depart: '/',
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext _, GoRouterState _) =>
                    const AgentEntreePage(),
              ),
            ],
            surcharges: <Override>[
              echecAgentProvider.overrideWithValue(
                EchecAgent.serviceIndisponible,
              ),
            ],
            direction: sens,
            echelle: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.agent.jeton), findsOneWidget);
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
      });
    }
  });

  // EA-HL-DOUBLE-1f : captures de preuve, hors ligne sous le bandeau (390
  // clair et sombre, 320 texte x2 en LTR et RTL) et en ligne. Sautees sans
  // CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1f', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String, Size, ThemeMode, double, TextDirection, bool) cas
        in <(String, Size, ThemeMode, double, TextDirection, bool)>[
          (
            '390_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            true,
          ),
          (
            '390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            1,
            TextDirection.ltr,
            true,
          ),
          (
            '320x2_clair',
            const Size(320, 1700),
            ThemeMode.light,
            2,
            TextDirection.ltr,
            true,
          ),
          (
            '320x2_rtl_clair',
            const Size(320, 1700),
            ThemeMode.light,
            2,
            TextDirection.rtl,
            true,
          ),
          (
            '390_en_ligne_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            false,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            Directionality(
              textDirection: cas.$5,
              child: const AgentEntreePage(),
            ),
            surcharges: <Override>[
              echecAgentProvider.overrideWithValue(
                EchecAgent.serviceIndisponible,
              ),
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(cas.$6),
              ),
            ],
            themeMode: cas.$3,
            echelleTexte: cas.$4,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(t.agent.indisponibleDetail), findsOneWidget);
        expect(causesAffirmees(), findsNothing);
        if (cas.$6) {
          expectHorsLigneUneFois();
        }
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
        debugPrint(
          'PNG ${await capturer(tester, 'ea_hl_double1f_agent_echec_${cas.$1}')}',
        );
      });
    }
  });
}
