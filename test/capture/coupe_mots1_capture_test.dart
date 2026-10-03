// Captures de recette de COUPE-MOTS-1 (part 1/2 : composants partages et
// Mes Classes), avec PASTILLE-COUPE-1 et CORR-SUITE-2 : vraies polices, vrai
// theme, vraies coquilles de demonstration.
//
// - Mes Classes (ENS-09) a 320, 390 et 1280 px, texte x2, LTR et RTL ;
// - un ecran par role touche, 320 px, texte x1 et x2, clair et sombre :
//   enseignant (Mes Classes dans sa coquille, barre basse « Disponibilites »),
//   controleur (Echanges), tuteur (Historique et son controle segmente),
//   administration (Dossiers) ;
// - les barres laterales et le rail : enseignant a 768 x1, controleur a 768
//   x2, tuteur et administration a 1440 x2 ;
// - le titre de la salle « Seance en direct » a 320 x2.
//
// Chaque capture mesure aussi, en vraies polices, qu'aucun mot de la
// navigation, des pastilles et des en-tetes n'est coupe ni tronque.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie versionnee
// dans `docs/current/captures/COUPE-MOTS-1/`. Donnees : fixtures synthetiques
// de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart'
    show maintenantJourneeProvider;
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Monte [routeur] dans le cadre de capture, a l'echelle et dans le sens
/// donnes.
Future<void> _monter(
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

String _x(double echelle) => 'x${echelle.round()}';

/// La navigation, les pastilles et les en-tetes : aucun mot coupe.
void _mesurer(WidgetTester tester) {
  for (final Finder f in <Finder>[
    find.byKey(NavShell.barreBasseKey),
    find.byKey(NavShell.railKey),
    find.byKey(NavShell.barreLateraleKey),
    find.byKey(AdminShell.barreLateraleKey),
    find.byType(StatusPill),
    find.byType(EntetePage),
    find.byWidgetPredicate((Widget w) => w is ControleSegmente),
  ]) {
    if (f.evaluate().isNotEmpty) verifierAucunMotCoupe(tester, f);
  }
}

void main() {
  group('Capture : COUPE-MOTS-1', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    // Mes Classes, avec la pastille « Remplacement » et le cahier a valider
    // sur la meme ligne (Al-Badr), comme le test ENS-09.
    final GroupeEnseignant badr = DonneesEnseignantDemo.groupes().firstWhere(
      (GroupeEnseignant g) => g.libelle == 'Al-Badr',
    );
    final List<Override> surchargesClasses = <Override>[
      maintenantJourneeProvider.overrideWithValue(
        () => DonneesEnseignantDemo.maintenant,
      ),
      groupesEnseignantProvider.overrideWith(
        (Ref _) async => DonneesEnseignantDemo.groupes(),
      ),
      seancesEnseignantProvider.overrideWith(
        (Ref _) async =>
            DonneesEnseignantDemo.seances(EtatDemoEnseignant.nominal),
      ),
      cahiersEnRetardProvider.overrideWith(
        (Ref _) async =>
            DonneesEnseignantDemo.cahiersEnRetard(EtatDemoEnseignant.nominal),
      ),
      detailsClassesProvider.overrideWithValue(<String, DetailClasse>{
        badr.id: const DetailClasse(
          niveau: 2,
          langue: 'Français',
          remplacement: true,
        ),
      }),
    ];

    for (final double largeur in <double>[320, 390, 1280]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('Mes Classes $largeur x2 ${sens.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, Size(largeur, 900), 2);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: sens,
                child: const MesClassesPage(),
              ),
              surcharges: surchargesClasses,
              echelleTexte: 2,
            ),
          );
          await stabiliser(tester);
          _mesurer(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'mes_classes_${largeur.round()}_x2_${sens.name}')}',
          );
        });
      }
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double echelle in <double>[1, 2]) {
        testWidgets('enseignant 320 ${_x(echelle)} ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 700), 2);
          await _monter(
            tester,
            routeur: (WidgetRef _) => GoRouter(
              initialLocation: adresseDemoEnseignant(
                EcranDemoEnseignant.classes,
              ),
              routes: routesDemoEnseignant('dev'),
            ),
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'enseignant_classes_320_${_x(echelle)}_${mode.name}')}',
          );
        });

        testWidgets('controleur 320 ${_x(echelle)} ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 700), 2);
          await _monter(
            tester,
            routeur: (WidgetRef _) => GoRouter(
              initialLocation: adresseDemoControleur(
                EcranDemoControleur.echanges,
              ),
              routes: routesDemoControleur('dev'),
            ),
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'controleur_echanges_320_${_x(echelle)}_${mode.name}')}',
          );
        });

        testWidgets('tuteur 320 ${_x(echelle)} ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 700), 2);
          final FauxServiceAppairage appairage = FauxServiceAppairage()
            ..elevesRendus = FoyersFictifs.foyerA;
          await _monter(
            tester,
            routeur: (WidgetRef ref) => ref.read(routeurProvider),
            surcharges: surchargesRouteur(
              FausseSourceSession(sessionActive(AppRole.guardian)),
              appairage: appairage,
            ),
            depart: Routes.tuteurSuivi,
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'tuteur_historique_320_${_x(echelle)}_${mode.name}')}',
          );
        });

        testWidgets('admin 320 ${_x(echelle)} ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 700), 2);
          await _monter(
            tester,
            routeur: (WidgetRef ref) => ref.read(routeurProvider),
            surcharges: surchargesDemoAdmin(environnement: 'staging'),
            depart: Routes.adminPersonnesDossiers,
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'admin_dossiers_320_${_x(echelle)}_${mode.name}')}',
          );
        });
      }
    }

    testWidgets('enseignant rail 768 x1', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(768, 900), 1);
      await _monter(
        tester,
        routeur: (WidgetRef _) => GoRouter(
          initialLocation: adresseDemoEnseignant(EcranDemoEnseignant.classes),
          routes: routesDemoEnseignant('dev'),
        ),
        mode: ThemeMode.light,
        echelle: 1,
      );
      _mesurer(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'enseignant_rail_768_x1_light')}',
      );
    });

    testWidgets('controleur rail 768 x2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(768, 1024), 1);
      await _monter(
        tester,
        routeur: (WidgetRef _) => GoRouter(
          initialLocation: adresseDemoControleur(EcranDemoControleur.echanges),
          routes: routesDemoControleur('dev'),
        ),
        mode: ThemeMode.light,
        echelle: 2,
      );
      _mesurer(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'controleur_rail_768_x2_light')}',
      );
    });

    testWidgets('tuteur barre laterale 1440 x2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = FoyersFictifs.foyerA;
      await _monter(
        tester,
        routeur: (WidgetRef ref) => ref.read(routeurProvider),
        surcharges: surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        depart: Routes.tuteurSuivi,
        mode: ThemeMode.light,
        echelle: 2,
      );
      _mesurer(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'tuteur_barre_laterale_1440_x2_light')}',
      );
    });

    testWidgets('admin barre laterale 1440 x2', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monter(
        tester,
        routeur: (WidgetRef ref) => ref.read(routeurProvider),
        surcharges: surchargesDemoAdmin(environnement: 'staging'),
        depart: Routes.adminPersonnesDossiers,
        mode: ThemeMode.light,
        echelle: 2,
      );
      _mesurer(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'admin_barre_laterale_1440_x2_light')}',
      );
    });

    testWidgets('salle « Seance en direct » 320 x2', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 700), 2);
      await _monter(
        tester,
        routeur: (WidgetRef _) => GoRouter(
          initialLocation: adresseDemoSalle(
            RoleSeance.enseignant,
            EtatDemoSalle.repos,
          ),
          routes: routesDemoSalle('dev'),
        ),
        mode: ThemeMode.light,
        echelle: 2,
      );
      debugPrint('PNG ${await capturer(tester, 'salle_titre_320_x2_light')}');
    });
  });
}
