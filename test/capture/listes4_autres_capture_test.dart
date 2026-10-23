// Captures LISTES-1, lot 4 (autres listes) : Classes et Progression, sur la
// VRAIE application et le vrai routeur en demonstration d'administration (la
// coque est dans chaque PNG), 1440x900, clair et sombre. Menu de ligne ouvert
// en plus.
//
// Le meme fichier sert aux captures « avant » (code de depart) et « apres » :
// seul `CAPTURE_DIR` change. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`). Donnees fictives uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import 'outil_capture.dart';

const Size _bureau = Size(1440, 900);

Future<void> _monter(
  WidgetTester tester,
  String route, {
  required ThemeMode mode,
  List<EleveProgression>? eleves,
  List<EvaluationAdmin>? evaluations,
  List<AnomalieQualite>? anomalies,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        if (evaluations != null)
          evaluationsProvider.overrideWith((Ref ref) async => evaluations),
        if (anomalies != null)
          anomaliesQualiteProvider.overrideWith((Ref ref) async => anomalies),
        if (eleves != null)
          progressionProvider.overrideWith((Ref ref) async => eleves),
      ],
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
  routeur.go(route);
  await stabiliser(tester);
  await stabiliser(tester);
}

Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

List<EleveProgression> _eleves() {
  const List<String> prenoms = <String>[
    'Amina',
    'Yacine',
    'Salma',
    'Idris',
    'Maryam',
    'Bilal',
    'Nour',
    'Zayd',
    'Hana',
    'Omar',
    'Lina',
    'Sami',
    'Rania',
    'Anas',
    'Imane',
    'Walid',
  ];
  const List<String> noms = <String>[
    'Test-Alpha',
    'Test-Beta',
    'Test-Gamma',
    'Test-Delta',
    'Test-Epsilon',
    'Test-Zeta',
    'Test-Eta',
    'Test-Theta',
  ];
  const List<String> cycles = <String>[
    'Éveil',
    'Fondations',
    'Approfondissement',
    'Perfectionnement',
  ];
  return <EleveProgression>[
    for (int i = 0; i < 16; i++)
      EleveProgression(
        studentId: 'e$i',
        identifiant: 'RA-26-${4800 + i}',
        prenom: prenoms[i],
        nom: noms[i % noms.length],
        groupeId: i % 5 == 4 ? null : 'g${i % 3}',
        groupeLibelle: i % 5 == 4
            ? null
            : 'Débutants, lundi 18 h · n° ${i % 3 + 1}',
        niveauId: i % 6 == 5 ? null : 'n$i',
        niveauNomHumain: i % 6 == 5 ? null : 'Niveau ${i % 4 + 1}',
        niveauCycle: i % 6 == 5 ? null : cycles[i % 4],
        niveauDepuis: DateTime.now().subtract(Duration(days: i * 9)),
        exceptionActiveId: i % 7 == 3 ? 'x$i' : null,
        exceptionActiveType: i % 7 == 3
            ? TypeExceptionProgression.blocage
            : null,
      ),
  ];
}

List<EvaluationAdmin> _evaluations() => <EvaluationAdmin>[
  for (int i = 0; i < 12; i++)
    EvaluationAdmin(
      id: 'ev$i',
      studentId: 's$i',
      identifiant: 'RA-26-${4800 + i}',
      prenom: <String>['Amina', 'Yacine', 'Salma', 'Idris'][i % 4],
      nom: 'Test-${i + 1}',
      niveauId: 'n1',
      niveauNomHumain: 'Niveau ${i % 4 + 1}',
      type: TypeEvaluation.values[i % TypeEvaluation.values.length],
      statut: StatutEvaluation.values[i % StatutEvaluation.values.length],
      datePrevue: DateTime(2026, 10, 12 + i),
      dateRealisee: null,
      resultat: null,
      notes: null,
    ),
];

List<AnomalieQualite> _anomalies() => <AnomalieQualite>[
  for (int i = 0; i < 12; i++)
    AnomalieQualite(
      type: TypeAnomalieQualite.values[i % TypeAnomalieQualite.values.length],
      refId: 'r$i',
      studentId: 's$i',
      studentPrenom: <String>['Amina', 'Yacine', 'Salma', 'Idris'][i % 4],
      studentNom: 'Test-${i + 1}',
      teacherId: 't1',
      teacherPrenom: 'Sayyid',
      teacherNom: 'Fictif',
      depuis: DateTime.now().subtract(Duration(days: i * 3)),
      controleStatut: i % 4 == 3
          ? StatutControleQualite.traite
          : StatutControleQualite.ouvert,
      controleNote: null,
    ),
];

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('LISTES-1 lot 4 : captures Classes et Progression', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('classes 1440 ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(tester, Routes.adminOperationsGroupes, mode: mode);
        await _enHaut(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'classes_1440_${mode.name}')}',
        );
      });

      for (final (String, String) page in <(String, String)>[
        ('journal', Routes.adminSecuriteAuditJournal),
        ('observations', Routes.adminSecuriteAuditObservations),
        ('catalogue', Routes.adminPedagogieBibliotheque),
        ('pilotage', Routes.adminOperationsPilotage),
        ('evaluations', Routes.adminPedagogieEvaluations),
        ('qualite', Routes.adminPedagogieQualite),
        ('programmes', Routes.adminPedagogieProgrammes),
      ]) {
        if (mode != ThemeMode.light) continue;
        testWidgets('${page.$1} 1440 ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _bureau, 1);
          await _monter(tester, page.$2, mode: mode);
          await _enHaut(tester);
          debugPrint(
            'PNG ${await capturer(tester, '${page.$1}_1440_${mode.name}')}',
          );
        });
      }

      testWidgets('evaluations donnees 1440 ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(
          tester,
          Routes.adminPedagogieEvaluations,
          mode: mode,
          evaluations: _evaluations(),
        );
        await _enHaut(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'evaluations_donnees_1440_${mode.name}')}',
        );
      });

      testWidgets('qualite donnees 1440 ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(
          tester,
          Routes.adminPedagogieQualite,
          mode: mode,
          anomalies: _anomalies(),
        );
        await _enHaut(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'qualite_donnees_1440_${mode.name}')}',
        );
      });

      testWidgets('classes menu ouvert 1440 ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(tester, Routes.adminOperationsGroupes, mode: mode);
        await tester.tap(find.byType(MenuActions).first);
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'classes_menu_ouvert_1440_${mode.name}')}',
        );
      });

      testWidgets('progression 1440 ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, _bureau, 1);
        await _monter(
          tester,
          Routes.adminPedagogieProgression,
          mode: mode,
          eleves: _eleves(),
        );
        await _enHaut(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'progression_1440_${mode.name}')}',
        );
      });
    }
  });
}
