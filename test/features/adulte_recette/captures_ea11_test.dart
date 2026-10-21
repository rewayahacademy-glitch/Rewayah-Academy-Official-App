// EA-11 : les captures de la reprise du foyer (succession, doc sections 12,
// 13 et 19, F18), depuis la VRAIE route /demo/adulte (`adresseDemoAdulte`),
// comme `captures_ea10_test.dart` : 390x844, 768x1024 et 1440x900, clair et
// sombre, plus le texte a 200 % en 390. L'explication (second adulte), les
// cinq etats rendus, la decision du titulaire, son etat refuse, et D5.
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea10_test.dart`).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  Future<void> Function(WidgetTester tester)? avant,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (avant != null) await avant(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Adresse de la demande de reprise, second adulte, dans [etat].
String _adresseReprise({EtatDemoAdulte etat = EtatDemoAdulte.conjointActif}) =>
    adresseDemoAdulte(
      EcranDemoAdulte.repriseFoyer,
      etat: etat,
      vue: VueDemoAdulte.secondAdulte,
    );

/// Adresse de la decision du titulaire, dans [etat].
String _adresseTitulaire({
  EtatDemoAdulte etat = EtatDemoAdulte.repriseDemandee,
}) => adresseDemoAdulte(EcranDemoAdulte.repriseTitulaire, etat: etat);

/// Tape « Deposer la demande » puis confirme, jusqu'a l'etat rendu.
Future<void> _deposer(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(RepriseFoyerPage.deposerKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(RepriseFoyerPage.deposerKey));
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(ActionPrincipale, t.adulte.reprise.deposer).last,
  );
  await tester.pumpAndSettle();
}

/// Tape « Refuser la demande », sans confirmation (UX_REVIEW_07 ligne 18).
Future<void> _refuser(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(RepriseTitulairePage.refuserKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(RepriseTitulairePage.refuserKey));
  await tester.pumpAndSettle();
}

void main() {
  group('Capture : EA-11', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Second adulte, l'explication (doc section 19, 12.6 et 12.7) : 390/768/
    // 1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea11_explication_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseReprise(),
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur l'explication, en 390.
    testWidgets('ea11_explication_390_light_200pc', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea11_explication_390_light_200pc',
        _adresseReprise(),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Les cinq etats rendus (doc section 18, cas 16 a 20) : 390, clair et
    // sombre, apres le depot pour « deposee ».
    for (final (String nom, EtatDemoAdulte? etat)
        in <(String, EtatDemoAdulte?)>[
          ('deposee', null),
          ('refusee_par_titulaire', EtatDemoAdulte.repriseRefuseeParTitulaire),
          ('attente_administration', EtatDemoAdulte.repriseSansReponse),
          ('validee', EtatDemoAdulte.repriseValidee),
          ('refusee', EtatDemoAdulte.repriseRefusee),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea11_etat_${nom}_390_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseReprise(etat: etat ?? EtatDemoAdulte.conjointActif),
            const Size(390, 844),
            mode: mode,
            avant: etat == null ? _deposer : null,
          );
        });
      }
    }

    // D5 : le depot n'est pas confirme, le bouton reste actif : 390 clair.
    testWidgets('ea11_d5_depot_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea11_d5_depot_390_light',
        _adresseReprise(etat: EtatDemoAdulte.erreurReseau),
        const Size(390, 844),
        avant: _deposer,
      );
    });

    // Titulaire, la decision (doc section 12.2) : 390/768/1440, clair et
    // sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea11_titulaire_decision_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adresseTitulaire(),
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur la decision du titulaire, en 390.
    testWidgets('ea11_titulaire_decision_390_light_200pc', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea11_titulaire_decision_390_light_200pc',
        _adresseTitulaire(),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // Apres « Refuser la demande », sans confirmation : l'etat rendu, 390
    // clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String fichier = 'ea11_titulaire_refusee_390_${mode.name}';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          _adresseTitulaire(),
          const Size(390, 844),
          mode: mode,
          avant: _refuser,
        );
      });
    }

    // D5 au refus : aucun combo du demo n'offre decision + coupure par la
    // route (le refus reseau n'est module que hors de la matrice de
    // `DonneesAdulteDemo.repriseTitulaire`), donc l'ecran est monte
    // directement, comme `captures_cl47_test.dart`, avec le port coupe.
    testWidgets('ea11_d5_refus_390_light', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          RepriseTitulairePage(onRetour: () {}, onRefusee: () {}),
          surcharges: <Override>[
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
            demandeRepriseRecueProvider.overrideWith(
              (Ref _) async => const RepriseARefuser(),
            ),
            portRepriseFoyerProvider.overrideWithValue(
              const _PortCoupeCapture(),
            ),
          ],
        ),
      );
      await stabiliser(tester);
      await tester.ensureVisible(find.byKey(RepriseTitulairePage.refuserKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RepriseTitulairePage.refuserKey));
      await tester.pumpAndSettle();
      debugPrint('PNG ${await capturer(tester, 'ea11_d5_refus_390_light')}');
    });
  });
}

/// Un port dont la reponse du refus se perd (D5), pour la capture directe.
class _PortCoupeCapture implements PortRepriseFoyer {
  const _PortCoupeCapture();

  @override
  Future<ResultatReprise> deposer({required String cle}) async =>
      const RepriseEchecReseau();

  @override
  Future<ResultatReprise> refuser({required String cle}) async =>
      const RepriseEchecReseau();
}
