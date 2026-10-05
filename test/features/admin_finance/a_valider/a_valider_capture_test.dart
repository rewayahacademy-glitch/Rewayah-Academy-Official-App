// Captures de recette de CPT-VAL-1 (decision Q-8 = (a) du 05/10) :
// - l'onglet « A valider » dans la vraie coquille admin
//   (`/demo/finance?ecran=aValider`) ;
// - la decision d'une demande (feuille, montant exact) ;
// - le refus avec motif (puces, un motif retenu) ;
// - cote Comptable : le detail d'un paiement dont la demande a ete refusee
//   par la direction (« Refusee », par qui, motif).
// 390, 1440 et 320 a texte double, clair et sombre.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais, rien n'est ecrit) :
//
//   CAPTURE_DIR=docs/current/captures/CPT-VAL-1 \
//     flutter test test/features/admin_finance/a_valider/a_valider_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_validations_finance.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_finance/a_valider/a_valider_page.dart';
import 'package:rewayah_academy/features/admin_finance/a_valider/decision_validation.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/validations_demo.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import '../../../capture/outil_capture.dart';
import '../../comptable/paiements/support_paiements.dart';
import '../reserve_delegation/support_direction.dart';

MaterialApp _app({
  required ThemeMode mode,
  required double echelle,
  GoRouter? routeur,
  Widget? accueil,
}) {
  Widget cadre(BuildContext context, Widget? app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(echelle)),
    child: app!,
  );
  final ThemeData clair = AppTheme.pour(InterfaceMode.standard, Brightness.light);
  final ThemeData sombre = AppTheme.pour(InterfaceMode.standard, Brightness.dark);
  if (routeur != null) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: clair,
      darkTheme: sombre,
      themeMode: mode,
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: cadre,
      routerConfig: routeur,
    );
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: clair,
    darkTheme: sombre,
    themeMode: mode,
    locale: AppLocale.fr.flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: cadre,
    home: accueil,
  );
}

Future<void> _monterOnglet(
  WidgetTester tester, {
  required ThemeMode mode,
  double echelle = 1,
}) async {
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoFinance(OngletFinance.aValider),
    routes: routesDemoFinance('staging'),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: sessionDirection(),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: _app(mode: mode, echelle: echelle, routeur: routeur),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _monterComptable(
  WidgetTester tester, {
  required ThemeMode mode,
  double echelle = 1,
}) async {
  final EtatDemoPaiements etat = EtatDemoPaiements();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...sessionDirection(),
        ...surchargesDemo(etat),
        portValidationsFinanceProvider.overrideWithValue(
          ValidationsFinanceDemo(
            lecteurId: SocleComptableDemo.comptableId,
            lecteurNom: SocleComptableDemo.leComptable.nom,
          ),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: _app(
            mode: mode,
            echelle: echelle,
            accueil: const DetailPaiementPage(
              obligationId: PaiementsDemo.obligationMethodeRecente,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible.first);
  await tester.pumpAndSettle();
  await tester.tap(cible.first);
  await tester.pumpAndSettle();
}

/// Le Comptable a demande la validation de la paie dont les coordonnees ont
/// change, la direction l'a refusee avec un motif.
Future<void> _refuserCoordonnees() async {
  final DemandeValidation d = RegistreValidationsDemo.instance.deposer(
    nature: NatureDemandeValidation.payoutSensible,
    demandeurId: SocleComptableDemo.comptableId,
    demandeurNom: SocleComptableDemo.leComptable.nom,
    objet: 'Octobre 2026 · ${SocleComptableDemo.enseignants[11].nom}',
    montant: SocleComptableDemo.usd(100),
    raison: RaisonBlocage.validationRequise,
    cleIdempotence: 'capture-depot',
    objetId: PaiementsDemo.obligationMethodeRecente,
    precision: 'Coordonnées du bénéficiaire modifiées le 2 octobre 2026.',
  );
  await const ValidationsFinanceDemo().decider(
    demandeId: d.id,
    decision: DecisionValidation.refuser,
    cleIdempotence: 'capture-decision',
    motif: t.comptable.validation.motifs.coordonnees,
  );
}

void main() {
  group('Capture : A valider (CPT-VAL-1)', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });
    setUp(RegistreValidationsDemo.instance.reinitialiser);

    // (nom, taille de vue, echelle du texte, hauteur pleine pour l'onglet)
    const List<(String, Size, double, double)> vues =
        <(String, Size, double, double)>[
          ('390', Size(390, 844), 1, 2600),
          ('1440', Size(1440, 900), 1, 1900),
          ('320_x2', Size(320, 700), 2, 7600),
        ];

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String m = mode.name;
      for (final (String nom, Size vue, double echelle, double pleine)
          in vues) {
        testWidgets('onglet $nom $m', (WidgetTester tester) async {
          fixerVueCapture(tester, Size(vue.width, pleine), 1);
          await _monterOnglet(tester, mode: mode, echelle: echelle);
          expect(find.byType(AValiderBloc), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, 'onglet_${nom}_$m')}');
        });

        testWidgets('detail $nom $m', (WidgetTester tester) async {
          fixerVueCapture(tester, vue, 1);
          await _monterOnglet(tester, mode: mode, echelle: echelle);
          await _toucher(
            tester,
            find.byKey(
              AValiderBloc.cleDemande(ValidationsDemo.demandeRetraitReserve),
            ),
          );
          expect(find.byType(FeuilleDecisionValidation), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, 'detail_${nom}_$m')}');
        });

        testWidgets('refus avec motif $nom $m', (WidgetTester tester) async {
          fixerVueCapture(tester, vue, 1);
          await _monterOnglet(tester, mode: mode, echelle: echelle);
          await _toucher(
            tester,
            find.byKey(
              AValiderBloc.cleDemande(ValidationsDemo.demandeLieeOperateur),
            ),
          );
          await _toucher(
            tester,
            find.byKey(FeuilleDecisionValidation.cleRefuser),
          );
          await _toucher(
            tester,
            find.byKey(
              FeuilleDecisionValidation.cleMotif(
                MotifRefusValidation.coordonnees,
              ),
            ),
          );
          await tester.ensureVisible(
            find.byKey(FeuilleDecisionValidation.cleConfirmerRefus),
          );
          await tester.pumpAndSettle();
          debugPrint('PNG ${await capturer(tester, 'refus_motif_${nom}_$m')}');
        });

        testWidgets('comptable refusee $nom $m', (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            Size(vue.width, nom == '320_x2' ? 5200 : vue.height + 900),
            1,
          );
          await _refuserCoordonnees();
          await _monterComptable(tester, mode: mode, echelle: echelle);
          expect(
            find.text(t.comptable.statuts.validation.refusee),
            findsWidgets,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'comptable_refusee_${nom}_$m')}',
          );
        });
      }
    }
  });
}
