// Le montage commun des tests de W06 (CPT-CTR-1) : les trois pages de la voie
// sur un routeur minimal (la liste, le detail, le formulaire et un W03 de
// substitution), le port de demonstration, le reseau et la visibilite des
// montants fixes. Aucun serveur.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_contractuels.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/contractuels/contractuels_page.dart';
import 'package:rewayah_academy/features/comptable/contractuels/nouvelle_obligation_page.dart';
import 'package:rewayah_academy/features/comptable/contractuels/obligation_contractuel_page.dart';
import 'package:rewayah_academy/features/demo/comptable/contractuels_demo.dart';

/// Le texte du W03 de substitution : « Detail du paiement ID ».
String texteW03(String id) => 'W03 $id';

class _Visibilite extends VisibiliteMontants {
  _Visibilite(this._initiale);

  final bool _initiale;

  @override
  bool build() => _initiale;
}

/// Monte W06 a [depart] et rend le routeur.
Future<GoRouter> monterContractuels(
  WidgetTester tester, {
  String depart = Routes.comptableContractuels,
  PortObligationsContractuels? port,
  bool horsLigne = false,
  bool montantsAffiches = false,
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.comptableContractuels,
        builder: (BuildContext _, GoRouterState e) =>
            ContractuelsPage(onglet: e.uri.queryParameters['onglet']),
      ),
      GoRoute(
        path: Routes.comptableContractuelsNouvelle,
        builder: (BuildContext _, GoRouterState _) =>
            const NouvelleObligationPage(),
      ),
      GoRoute(
        path: '${Routes.comptableContractuelsObligation}/:obligationId',
        builder: (BuildContext _, GoRouterState e) => ObligationContractuelPage(
          obligationId: e.pathParameters['obligationId']!,
        ),
      ),
      GoRoute(
        path: '${Routes.comptablePaiementsObligation}/:obligationId',
        builder: (BuildContext _, GoRouterState e) =>
            Scaffold(body: Text(texteW03(e.pathParameters['obligationId']!))),
      ),
    ],
  );
  final List<Override> surcharges = <Override>[
    portObligationsContractuelsProvider.overrideWithValue(
      port ?? ObligationsContractuelsDemo(),
    ),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    visibiliteMontantsProvider.overrideWith(
      () => _Visibilite(montantsAffiches),
    ),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
          builder: (BuildContext context, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: enfant!,
          ),
        ),
      ),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return routeur;
}

/// Un port dont la lecture ne rend jamais : l'etat « chargement ».
class PortSansFin extends ObligationsContractuelsDemo {
  /// Cree le port.
  PortSansFin();

  final Completer<void> _jamais = Completer<void>();

  @override
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  ) async {
    await _jamais.future;
    return const <ObligationContractuel>[];
  }
}

/// Un port vide.
class PortVide extends ObligationsContractuelsDemo {
  /// Cree le port.
  PortVide({super.peutCreer});

  @override
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  ) async => const <ObligationContractuel>[];
}

/// Un port dont la lecture echoue avec [erreur].
class PortEnEchec extends ObligationsContractuelsDemo {
  /// Cree le port.
  PortEnEchec(this.erreur);

  /// L'erreur jetee par la lecture.
  final Object erreur;

  @override
  Future<List<ObligationContractuel>> liste(
    FiltreObligationsContractuels filtre,
  ) => Future<List<ObligationContractuel>>.error(erreur);
}
