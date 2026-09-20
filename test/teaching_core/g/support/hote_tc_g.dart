import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../faux/faux_observation.dart';

/// L'hote minimal d'un composant d'observation sous test.
///
/// **Le sien, pas celui du depot.** `test/support/harnais.dart` est un fichier
/// unique de quarante kilo-octets deja modifie par le chantier enseignant : la
/// decision D-06 confie a chaque agent son propre hote sous
/// `test/teaching_core/<lettre>/support/`. Agent Z consolidera a
/// l'integration, pas avant.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un composant monte sans elles echoue avant d'avoir
/// rendu quoi que ce soit.
Widget hoteTcG(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: enfant),
        ),
      ),
    ),
  ),
);

/// L'hote d'un ecran d'observation qui navigue.
///
/// Le `GoRouter` est construit **ici**, hors de `lib/` : `verifier_jetons.dart`
/// refuse un second routeur dans `lib/`, et `routesTcG()` se contente donc de
/// retourner des routes. C'est ce test qui prouve qu'elles se montent.
Widget hoteRoutantTcG({
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

/// Une source de session en memoire, resolue d'emblee.
class FausseSourceSessionTcG implements SourceSession {
  /// Cree la source pour un role donne.
  FausseSourceSessionTcG(this.role);

  /// Le role porte par le jeton.
  final AppRole? role;

  @override
  Stream<SessionState> etats() => Stream<SessionState>.value(
    SessionState(
      resolue: true,
      role: role,
      profileId: 'p1',
      accountStatus: AccountStatus.active,
      lectureProfil: LectureProfil.presente,
    ),
  );

  @override
  Future<void> rafraichir() async {}
}

/// Les surcharges d'un ecran d'observation sous test.
List<Override> surchargesTcG({
  AppRole? role,
  FauxPortVisite? visites,
  FauxPortPolitique? politique,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSessionTcG(role)),
  portVisiteObservationProvider.overrideWithValue(visites ?? FauxPortVisite()),
  portPolitiqueObservationProvider.overrideWithValue(
    politique ?? FauxPortPolitique(),
  ),
];
