// SALLE-1-TOUT-ICI, suite (arbitrage du garde-cap du 07/11, PLAN-TROIS-SALLES
// §2, option c) : sur la piece et sur la candidature, l'action principale
// n'y conclut pas une lecture ; elle se voit donc SANS DEFILER sur un
// telephone de 390 x 844 (texte x1). Mesures de B avant ce lot : piece
// y ~ 954, candidature y ~ 834 a 942.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../support/harnais.dart';
import 'candidature/hote_candidature.dart';

const Size _telephone = Size(390, 844);

/// Le bas de l'unique action pleine de l'ecran, sans aucun defilement.
double _basDeLActionPleine(WidgetTester tester) {
  final List<Element> pleines = find
      .byType(ActionPrincipale)
      .evaluate()
      .where(
        (Element e) =>
            (e.widget as ActionPrincipale).niveau == NiveauAction.principale,
      )
      .toList();
  expect(pleines, hasLength(1), reason: 'une seule action pleine (K-56)');
  return tester.getRect(find.byWidget(pleines.single.widget)).bottom;
}

void main() {
  // Les vraies polices, comme les mesures de B : la police de test (Ahem)
  // grossit chaque ligne et fausserait la mesure.
  setUpAll(chargerPolicesDuDepot);

  group('l\'action principale se voit sans defiler, 390 x 844', () {
    testWidgets('candidature : les trois ecrans de presentation', (
      WidgetTester tester,
    ) async {
      await monterQuestionnaire(tester, port: FauxMaCandidature());
      for (int ecran = 1; ecran <= 3; ecran++) {
        final double bas = _basDeLActionPleine(tester);
        expect(
          bas,
          lessThanOrEqualTo(_telephone.height),
          reason: 'presentation $ecran : action en bas a $bas',
        );
        final Finder action = find.byWidgetPredicate(
          (Widget w) =>
              w is ActionPrincipale && w.niveau == NiveauAction.principale,
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('piece d\'identite', (WidgetTester tester) async {
      tester.view.physicalSize = _telephone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attentePiece,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attentePiece,
              builder: (BuildContext _, GoRouterState _) =>
                  const DepotPiecePage(),
            ),
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('portail')),
            ),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
            depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
            selecteurFichierProvider.overrideWithValue(
              FauxSelecteurFichier(null),
            ),
            baseLocaleEnMemoire(),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final double bas = _basDeLActionPleine(tester);
      expect(
        bas,
        lessThanOrEqualTo(_telephone.height),
        reason: 'piece : action en bas a $bas',
      );
      // Une piece choisie (la derniere, la plus haute) : le lien « Choisir
      // la photo » parait au-dessus de l'action, qui reste dans l'ecran.
      await tester.tap(find.text(t.kyc.autrePiece));
      await tester.pumpAndSettle();
      expect(find.text(t.kyc.choisirFichier), findsOneWidget);
      final double apres = _basDeLActionPleine(tester);
      expect(
        apres,
        lessThanOrEqualTo(_telephone.height),
        reason: 'piece choisie : action en bas a $apres',
      );
    });
  });
}
