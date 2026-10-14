import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/consentements_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/consentements/consentement_observation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/annonces.dart';
import '../support/harnais.dart';

Acceptation _accordObservation({DateTime? quand}) => Acceptation(
  sorte: SorteContrat.conditionsTuteur,
  version: VersionsContrat.pour(SorteContrat.conditionsTuteur),
  accepteeLe: quand ?? DateTime(2026, 9, 4),
);

/// Une destination de retour, pour que le `go` du bouton retour aboutisse.
GoRoute _compte() => GoRoute(
  path: Routes.tuteurCompte,
  builder: (BuildContext _, GoRouterState _) =>
      const Scaffold(body: Text('compte')),
);

/// Rend le geste visible avant de le taper : la page defile (l'explication
/// occupe la colonne), et un tap hors cadre ne prouve rien.
Future<void> _tapperVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<FauxPortConsentements> _monter(
  WidgetTester tester, {
  String depart = Routes.tuteurCompteConsentements,
}) async {
  final FauxPortConsentements port = FauxPortConsentements();
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.tuteurCompteConsentements,
          builder: (BuildContext _, GoRouterState _) =>
              const ConsentementObservationPage(),
        ),
        _compte(),
      ],
      surcharges: <Override>[consentementsLotAProvider.overrideWithValue(port)],
    ),
  );
  await tester.pumpAndSettle();
  return port;
}

