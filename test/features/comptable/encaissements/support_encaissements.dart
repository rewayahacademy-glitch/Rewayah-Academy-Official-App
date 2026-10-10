// L'hote des tests de la voie CPT-ENC : vrai theme clair ou sombre, sens,
// echelle du texte, reseau simule, visibilite des montants partant masquee
// (R-FIN-01), et un routeur minimal (liste, detail, rapprochement) pour les
// navigations de la page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/encaissements/detail_encaissement_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/encaissements_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement_page.dart';

import '../../../support/harnais.dart';

/// La visibilite de test : masquee au depart, sans session.
class VisibiliteTest extends VisibiliteMontants {
  /// Cree la visibilite.
  VisibiliteTest({this.initiale = false});

  /// L'etat de depart.
  final bool initiale;

  @override
  bool build() => initiale;
}

/// Monte [depart] dans un routeur minimal et rend le routeur.
Future<GoRouter> monterEncaissements(
  WidgetTester tester,
  String depart, {
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(1440, 900),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
  bool horsLigne = false,
  bool montantsAffiches = false,
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.comptableEncaissements,
        builder: (BuildContext _, GoRouterState etat) => EncaissementsPage(
          filtre: etat.uri.queryParameters[Routes.parametreFiltreComptable],
        ),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (BuildContext _, GoRouterState etat) =>
                DetailEncaissementPage(
                  encaissementId: etat.pathParameters['id']!,
                ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.comptableRapprochement,
        builder: (BuildContext _, GoRouterState _) => const RapprochementPage(),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
        visibiliteMontantsProvider.overrideWith(
          () => VisibiliteTest(initiale: montantsAffiches),
        ),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (BuildContext context, Widget? app) => Directionality(
            textDirection: sens,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  if (attendre) await tester.pumpAndSettle();
  return routeur;
}

/// Tous les textes rendus.
List<String> textesRendus(WidgetTester tester) => <String>[
  for (final Element e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];
