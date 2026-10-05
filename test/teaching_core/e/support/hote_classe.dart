import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3 : il vit
// dans `misc.dart`, alors que `ProviderScope.overrides` en attend une liste.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';
import 'package:rewayah_academy/features/tc_classe_live/routes_tc_e.dart';

import '../faux/faux_classe.dart';

/// L'hote de test d'Agent E.
///
/// **Le `GoRouter` est construit ICI, hors de `lib/`** (decision D-04) :
/// `tool/verifier_jetons.dart` fait echouer la CI si un second fichier de `lib/`
/// en construit un. `routesTcE()` retourne des routes ; c'est ce fichier, et
/// Agent Z a l'integration, qui les monte.

/// Les trois largeurs de reference du produit.
///
/// Elles ne sont pas choisies : ce sont les seuils de `AppGabarit` -- 600 et
/// 1200 -- encadres du telephone de reference, 390 sur 844.
enum LargeurEcran {
  /// Telephone de reference.
  mobile(Size(390, 844)),

  /// Tablette en paysage, au-dessus du seuil de 600.
  tablette(Size(900, 700)),

  /// Bureau, au-dessus du seuil de 1200.
  desktop(Size(1400, 900));

  const LargeurEcran(this.taille);

  /// La surface simulee.
  final Size taille;
}

/// Pose la surface de test et la remet en place a la fin.
void poserEcran(WidgetTester tester, LargeurEcran ecran) {
  tester.view.physicalSize = ecran.taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Les surcharges d'une Classe Live de test.
List<Override> surchargesClasse({
  required FauxMoteurClasse moteur,
  required FauxServiceVideoClasse video,
  required FauxPreVolClasse preVol,
  FauxPresenceClasse? presence,
  FauxRosterEnseignant? roster,
  PortRappelDiscret? rappel,
  FauxAnnonceObservation? annonces,
  FauxAnnonceObservationEnfant? annonceEnfant,
}) => <Override>[
  servicePreVolProvider.overrideWithValue(preVol),
  serviceVideoProvider.overrideWithValue(video),
  moteurSalleProvider.overrideWithValue(moteur),
  // **Indisponible par defaut, et c'est le bon defaut** : un test qui ne parle
  // pas de presence doit exercer le repli de l'invariant J3, pas un tableau
  // rempli par commodite.
  servicePresenceProvider.overrideWithValue(presence ?? FauxPresenceClasse()),
  portRosterEnseignantProvider.overrideWithValue(
    roster ?? FauxRosterEnseignant(),
  ),
  // **Personne n'observe par defaut, et c'est le bon defaut** : le vrai port
  // parlerait a Supabase, et un test qui ne dit rien de l'observation doit
  // exercer l'en-tete sans annonce, pas une salle observee par commodite.
  portAnnonceObservationProvider.overrideWithValue(
    annonces ?? FauxAnnonceObservation(),
  ),
  // **Le tuteur de l'eleve n'observe pas par defaut**, meme raison : le vrai
  // port appellerait `annonce_observation_pour_moi` sur Supabase.
  portAnnonceObservationEnfantProvider.overrideWithValue(
    annonceEnfant ?? FauxAnnonceObservationEnfant(),
  ),
  if (rappel != null) portRappelDiscretProvider.overrideWithValue(rappel),
];

/// L'hote minimal d'un widget sous test.
///
/// Le theme est indispensable : `AppPalette.of` et `AppMetriques.of` lisent des
/// extensions de theme, et un widget monte sans elles echoue avant d'avoir rendu
/// quoi que ce soit.
Widget hoteClasse(
  Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(mode, Brightness.light),
      home: Scaffold(body: enfant),
    ),
  ),
);

/// Monte la Classe Live dans un routeur minimal.
///
/// La destination de sortie est reelle : sans elle, on testerait une sortie qui
/// ne mene nulle part.
Future<void> monterClasse(
  WidgetTester tester, {
  required ContexteClasseLive contexte,
  required List<Override> surcharges,
  LargeurEcran ecran = LargeurEcran.tablette,
  InterfaceMode mode = InterfaceMode.standard,
  Brightness luminosite = Brightness.light,
  bool mouvementReduit = false,
}) async {
  poserEcran(tester, ecran);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(mode, luminosite),
          // Pendant une visite, le point d'enregistrement clignote sans fin :
          // `pumpAndSettle` ne s'arreterait jamais. Le mouvement reduit le
          // fige (`AppMouvement.mouvementReduit`), sans rien changer d'autre.
          builder: mouvementReduit
              ? (BuildContext context, Widget? enfant) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: true),
                  child: enfant ?? const SizedBox.shrink(),
                )
              : null,
          routerConfig: GoRouter(
            initialLocation: RoutesTcE.classe,
            routes: <RouteBase>[
              GoRoute(
                path: RoutesTcE.classe,
                builder: (BuildContext _, GoRouterState _) =>
                    ClasseLivePage(contexte: contexte),
              ),
              GoRoute(
                path: '/tc/groupe-de-test',
                builder: (BuildContext _, GoRouterState _) =>
                    const Text('espace groupe'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
