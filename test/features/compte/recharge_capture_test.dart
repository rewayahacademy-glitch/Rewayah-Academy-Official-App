// Captures de recette LT-7 : S03 « Pour qui ? » et S04 « Quelle recharge ? »
// sur le VRAI routeur, avec la demonstration, 390x844 et 1440x900, clair et
// sombre. A comparer a la planche « 01 Recharges, remises et acces ».
// LT-8 : S05 « Verifier » et S06 « Resultat » avec un faux port (devis et
// paiement indisponibles en demonstration).
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
import 'package:rewayah_academy/features/compte/recharge_page.dart';
import 'package:rewayah_academy/features/compte/verifier_recharge_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import '../../support/pressable_de.dart';
import 'support_compte.dart' hide toucher;

/// Faux port des captures S05-S06 : un devis et un resultat rendus.
class _FauxPaiement extends FinanceFoyerDemo {
  const _FauxPaiement();

  static final DevisRecharge devis = DevisRecharge(
    reference: 'capture-devis',
    lignes: const <LigneDevis>[
      LigneDevis(
        profilId: DonneesDemo.aichaId,
        prixMineur: 1500,
        remiseMineure: 100,
        quantiteMineure: 1000,
      ),
      LigneDevis(
        profilId: DonneesDemo.yusufId,
        prixMineur: 1200,
        remiseMineure: 0,
        quantiteMineure: 800,
      ),
    ],
    totalMineur: 2600,
    devise: FinanceFoyerDemo.devise,
    valableJusqua: DateTime.utc(2099, 1, 15, 12),
  );

  @override
  Future<ResultatRecharge> payer({
    required String referenceDevis,
    required String cleIdempotence,
  }) async => const ResultatRecharge(
    referencePaiement: 'PAI-CAPTURE-1',
    paiement: IssueServeur.confirmee,
    attributions: <IssueProfil>[
      IssueProfil(profilId: DonneesDemo.aichaId, issue: IssueServeur.confirmee),
      IssueProfil(profilId: DonneesDemo.yusufId, issue: IssueServeur.enAttente),
    ],
  );
}

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode,
  String chemin, {
  PortFinanceFoyer port = const FinanceFoyerDemo(),
  Object? extra,
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
  routeur.go(chemin, extra: extra);
  await stabiliser(tester);
}

void main() {
  group('Capture : Recharger (LT-7)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    final String chemin = Uri(
      path: Routes.tuteurCompteRecharge,
      queryParameters: <String, String>{'profil': DonneesDemo.aichaId},
    ).toString();
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille) format in <(String, Size)>[
        ('390x844', const Size(390, 844)),
        ('1440x900', const Size(1440, 900)),
      ]) {
        testWidgets('recharge demo, ${format.$1}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, format.$2, 1);
          await _monter(tester, mode, chemin);
          debugPrint(
            'PNG ${await capturer(tester, 'recharge1_${format.$1}_${mode.name}')}',
          );
          await tester.tap(pressableDe(find.byKey(RechargePage.continuerKey)));
          await stabiliser(tester);
          await tester.tap(
            find.byKey(
              RechargePage.offreKey('demo-offre-${DonneesDemo.aichaId}'),
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'recharge2_${format.$1}_${mode.name}')}',
          );
        });
      }
    }
  });

  group('Capture : Verifier et resultat (LT-8)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille) format in <(String, Size)>[
        ('390x844', const Size(390, 844)),
        ('1440x900', const Size(1440, 900)),
      ]) {
        testWidgets('verifier et resultat, ${format.$1}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, format.$2, 1);
          await _monter(
            tester,
            mode,
            Routes.tuteurCompteRechargeVerifier,
            port: const _FauxPaiement(),
            extra: _FauxPaiement.devis,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'recharge5_${format.$1}_${mode.name}')}',
          );
          await tester.tap(
            pressableDe(find.byKey(VerifierRechargePage.payerKey)),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'recharge6_${format.$1}_${mode.name}')}',
          );
        });
      }
    }
  });
}
