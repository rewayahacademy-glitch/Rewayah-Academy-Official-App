// Un ecran reel par role, monte dans sa vraie coquille (routeur, theme,
// navigation), pour mesurer qu'aucun mot de l'ECRAN ENTIER n'est coupe ni
// tronque (COUPE-MOTS-1, revue COUPE-MOTS-1-R M2).
//
// Partage entre les captures de recette (`test/capture/coupe_mots1_capture_test.dart`,
// sautees sans CAPTURE_DIR) et la mesure qui tourne toujours en CI
// (`test/accessibilite/ecrans_roles_sans_coupure_test.dart`) : les deux
// mesurent exactement les memes ecrans.
//
// Donnees : fixtures synthetiques de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../capture/outil_capture.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import 'aucun_mot_coupe.dart';
import 'harnais.dart';

/// Un ecran de role : son routeur, ses surcharges et son adresse de depart.
typedef EcranRole = ({
  String nom,
  GoRouter Function(WidgetRef ref) routeur,
  List<Override> Function() surcharges,
  String? depart,
});

List<Override> _aucune() => const <Override>[];

/// L'ecran mesure de chaque role : enseignant (Mes Classes, barre basse
/// « Disponibilites »), controleur (Echanges), tuteur (Historique et son
/// controle segmente), administration (Dossiers), salle (« Seance en
/// direct », cote enseignant). Eleve et famille : leurs accueils sont
/// mesures par leurs propres tests (`accueil_eleve_test`, `accueil_ma_prod_test`).
final List<EcranRole> ecransParRole = <EcranRole>[
  (
    nom: 'enseignant',
    routeur: (WidgetRef _) => GoRouter(
      initialLocation: adresseDemoEnseignant(EcranDemoEnseignant.classes),
      routes: routesDemoEnseignant('dev'),
    ),
    surcharges: _aucune,
    depart: null,
  ),
  (
    nom: 'controleur',
    routeur: (WidgetRef _) => GoRouter(
      initialLocation: adresseDemoControleur(EcranDemoControleur.echanges),
      routes: routesDemoControleur('dev'),
    ),
    surcharges: _aucune,
    depart: null,
  ),
  (
    nom: 'tuteur',
    routeur: (WidgetRef ref) => ref.read(routeurProvider),
    surcharges: () => surchargesRouteur(
      FausseSourceSession(sessionActive(AppRole.guardian)),
      appairage: FauxServiceAppairage()..elevesRendus = FoyersFictifs.foyerA,
    ),
    depart: Routes.tuteurSuivi,
  ),
  (
    nom: 'admin',
    routeur: (WidgetRef ref) => ref.read(routeurProvider),
    surcharges: () => surchargesDemoAdmin(environnement: 'staging'),
    depart: Routes.adminPersonnesDossiers,
  ),
  (
    nom: 'salle',
    routeur: (WidgetRef _) => GoRouter(
      initialLocation: adresseDemoSalle(
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      ),
      routes: routesDemoSalle('dev'),
    ),
    surcharges: _aucune,
    depart: null,
  ),
];

/// L'ecran de role [nom].
EcranRole ecranRole(String nom) =>
    ecransParRole.firstWhere((EcranRole e) => e.nom == nom);

/// Monte [routeur] dans le cadre de capture ([cadreCapture]), a l'echelle
/// et dans le sens donnes.
Future<void> monterEcranRouteur(
  WidgetTester tester, {
  required GoRouter Function(WidgetRef ref) routeur,
  required ThemeMode mode,
  required double echelle,
  List<Override> surcharges = const <Override>[],
  String? depart,
  TextDirection? sens,
}) async {
  late GoRouter r;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              r = routeur(ref);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: r,
                builder: (BuildContext contexte, Widget? app) {
                  final Widget echelonne = MediaQuery(
                    data: MediaQuery.of(contexte)
                        .copyWith(textScaler: TextScaler.linear(echelle)),
                    child: app!,
                  );
                  return sens == null
                      ? echelonne
                      : Directionality(textDirection: sens, child: echelonne);
                },
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (depart != null) {
    r.go(depart);
    await stabiliser(tester);
  }
}

/// Monte l'ecran de role [ecran].
Future<void> monterEcranRole(
  WidgetTester tester,
  EcranRole ecran, {
  required ThemeMode mode,
  required double echelle,
}) => monterEcranRouteur(
  tester,
  routeur: ecran.routeur,
  surcharges: ecran.surcharges(),
  depart: ecran.depart,
  mode: mode,
  echelle: echelle,
);

/// L'ecran ENTIER (tout le cadre capture : corps, cartes, legendes, titres,
/// navigation, salle comprise) : aucun mot coupe ni tronque. Aucune
/// exception d'ellipse. Seule permission : un nom compose passe a la ligne
/// APRES son trait d'union (« Classe Al- / Badr »), chaque partie restant
/// entiere, comme le fait le moteur de texte (question au directeur).
void mesurerEcranEntier(WidgetTester tester) {
  final List<String> fautes = motsCoupes(
    tester,
    find.byKey(cadreCapture),
    traitDUnionPermis: true,
  );
  if (fautes.isNotEmpty) debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
  expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
}
