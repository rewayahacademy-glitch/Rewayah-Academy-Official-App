import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../../support/harnais.dart';

GoRoute _temoin(String chemin, String texte) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) => Scaffold(body: Text(texte)),
);

EtatDossier _dossier({
  required AppRole role,
  bool accuse = false,
  bool contrat = false,
}) => EtatDossier(
  profilExiste: true,
  role: role,
  statutCompte: AccountStatus.pendingKyc,
  accuseSigne: accuse,
  contratSigne: contrat,
);

Future<void> _monterDepot(WidgetTester tester, EtatDossier etat) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attentePiece,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attentePiece,
          builder: (BuildContext _, GoRouterState _) => const DepotPiecePage(),
        ),
        _temoin(Routes.attente, 'portail'),
        _temoin(Routes.tuteurAccueil, 'accueil-tuteur'),
        _temoin(Routes.eleve, 'accueil-eleve'),
        _temoin(Routes.enseignantJournee, 'journee'),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(
          FauxServiceDossier()..etatRendu = etat,
        ),
        selecteurFichierProvider.overrideWithValue(FauxSelecteurFichier(null)),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _monterAttente(WidgetTester tester, EtatDossier etat) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attente,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) => const AttentePage(),
        ),
        _temoin(Routes.attentePiece, 'piece'),
        _temoin(Routes.tuteurAccueil, 'accueil-tuteur'),
        _temoin(Routes.enseignantJournee, 'journee'),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(
          FauxServiceDossier()..etatRendu = etat,
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Le depot de la piece : propose aux familles, jamais impose', () {
    testWidgets('un tuteur peut faire plus tard, et continue chez lui', (
      WidgetTester tester,
    ) async {
      await _monterDepot(tester, _dossier(role: AppRole.guardian));

      expect(find.text(t.classes.kyc.plusTard), findsOneWidget);
      expect(find.text(t.classes.kyc.plusTardDetail), findsOneWidget);
      // Le bouton tient dans un telephone, avec les deux gestes du depot.
      final Rect zone = tester.getRect(find.text(t.classes.kyc.plusTard));
      expect(zone.bottom, lessThanOrEqualTo(844));
      expect(zone.top, greaterThanOrEqualTo(0));

      await tester.tap(find.text(t.classes.kyc.plusTard));
      await tester.pumpAndSettle();
      expect(find.text('accueil-tuteur'), findsOneWidget);
    });

    testWidgets('un enseignant n a pas cette sortie : son KYC est requis', (
      WidgetTester tester,
    ) async {
      await _monterDepot(tester, _dossier(role: AppRole.teacher));
      expect(find.text(t.classes.kyc.plusTard), findsNothing);
      expect(find.text(t.classes.kyc.plusTardDetail), findsNothing);
    });
  });

  group('Le portail d attente laisse une famille continuer sans la piece', () {
    testWidgets('seule la piece manque : continuer est propose', (
      WidgetTester tester,
    ) async {
      await _monterAttente(
        tester,
        _dossier(role: AppRole.guardian, accuse: true, contrat: true),
      );

      expect(find.text(t.classes.kyc.continuerSansPiece), findsOneWidget);
      // La piece reste proposee : elle n'est pas cachee, elle attend.
      expect(find.text(t.attente.deposerLaPiece), findsOneWidget);

      await tester.tap(find.text(t.classes.kyc.continuerSansPiece));
      await tester.pumpAndSettle();
      expect(find.text('accueil-tuteur'), findsOneWidget);
    });

    testWidgets('le contrat ou l accuse manquants : pas de raccourci', (
      WidgetTester tester,
    ) async {
      await _monterAttente(tester, _dossier(role: AppRole.guardian));
      expect(find.text(t.classes.kyc.continuerSansPiece), findsNothing);
    });

    testWidgets('un enseignant ne continue jamais sans sa piece', (
      WidgetTester tester,
    ) async {
      await _monterAttente(
        tester,
        _dossier(role: AppRole.teacher, accuse: true, contrat: true),
      );
      expect(find.text(t.classes.kyc.continuerSansPiece), findsNothing);
    });
  });
}
