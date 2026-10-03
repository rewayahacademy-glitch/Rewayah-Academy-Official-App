// Captures de recette de COUPE-MOTS-1 (part 1/2 : composants partages et
// Mes Classes), avec PASTILLE-COUPE-1 et CORR-SUITE-2 : vraies polices, vrai
// theme, vraies coquilles de demonstration.
//
// - Mes Classes (ENS-09) a 320, 390 et 1280 px, texte x2, LTR et RTL ;
// - un ecran par role touche, 320 px, texte x1 et x2, clair et sombre :
//   enseignant (Mes Classes dans sa coquille, barre basse « Disponibilites »),
//   controleur (Echanges), tuteur (Historique et son controle segmente),
//   administration (Dossiers) ;
// - les rails (enseignant, controleur) a 768 et les barres laterales (tuteur,
//   administration) a 1440, x1 et x2, clair et sombre ;
// - le titre de la salle « Seance en direct » a 320, x1 et x2, clair et
//   sombre (titre toujours plus grand que son sous-titre).
//
// Chaque capture mesure aussi, en vraies polices, qu'aucun mot de l'ECRAN
// ENTIER (chaque Scaffold, plus la navigation) n'est coupe ni tronque ; le
// rail ne descend jamais sous la taille du theme.
//
// Eleve et famille : aucune capture ici, leurs ecrans d'accueil et la
// journee appartiennent a la voie Bento (fichiers interdits a ce lot).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie versionnee
// dans `docs/current/captures/COUPE-MOTS-1/`. Donnees : fixtures synthetiques
// de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart'
    show echelleMinimaleLisible;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
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

/// L'ecran ENTIER (tout le cadre capture : corps, cartes, legendes, titres,
/// navigation, salle comprise) : aucun mot coupe ni tronque. Aucune
/// exception d'ellipse. Seule permission : un nom compose passe a la ligne
/// APRES son trait d'union (« Classe Al- / Badr »), chaque partie restant
/// entiere, comme le fait le moteur de texte (question au directeur).
void _mesurer(WidgetTester tester) {
  final List<String> fautes = motsCoupes(
    tester,
    find.byKey(cadreCapture),
    traitDUnionPermis: true,
  );
  if (fautes.isNotEmpty) debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
  expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
}

/// Le rail a libelles ne descend jamais sous `echelleMinimaleLisible`
/// (0,85) : il s'elargirait plutot (relecture COUPE-MOTS-1). En vraies
/// polices, francais, il garde sa largeur de base (80).
void _railBorne(WidgetTester tester) {
  final Finder rail = find.byKey(NavShell.railKey);
  if (rail.evaluate().isEmpty) return;
  for (final RenderParagraph p in tester.renderObjectList<RenderParagraph>(
    find.descendant(of: rail, matching: find.byType(RichText)),
  )) {
    debugPrint(
      'RAIL « ${p.text.toPlainText()} » echelle '
      '${p.textScaler.scale(1).toStringAsFixed(3)}',
    );
    expect(
      p.textScaler.scale(1),
      greaterThanOrEqualTo(echelleMinimaleLisible),
      reason: '« ${p.text.toPlainText()} » sous le plancher',
    );
  }
  expect(tester.getSize(rail).width, AppGabarit.largeurRail);
}

/// La taille rendue d'un paragraphe (taille du style, a son echelle).
double _tailleRendue(RenderParagraph p) =>
    p.textScaler.scale(p.text.style?.fontSize ?? 14);

/// Le titre de la salle reste plus grand que son sous-titre : la reduction
/// pour tenir dans ses lignes ne renverse jamais la hierarchie.
void _titreSalleAuDessusDuSousTitre(WidgetTester tester) {
  final Finder titre = find.text('Séance en direct');
  final Finder sousTitre = find.textContaining('min restantes');
  if (titre.evaluate().isEmpty || sousTitre.evaluate().isEmpty) return;
  final RenderParagraph t = tester.renderObject<RenderParagraph>(
    find.descendant(of: titre.first, matching: find.byType(RichText)).first,
  );
  final RenderParagraph s = tester.renderObject<RenderParagraph>(
    find.descendant(of: sousTitre.first, matching: find.byType(RichText)).first,
  );
  debugPrint(
    'SALLE titre ${_tailleRendue(t).toStringAsFixed(1)} / sous-titre '
    '${_tailleRendue(s).toStringAsFixed(1)}',
  );
  expect(_tailleRendue(t), greaterThan(_tailleRendue(s)));
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
          if (largeur >= 1280) {
            // CORR-SUITE-2, en vraies polices : a 1280 x2, la marque (passee
            // sous la legende) tient sur une seule ligne.
            final RenderParagraph p = tester.renderObject<RenderParagraph>(
              find.text(t.enseignant.classes.cahierAValider),
            );
            expect(<int>{
              for (final TextBox b in p.getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: p.text.toPlainText().length,
                ),
              ))
                b.top.round(),
            }, hasLength(1));
          }
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

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double echelle in <double>[1, 2]) {
        final String suffixe = '${_x(echelle)}_${mode.name}';

        testWidgets('enseignant rail 768 $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(768, 1024), 1);
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
          _railBorne(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'enseignant_rail_768_$suffixe')}',
          );
        });

        testWidgets('controleur rail 768 $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(768, 1024), 1);
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
          _railBorne(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'controleur_rail_768_$suffixe')}',
          );
        });

        testWidgets('tuteur barre laterale 1440 $suffixe', (
          WidgetTester tester,
        ) async {
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
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'tuteur_barre_laterale_1440_$suffixe')}',
          );
        });

        testWidgets('admin barre laterale 1440 $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
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
            'PNG ${await capturer(tester, 'admin_barre_laterale_1440_$suffixe')}',
          );
        });

        testWidgets('salle « Seance en direct » 320 $suffixe', (
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
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester);
          _titreSalleAuDessusDuSousTitre(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'salle_titre_320_$suffixe')}',
          );
        });
      }
    }
  });
}
