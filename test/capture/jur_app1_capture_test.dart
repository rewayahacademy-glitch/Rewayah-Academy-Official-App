// Captures de JUR-APP-1 : textes juridiques valides le 02/10/2026 portes dans
// l'application. Le bandeau de la salle (guidee) avec son lien « En savoir
// plus », la lecture E-1 ouverte, la carte d'accuse (A3 tuteur, E1
// enseignant) et le contrat (tuteur, enseignant avec clause et case art. 9 en
// demonstration comme hors demonstration depuis la publication de la
// politique de controle le 05/10/2026, ASSETS-DIR-1), et la politique de
// controle ouverte depuis le lien de la clause.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Les pages de texte
// sont capturees dans une vue haute (390 x 2400) pour montrer le texte entier.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

Future<void> _monterDossier(
  WidgetTester tester, {
  required String depart,
  required AppRole role,
  Size taille = const Size(390, 2400),
  bool demonstration = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..demonstration = demonstration
    ..etatRendu = EtatDossier(
      profilExiste: true,
      role: role,
      statutCompte: AccountStatus.pendingKyc,
      accuseSigne: depart == Routes.attenteContrat,
    );
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.attenteAccuse,
        builder: (BuildContext _, GoRouterState _) => const AccusePage(),
      ),
      GoRoute(
        path: Routes.attenteContrat,
        builder: (BuildContext _, GoRouterState _) => const ContratPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[serviceDossierProvider.overrideWithValue(dossier)],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Future<void> _monterSalle(
  WidgetTester tester,
  Size taille, {
  double densite = 2,
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(
    hoteCapture(
      SalleDemo(
        role: RoleSeance.guidee,
        etat: EtatDemoSalle.repos,
        onSortir: () {},
      ),
      themeMode: mode,
      echelleTexte: echelle,
      interfaceMode: InterfaceMode.enfant,
    ),
  );
  await stabiliser(tester);
}

/// Le haut de la surface du cours (la carte « Chapitre 1 »), pour mesurer ce
/// que la mention et son lien prennent en hauteur.
double _hautCours(WidgetTester tester) =>
    tester.getTopLeft(find.text('Chapitre 1').first).dy;

void main() {
  group('Capture JUR-APP-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    // Le nom dit la largeur, puis « t200 » pour le texte a 200 %.
    for (final (String nom, Size taille, double densite, double echelle)
        in <(String, Size, double, double)>[
          ('320x690', const Size(320, 690), 2, 1),
          ('320x690_t200', const Size(320, 690), 2, 2),
          ('390x844', const Size(390, 844), 2, 1),
          ('1440x900', const Size(1440, 900), 1, 1),
        ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String m = mode == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('salle guidee, bandeau et lien, $nom $m', (
          WidgetTester tester,
        ) async {
          await _monterSalle(
            tester,
            taille,
            densite: densite,
            mode: mode,
            echelle: echelle,
          );
          expect(find.text(t.salle.informationControle.lien), findsOneWidget);
          debugPrint('MESURE $nom $m haut du cours ${_hautCours(tester)}');
          debugPrint(
            'PNG ${await capturer(tester, 'jur_app1_salle_guidee_${nom}_$m')}',
          );
        });

        testWidgets('lecture E-1, haut et bas, $nom $m', (
          WidgetTester tester,
        ) async {
          await _monterSalle(
            tester,
            taille,
            densite: densite,
            mode: mode,
            echelle: echelle,
          );
          await tester.tap(find.text(t.salle.informationControle.lien));
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(
            find.text(t.salle.informationControle.e1.titre),
            findsOneWidget,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'jur_app1_e1_${nom}_${m}_haut')}',
          );
          await tester.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, -5000),
          );
          await stabiliser(tester);
          expect(
            tester.getRect(find.text(t.salle.informationControle.e1.p5)).bottom,
            lessThanOrEqualTo(taille.height),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'jur_app1_e1_${nom}_${m}_bas')}',
          );
        });
      }
    }

    testWidgets('accuse tuteur (A3)', (WidgetTester tester) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteAccuse,
        role: AppRole.guardian,
      );
      debugPrint('PNG ${await capturer(tester, 'jur_app1_accuse_tuteur_a3')}');
    });

    testWidgets('accuse enseignant (E1)', (WidgetTester tester) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteAccuse,
        role: AppRole.teacher,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'jur_app1_accuse_enseignant_e1')}',
      );
    });

    testWidgets('contrat tuteur (A3 et observation)', (
      WidgetTester tester,
    ) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteContrat,
        role: AppRole.guardian,
      );
      debugPrint('PNG ${await capturer(tester, 'jur_app1_contrat_tuteur')}');
    });

    testWidgets('contrat enseignant en demonstration (2026-10-jur : E1, '
        'clause, case art. 9)', (WidgetTester tester) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteContrat,
        role: AppRole.teacher,
        demonstration: true,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'jur_app1_contrat_enseignant')}',
      );
    });

    testWidgets('contrat enseignant hors demonstration (politique publiee : '
        '2026-10-jur, clause, lien vers la politique, case art. 9)', (
      WidgetTester tester,
    ) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteContrat,
        role: AppRole.teacher,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'jur_app1_contrat_enseignant_hors_demo')}',
      );
    });

    testWidgets(
      'politique de controle ouverte depuis la clause (ASSETS-DIR-1)',
      (WidgetTester tester) async {
        await _monterDossier(
          tester,
          depart: Routes.attenteContrat,
          role: AppRole.teacher,
          taille: const Size(390, 4200),
        );
        await tester.tap(find.text(t.contrat.politique.lien));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'jur_app1_politique_controle')}',
        );
      },
    );
  });
}
