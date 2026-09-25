// Captures de recette LT-9 : S09 (page des acces et choix des profils), S10
// « Consequences » et S11 « Resultat » sur le VRAI routeur, 390x844 et
// 1440x900, clair et sombre. A comparer a la planche « 01 Recharges, remises
// et acces ». S11 avec un faux port (l'arret est indisponible en
// demonstration).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/arret_acces_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import '../../support/pressable_de.dart';
import 'support_compte.dart' hide toucher;

/// Faux port des captures S11 : un arret rendu, deux issues.
class _FauxArret extends FinanceFoyerDemo {
  const _FauxArret();

  @override
  Future<ResultatAnnulation> annulerAcces({
    required String referenceApercu,
    required List<String> profilIds,
    required String cleIdempotence,
  }) async => const ResultatAnnulation(
    profils: <IssueProfil>[
      IssueProfil(profilId: DonneesDemo.aichaId, issue: IssueServeur.enAttente),
      IssueProfil(profilId: DonneesDemo.yusufId, issue: IssueServeur.echouee),
    ],
  );
}

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode,
  String chemin, {
  PortFinanceFoyer port = const FinanceFoyerDemo(),
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage()..elevesRendus = DonneesDemo.eleves,
        ),
        ...surchargesCompte(eleves: DonneesDemo.eleves),
        portFinanceFoyerProvider.overrideWithValue(port),
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
  routeur.go(chemin);
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.tap(pressableDe(cible));
  await stabiliser(tester);
}

void main() {
  group('Capture : Arreter l acces (LT-9)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille) format in <(String, Size)>[
        ('390x844', const Size(390, 844)),
        ('1440x900', const Size(1440, 900)),
      ]) {
        testWidgets(
          'acces, consequences, resultat, ${format.$1}, ${mode.name}',
          (WidgetTester tester) async {
            fixerVueCapture(tester, format.$2, 1);
            final String f = '${format.$1}_${mode.name}';
            await _monter(
              tester,
              mode,
              Routes.tuteurCompteAcces,
              port: const _FauxArret(),
            );
            debugPrint('PNG ${await capturer(tester, 'acces9a_$f')}');
            await _toucher(tester, find.byKey(AccesComptePage.arreterKey));
            await _toucher(tester, find.byType(Checkbox).first);
            debugPrint('PNG ${await capturer(tester, 'acces9b_$f')}');
            await _toucher(tester, find.byKey(ArretAccesPage.continuerKey));
            await _toucher(tester, find.byKey(ArretAccesPage.comprisKey));
            debugPrint('PNG ${await capturer(tester, 'acces10_$f')}');
            await _toucher(tester, find.byKey(ArretAccesPage.confirmerKey));
            debugPrint('PNG ${await capturer(tester, 'acces11_$f')}');
          },
        );
      }
    }
  });
}
