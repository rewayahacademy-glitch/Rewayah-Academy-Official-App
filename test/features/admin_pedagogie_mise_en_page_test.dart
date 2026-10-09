// ONGLETS-COUPE-1 : la sous-navigation de Pedagogie et de Configuration, et
// les pages de Pedagogie, a 320 px, texte x1 et x2, sur le VRAI routeur en
// demonstration admin, avec les VRAIES polices du depot (les captures de
// CAPT-L1-2 ont montre ce que la police de test cache).
//
// Ce qui est mesure :
//   * aucune exception de mise en page (RenderFlex qui deborde) sur les cinq
//     pages de Pedagogie ;
//   * aucun mot coupe dans tout l'ecran (« Fonctionnalite / s ») ;
//   * aucun mot coupe dans le menu ouvert du selecteur de section ;
//   * le menu ouvert s'aligne sur le declencheur (meme bord de debut).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/selecteur_section.dart';

Future<void> _monter(
  WidgetTester tester,
  String route,
  double echelle, {
  ThemeMode mode = ThemeMode.light,
  List<Override> donnees = const <Override>[],
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        ...donnees,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? child) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: child!,
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(route);
  await stabiliser(tester);
}

/// Toutes les exceptions levees pendant le montage, pas seulement la
/// premiere : un ecran qui deborde a plusieurs endroits les nomme tous.
List<String> _exceptions(WidgetTester tester) {
  final List<String> toutes = <String>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    toutes.add('$e'.split('\n').first);
  }
  return toutes;
}

final DateTime _jour = DateTime(2026, 9, 14);

/// Des listes remplies : la demonstration admin ne sert aucune ligne de
/// pedagogie (etat d'erreur), or c'est la liste sous l'introduction et les
/// filtres qui n'avait plus de hauteur.
final List<Override> _listesRemplies = <Override>[
  progressionProvider.overrideWith(
    (Ref _) async => <EleveProgression>[
      for (int i = 0; i < 6; i++)
        EleveProgression(
          studentId: 's$i',
          identifiant: 'eleve-$i',
          prenom: 'Maryam',
          nom: 'Benali',
          groupeId: 'g1',
          groupeLibelle: 'Classe Al-Fajr',
          niveauId: 'n1',
          niveauNomHumain: 'Lecture courante',
          niveauCycle: i.isEven ? 'Fondations' : 'Consolidation',
          niveauDepuis: _jour,
          exceptionActiveId: i == 0 ? 'x1' : null,
          exceptionActiveType: i == 0 ? TypeExceptionProgression.blocage : null,
        ),
    ],
  ),
  evaluationsProvider.overrideWith(
    (Ref _) async => <EvaluationAdmin>[
      for (int i = 0; i < 6; i++)
        EvaluationAdmin(
          id: 'e$i',
          studentId: 's$i',
          identifiant: 'eleve-$i',
          prenom: 'Maryam',
          nom: 'Benali',
          niveauId: 'n1',
          niveauNomHumain: 'Lecture courante',
          type: TypeEvaluation.values[i % TypeEvaluation.values.length],
          statut: StatutEvaluation.values[i % StatutEvaluation.values.length],
          datePrevue: _jour,
          dateRealisee: null,
          resultat: null,
          notes: null,
        ),
    ],
  ),
  anomaliesQualiteProvider.overrideWith(
    (Ref _) async => <AnomalieQualite>[
      for (int i = 0; i < 6; i++)
        AnomalieQualite(
          type:
              TypeAnomalieQualite.values[i % TypeAnomalieQualite.values.length],
          refId: 'r$i',
          studentId: 's$i',
          studentPrenom: 'Maryam',
          studentNom: 'Benali',
          teacherId: 't1',
          teacherPrenom: 'Youssef',
          teacherNom: 'Haddad',
          depuis: _jour,
          controleStatut: StatutControleQualite.ouvert,
          controleNote: null,
        ),
    ],
  ),
  versionsProgrammeProvider.overrideWith(
    (Ref _) async => <VersionProgramme>[
      for (int i = 1; i <= 3; i++)
        VersionProgramme(
          id: 'v$i',
          statut: i == 1
              ? StatutVersionProgramme.brouillon
              : StatutVersionProgramme.publiee,
          numeroVersion: i,
          creeParIdentifiant: 'admin',
          creeParPrenom: 'Amina',
          creeParNom: 'Diallo',
          publieeAt: i == 1 ? null : _jour,
          nombreNiveaux: 6,
          createdAt: _jour,
        ),
    ],
  ),
  niveauxProgrammeProvider.overrideWith(
    (Ref _, String _) async => <NiveauProgramme>[
      for (int i = 0; i < 6; i++)
        NiveauProgramme(
          id: 'n$i',
          codeTechnique: 'niveau_$i',
          nomHumain: 'Lecture courante $i',
          cycle: 'Fondations',
          ordre: i,
          description: null,
        ),
    ],
  ),
];

