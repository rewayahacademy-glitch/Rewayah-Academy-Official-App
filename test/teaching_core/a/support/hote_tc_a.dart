import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../faux/faux_reseau.dart';

/// L'hote minimal d'un ecran d'Agent A.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un ecran monte sans elles echoue avant d'avoir rendu
/// quoi que ce soit. `TranslationProvider` l'est aussi : `PageShell` porte
/// `OfflineBanner`, qui lit une cle slang.
///
/// Cet hote vit dans `test/teaching_core/a/support/` et non dans
/// `test/support/harnais.dart`, qui est un fichier unique partage et deja
/// modifie par un autre chantier (decision `D-06`).
Widget hoteTcA(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: enfant,
    ),
  ),
);

/// L'hote d'un ecran qui navigue.
///
/// Le `GoRouter` est construit **ici**, dans `test/`, et jamais dans `lib/` :
/// `tool/verifier_jetons.dart` fait echouer la CI si un second fichier de
/// `lib/` en construit un (decision `D-04`).
Widget hoteRoutantTcA({
  required String depart,
  required List<RouteBase> routes,
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(mode, Brightness.light),
      routerConfig: GoRouter(initialLocation: depart, routes: routes),
    ),
  ),
);

/// Les surcharges du jeu de demonstration, arretees a un instant donne.
///
/// La cadence nulle ferme le flux apres sa premiere valeur : un minuteur qui
/// survivrait a la fin d'un test ferait echouer le suivant.
List<Override> surchargesDemonstration({
  DateTime? maintenant,
  bool horsLigne = false,
}) {
  final HorlogeSeanceDemonstration horloges = HorlogeSeanceDemonstration(
    horloge: maintenant == null ? null : (() => maintenant),
    cadence: Duration.zero,
  );
  return <Override>[
    portHorlogeSeanceProvider.overrideWithValue(horloges),
    portGroupesProvider.overrideWithValue(
      GroupesDemonstrationLocale(horloges: horloges),
    ),
    serviceReseauProvider.overrideWithValue(
      FauxServiceReseau(horsLigneMaintenant: horsLigne),
    ),
  ];
}

/// Pose une largeur d'ecran pour un test, et la rend a la fin.
///
/// **Aucun test ne compare une largeur a un nombre lui-meme** : les trois
/// valeurs ci-dessous encadrent les seuils de `AppGabarit`, qui reste le seul
/// endroit du produit autorise a les connaitre.
Future<void> avecLargeur(
  WidgetTester tester,
  double largeur,
  Future<void> Function() corps,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largeur, 1400);
  addTearDown(tester.view.reset);
  await corps();
}

/// Largeur de telephone : une colonne.
const double largeurMobile = 390;

/// Largeur de tablette : deux colonnes si utile.
const double largeurTablette = 900;

/// Largeur de bureau : contenu centre, jamais etire.
const double largeurDesktop = 1440;
