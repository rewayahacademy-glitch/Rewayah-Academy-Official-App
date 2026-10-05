// Captures de recette de la Classe du tuteur et de ses sous-pages (lot C,
// sous-paquet 2), sur le VRAI routeur : 390x844 et 1440x900, clair et
// sombre, tablette 1024x768, etats de production, et planche maquette M1 |
// rendu.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais). Planche :
// CAPTURE_MAQUETTE_CLASSE_MOBILE (M1 decoupee de la planche « Observation
// tuteur », 390 logiques). Donnees : fixtures isolees uniquement, jamais un
// service reel.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/faux_observation.dart';
import 'support_classe.dart';

final String? _maquetteMobile =
    Platform.environment['CAPTURE_MAQUETTE_CLASSE_MOBILE'];

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Le scenario de la maquette M1, en donnees fictives : seance en direct,
/// eleve en salle, observation ouverte en simulation, deux visites.
List<Override> _nominal() => surchargesClasse(
  seances: _nominalSeances(),
  portClasses: classesAvecParcours(),
  observation: true,
  presence: const <PresenceParticipant>[presenceA1],
);

Future<void> _monter(
  WidgetTester tester,
  String chemin, {
  ThemeMode mode = ThemeMode.light,
  List<Override>? surcharges,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges ?? _nominal(),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
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
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(chemin);
  await stabiliser(tester);
}

Future<(int, int)> _taillePx(WidgetTester tester, String chemin) async {
  late int l;
  late int h;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      await File(chemin).readAsBytes(),
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    l = image.width;
    h = image.height;
    image.dispose();
  });
  return (l, h);
}

String _classe([String? segment]) => segment == null
    ? Routes.classePour(classeA, eleveId: eleveA1)
    : '${Routes.classeSousPage(classeA, segment)}?eleve=$eleveA1';

/// Les sous-pages, avec leurs donnees fictives branchees.
Future<List<Override>> _sousPages() async => surchargesClasse(
  seances: _nominalSeances(),
  portClasses: classesAvecParcours(),
  observation: true,
  presence: const <PresenceParticipant>[presenceA1],
  travail: await travauxFictifs(),
  catalogue: FauxCatalogueClasse(<LibraryResource>[
    ressourceFictive('r1', 'Support fictif 1'),
    ressourceFictive('r2', 'Lecon fictive 2', type: TypeRessource.lecon),
    ressourceFictive(
      'r3',
      'Texte fictif 3',
      type: TypeRessource.texteStructure,
    ),
  ]),
  progression: const FausseProgressionClasse(
    ProgressionEleve(
      eleveId: eleveA1,
      niveauHumain: 'Niveau fictif',
      jalons: <String>['Etape fictive 1', 'Etape fictive 2'],
    ),
  ),
);

List<SeanceFamille> _nominalSeances() => <SeanceFamille>[
  seanceEnDirect(duree: const Duration(minutes: 70)),
  seanceSalleOuverte(
    seanceId: 's2',
    avant: const Duration(days: 2),
    heure: '18:00',
    date: 'Mercredi 23 septembre',
  ),
  seanceSalleOuverte(
    seanceId: 's3',
    avant: const Duration(days: 5),
    statut: StatutSeance.annulee,
    heure: '18:00',
    date: 'Samedi 26 septembre',
  ),
];

void main() {
  group('Capture : Classe du tuteur', skip: sautSansCapture, () {
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

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('classe 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, _classe(), mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'classe_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('classe 1440x900 @1, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, _classe(), mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'classe_1440x900@1_${mode.name}')}',
        );
      });

      testWidgets('classe 1024x768 @1, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1024, 768), 1);
        await _monter(tester, _classe(), mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'classe_1024x768@1_${mode.name}')}',
        );
      });

      for (final String segment in <String>[
        'planning',
        'travail',
        'ressources',
        'progression',
      ]) {
        testWidgets('$segment 390x844 @3, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
          await _monter(
            tester,
            _classe(segment),
            mode: mode,
            surcharges: await _sousPages(),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'classe_${segment}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('$segment 1440x900 @1, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _monter(
            tester,
            _classe(segment),
            mode: mode,
            surcharges: await _sousPages(),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'classe_${segment}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }

    testWidgets('classe 390x1400 @2, page entiere, clair', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 1400), 2, zoneSure: _zoneSure);
      await _monter(tester, _classe());
      debugPrint(
        'PNG ${await capturer(tester, 'classe_390x1400@2_page_entiere_light')}',
      );
    });

    // Simulation : le port K6 est ici un double (la classe est lue), seuls
    // l'observation (P3) et l'horloge serveur sont dans leur etat de
    // production. Ce que voit un tuteur en production aujourd'hui (port K6
    // absent, C-1) est la capture `classe_390x844@3_indisponible`.
    testWidgets('classe 390x844 @3, simulation : observation fermee (P3), '
        'horloge serveur absente', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        _classe(),
        surcharges: surchargesClasse(
          seances: <SeanceFamille>[
            seanceSalleOuverte(
              avant: const Duration(hours: 3),
              avecHorloge: false,
            ),
          ],
          horlogeAbsente: true,
        ),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'classe_390x844@3_p3_simulation')}',
      );
    });

    testWidgets('classe 390x844 @3, classes indisponibles (port K6 absent)', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        _classe(),
        surcharges: surchargesClasse(
          portClasses: const ClassesFoyerIndisponible(),
        ),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'classe_390x844@3_indisponible')}',
      );
    });

    testWidgets('classe 390x844 @3, visites epuisees', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        _classe(),
        surcharges: surchargesClasse(
          seances: <SeanceFamille>[seanceEnDirect()],
          observation: true,
          budget: budgetEpuise,
          presence: const <PresenceParticipant>[presenceA1],
        ),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'classe_390x844@3_visites_epuisees')}',
      );
    });

    testWidgets('classe 390x844 @3, lecture en echec', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        _classe(),
        surcharges: surchargesClasse(portClasses: ClassesEnEchecPuisRendues()),
      );
      debugPrint('PNG ${await capturer(tester, 'classe_390x844@3_echec')}');
    });

    testWidgets('classe 390x844 @3, hors ligne', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        _classe(),
        surcharges: surchargesClasse(
          seances: _nominalSeances(),
          portClasses: classesAvecParcours(),
          horsLigne: true,
        ),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'classe_390x844@3_hors_ligne')}',
      );
    });

    for (final String segment in <String>[
      'travail',
      'ressources',
      'progression',
    ]) {
      testWidgets('$segment 390x844 @3, production (source non branchee)', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(tester, _classe(segment), surcharges: surchargesClasse());
        debugPrint(
          'PNG ${await capturer(tester, 'classe_${segment}_390x844@3_production')}',
        );
      });
    }

    testWidgets(
      'planche : Classe mobile clair contre la maquette M1',
      skip: _maquetteMobile == null,
      (WidgetTester tester) async {
        final (int l, int h) = await _taillePx(tester, _maquetteMobile!);
        fixerVueMaquette(
          tester,
          largeurPx: l,
          hauteurPx: h,
          largeurLogique: 390,
          zoneSure: _zoneSure,
        );
        await _monter(tester, _classe());
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'classe_mobile_contre_maquette', _maquetteMobile!)}',
        );
      },
    );
  });
}