void main() {
  group('/tuteur/compte/consentements : lecture avant tout affichage', () {
    testWidgets('rien n est presume pendant la lecture', (
      WidgetTester tester,
    ) async {
      final Completer<List<Acceptation>> reponse =
          Completer<List<Acceptation>>();
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.tuteurCompteConsentements,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tuteurCompteConsentements,
              builder: (BuildContext _, GoRouterState _) =>
                  const ConsentementObservationPage(),
            ),
            _compte(),
          ],
          surcharges: <Override>[
            accordsTitulaireProvider.overrideWith((_) => reponse.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.text(t.consentement.texte.caseResponsable), findsNothing);

      reponse.complete(<Acceptation>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('accord non signe : le texte, la case non precochee', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = await _monter(tester);
      port.signeesRendues = <Acceptation>[];

      expect(find.text(t.consentement.compte.intro), findsOneWidget);
      final Finder caseAccord = find.byType(Checkbox);
      expect(caseAccord, findsOneWidget);
      expect(tester.widget<Checkbox>(caseAccord).value, isFalse);
      expect(
        find
            .widgetWithText(ActionPrincipale, t.consentement.texte.continuer)
            .evaluate()
            .isEmpty,
        isFalse,
      );
    });

    testWidgets('deja signe : la date d acceptation, pas de case', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = FauxPortConsentements()
        ..signeesRendues = <Acceptation>[
          _accordObservation(quand: DateTime(2026, 9, 4)),
        ];
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.tuteurCompteConsentements,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tuteurCompteConsentements,
              builder: (BuildContext _, GoRouterState _) =>
                  const ConsentementObservationPage(),
            ),
            _compte(),
          ],
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('04/09/2026'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('une lecture en echec le dit, sans rien presumer', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = FauxPortConsentements()
        ..erreurAJeter = StateError('lecture');
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.tuteurCompteConsentements,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tuteurCompteConsentements,
              builder: (BuildContext _, GoRouterState _) =>
                  const ConsentementObservationPage(),
            ),
            _compte(),
          ],
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.consentement.compte.sansProfil), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('une lecture hors ligne le dit distinctement', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = FauxPortConsentements()
        ..erreurAJeter = const SocketException('hors ligne');
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.tuteurCompteConsentements,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tuteurCompteConsentements,
              builder: (BuildContext _, GoRouterState _) =>
                  const ConsentementObservationPage(),
            ),
            _compte(),
          ],
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.consentement.compte.horsLigne), findsOneWidget);
    });
  });

  group(
    '/tuteur/compte/consentements : accepter, geste depuis la navigation',
    () {
      testWidgets('la case non cochee ne signe rien', (
        WidgetTester tester,
      ) async {
        final List<String> annonces = ecouterAnnonces(tester);
        final FauxPortConsentements port = await _monter(tester);

        await _tapperVisible(
          tester,
          find.widgetWithText(ActionPrincipale, t.consentement.texte.continuer),
        );

        expect(port.accepteEnregistre, isEmpty);
        // BOUTONS-GRISES-1 : actif, l'appui dit ce qui manque, l'annonce et
        // rend le focus a la case.
        expect(find.text(t.formulaire.manqueAccord), findsOneWidget);
        expect(annonces, <String>[t.formulaire.manqueAccord]);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'case-accord');
      });

      testWidgets('cocher puis Continuer enregistre l accord, dit merci', (
        WidgetTester tester,
      ) async {
        final FauxPortConsentements port = await _monter(tester);

        await _tapperVisible(tester, find.byType(Checkbox));
        await _tapperVisible(
          tester,
          find.widgetWithText(ActionPrincipale, t.consentement.texte.continuer),
        );

        expect(port.accepteEnregistre, <({SorteContrat sorte, String version})>[
          (
            sorte: SorteContrat.conditionsTuteur,
            version: VersionsContrat.pour(SorteContrat.conditionsTuteur),
          ),
        ]);
        expect(find.text(t.consentement.compte.merci), findsOneWidget);
      });

      testWidgets(
        'un 23505 (deja signe ailleurs) relit au lieu d afficher une erreur',
        (WidgetTester tester) async {
          final FauxPortConsentements port = await _monter(tester);
          port.erreurAJeter = const PostgrestException(
            message: 'duplicate',
            code: '23505',
          );

          await _tapperVisible(tester, find.byType(Checkbox));
          await _tapperVisible(
            tester,
            find.widgetWithText(
              ActionPrincipale,
              t.consentement.texte.continuer,
            ),
          );

          expect(find.text(t.contrat.erreur), findsNothing);
        },
      );

      testWidgets('un echec d ecriture se dit, et ne quitte pas l ecran', (
        WidgetTester tester,
      ) async {
        final FauxPortConsentements port = await _monter(tester);
        port.erreurAJeter = StateError('reseau');

        await _tapperVisible(tester, find.byType(Checkbox));
        await _tapperVisible(
          tester,
          find.widgetWithText(ActionPrincipale, t.consentement.texte.continuer),
        );

        expect(find.text(t.contrat.erreur), findsOneWidget);
        expect(find.text('compte'), findsNothing);
      });

      testWidgets('Retour ramene au compte, geste tape depuis la navigation', (
        WidgetTester tester,
      ) async {
        await _monter(tester);

        await _tapperVisible(
          tester,
          find.widgetWithText(ActionPrincipale, t.consentement.texte.retour),
        );

        expect(find.text('compte'), findsOneWidget);
      });
    },
  );

  group('InviteConsentementObservation : le bouton qui ouvre l ecran', () {
    testWidgets('tapper Lire ouvre /tuteur/compte/consentements', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = FauxPortConsentements()
        ..signeesRendues = <Acceptation>[];
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.tuteurCompte,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tuteurCompte,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: InviteConsentementObservation()),
            ),
            GoRoute(
              path: Routes.tuteurCompteConsentements,
              builder: (BuildContext _, GoRouterState _) =>
                  const ConsentementObservationPage(),
            ),
          ],
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.consentement.compte.invite), findsOneWidget);
      await _tapperVisible(
        tester,
        find.text(t.consentement.compte.inviteAction),
      );

      expect(find.text(t.consentement.texte.titre), findsOneWidget);
    });

    testWidgets('deja signe : l invite ne s affiche pas', (
      WidgetTester tester,
    ) async {
      final FauxPortConsentements port = FauxPortConsentements()
        ..signeesRendues = <Acceptation>[_accordObservation()];
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.tuteurCompte,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tuteurCompte,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: InviteConsentementObservation()),
            ),
          ],
          surcharges: <Override>[
            consentementsLotAProvider.overrideWithValue(port),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.consentement.compte.invite), findsNothing);
    });
  });
}