void main() {
  setUpAll(chargerPolicesDuDepot);

  const List<(String, String)> pages = <(String, String)>[
    ('diagnostics', Routes.adminPedagogieDiagnostics),
    ('progression', Routes.adminPedagogieProgression),
    ('evaluations', Routes.adminPedagogieEvaluations),
    ('programmes', Routes.adminPedagogieProgrammes),
    ('qualite', Routes.adminPedagogieQualite),
    ('configuration', Routes.adminConfigurationFonctionnalites),
  ];

  for (final double echelle in const <double>[1, 2]) {
    final String x = 'x${echelle.toInt()}';
    group('320 $x', () {
      for (final (String nom, String route) p in pages) {
        testWidgets('${p.$1} : aucune exception, aucun mot coupe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 640), 1);
          await _monter(tester, p.$2, echelle);
          expect(_exceptions(tester), isEmpty);
          verifierEcranSansMotCoupe(tester);
        });

        if (p.$1 != 'diagnostics' && p.$1 != 'configuration') {
          testWidgets('${p.$1} : listes remplies, aucune exception, aucun mot '
              'coupe, la derniere carte atteignable', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, const Size(320, 640), 1);
            await _monter(tester, p.$2, echelle, donnees: _listesRemplies);
            expect(_exceptions(tester), isEmpty);
            verifierEcranSansMotCoupe(tester);
            // Tout defile ensemble : la derniere carte se ramene a l'ecran.
            final String marque = p.$1 == 'programmes'
                ? 'Lecture courante'
                : 'Benali';
            final Finder cartes = find.textContaining(marque).hitTestable();
            final Finder toutes = find.textContaining(marque);
            expect(toutes, findsWidgets);
            await tester.scrollUntilVisible(
              toutes.last,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await stabiliser(tester);
            expect(cartes, findsWidgets);
            expect(_exceptions(tester), isEmpty);
          });
        }

        testWidgets('${p.$1} : menu ouvert sans mot coupe, aligne', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 640), 1);
          await _monter(tester, p.$2, echelle);
          _exceptions(tester);
          final Finder menu = find.descendant(
            of: selecteurSection,
            matching: find.byWidgetPredicate((Widget w) => w is MenuFiltre),
          );
          expect(menu, findsOneWidget, reason: 'menu attendu a 320 px');
          await tester.tap(menu);
          await stabiliser(tester);
          final Finder entrees = find.byWidgetPredicate(
            (Widget w) => w is PopupMenuItem,
          );
          expect(entrees, findsWidgets);
          verifierAucunMotCoupe(tester, entrees);
          // Le menu commence au bord du declencheur, pas 2 px avant.
          final Rect declencheur = tester.getRect(menu);
          final Rect liste = tester.getRect(
            find
                .ancestor(of: entrees.first, matching: find.byType(Material))
                .first,
          );
          expect(liste.left, closeTo(declencheur.left, 0.5));
          expect(liste.right, closeTo(declencheur.right, 0.5));
          // Aucune elevation Material : son ombre noire se voyait en sombre
          // et, sous `flutter test`, faisait un trait noir de 6 px qui
          // debordait de 3 px du declencheur. Filet et ombre viennent des
          // jetons.
          final Material surface = tester.widget<Material>(
            find
                .ancestor(of: entrees.first, matching: find.byType(Material))
                .first,
          );
          expect(surface.elevation, 0);
        });
      }
    });
  }
}
