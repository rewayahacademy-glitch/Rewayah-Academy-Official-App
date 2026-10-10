// Le montage commun des tests de la voie CPT-PAY : la page sous un routeur
// minimal (la liste, le detail, le profil de paiement), les ports de la
// demonstration ou un double, le reseau et la visibilite des montants
// fixes. Aucun appel reseau.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_capacite_payout.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/capacites/port_payout.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';

/// La visibilite de depart fixee pour un test.
class VisibiliteFixe extends VisibiliteMontants {
  /// Cree la visibilite.
  VisibiliteFixe(this._initiale);

  final bool _initiale;

  @override
  bool build() => _initiale;
}

/// Les surcharges de la demonstration sur un [etat] connu du test.
List<Override> surchargesDemo(
  EtatDemoPaiements etat, {
  bool horsLigne = false,
  bool montantsAffiches = false,
}) => <Override>[
  portObligationsPayablesProvider.overrideWithValue(
    ObligationsPayablesDemo(etat),
  ),
  portPayoutProvider.overrideWithValue(PayoutDemo(etat)),
  portCapacitePayoutProvider.overrideWithValue(const CapacitePayoutDemo()),
  ...surchargesCommunes(
    horsLigne: horsLigne,
    montantsAffiches: montantsAffiches,
  ),
];

/// Le reseau et la visibilite des montants.
List<Override> surchargesCommunes({
  bool horsLigne = false,
  bool montantsAffiches = false,
}) => <Override>[
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  visibiliteMontantsProvider.overrideWith(
    () => VisibiliteFixe(montantsAffiches),
  ),
];

/// Le chemin du profil de paiement dans le routeur de test.
const String cheminProfilTest = '/comptable/paiements/beneficiaires/:id';

/// Monte [page] a la taille [taille] sous un routeur minimal.
Future<GoRouter> monterPaiements(
  WidgetTester tester,
  Widget page, {
  required List<Override> surcharges,
  Size taille = const Size(1440, 900),
  double texte = 1,
  bool attendre = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final GoRouter routeur = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => page),
      GoRoute(
        path: '/comptable/paiements/obligation/:id',
        builder: (BuildContext _, GoRouterState etat) =>
            DetailPaiementPage(obligationId: etat.pathParameters['id']!),
      ),
      GoRoute(
        path: '/comptable/paiements',
        builder: (BuildContext _, GoRouterState _) =>
            const PaiementsAEffectuerPage(),
      ),
      GoRoute(
        path: cheminProfilTest,
        builder: (BuildContext _, GoRouterState etat) =>
            Text('profil ${etat.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
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

/// Un port d'obligations pilote par le test : chargement sans fin, vide,
/// erreur, ou une liste donnee.
class ObligationsPilotees implements PortObligationsPayables {
  /// Cree le double.
  ObligationsPilotees({this.erreur, this.rendues, this.attente});

  /// L'erreur a jeter, si non nulle.
  Object? erreur;

  /// La liste a rendre.
  List<ObligationPayable>? rendues;

  /// Une attente sans fin (chargement).
  Completer<List<ObligationPayable>>? attente;

  /// Le nombre de lectures de la liste.
  int lectures = 0;

  @override
  Future<List<ObligationPayable>> liste(FiltreObligations filtre) {
    lectures++;
    final Completer<List<ObligationPayable>>? a = attente;
    if (a != null) return a.future;
    final Object? e = erreur;
    if (e != null) return Future<List<ObligationPayable>>.error(e);
    return Future<List<ObligationPayable>>.value(
      rendues ?? const <ObligationPayable>[],
    );
  }

  @override
  Future<ObligationPayable> detail(String obligationId) {
    final Object? e = erreur;
    if (e != null) return Future<ObligationPayable>.error(e);
    return Future<ObligationPayable>.value(
      (rendues ?? const <ObligationPayable>[]).firstWhere(
        (ObligationPayable o) => o.id == obligationId,
      ),
    );
  }

  @override
  Future<SignalementEcart> signalerEcart({
    required String obligationId,
    required String ligneId,
    required String motif,
    required String cleIdempotence,
  }) => Future<SignalementEcart>.error(StateError('signalement refuse'));

  @override
  Future<List<EntreeJournal>> journal(String obligationId) async =>
      const <EntreeJournal>[];
}
