// T-S6 du lot CL-7 : la page /demo/salle range les situations de secours par
// role. Chaque lien est tape et ouvre la bonne salle ; la liste reflue a 320
// et a 200 % ; le clavier ouvre un lien. Captures : `cl7_demo_liste_*`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

late GoRouter _routeur;

Future<void> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  _routeur = GoRouter(
    initialLocation: Routes.demoSalle,
    routes: routesDemoSalle('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
            themeMode: mode,
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext contexte, Widget? app) => MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelleTexte)),
              child: app!,
            ),
            routerConfig: _routeur,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _lien(RoleSeance role, EtatDemoSalle etat) =>
    find.byKey(ValueKey<String>('lien-${role.name}-${etat.name}'));

void main() {
  group('Liste par role', () {
    test('secours : 9 situations, 8 pour l\'enseignant (sans camera)', () {
      expect(etatsDemoSecours(RoleSeance.eleve), hasLength(9));
      expect(etatsDemoSecours(RoleSeance.guidee), hasLength(9));
      expect(etatsDemoSecours(RoleSeance.enseignant), hasLength(8));
      expect(
        etatsDemoSecours(RoleSeance.enseignant),
        isNot(contains(EtatDemoSalle.cameraInterdite)),
      );
      for (final RoleSeance role in RoleSeance.values) {
        for (final EtatDemoSalle etat in etatsDemoSecours(role)) {
          expect(etatsDemoSeance, isNot(contains(etat)));
        }
      }
    });

    testWidgets('deux groupes par role, liens attendus', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Déroulé de la séance'), findsNWidgets(3));
      expect(find.text('Situations de secours'), findsNWidgets(3));
      for (final RoleSeance role in RoleSeance.values) {
        for (final EtatDemoSalle etat in <EtatDemoSalle>[
          ...etatsDemoSeance,
          ...etatsDemoSecours(role),
        ]) {
          expect(_lien(role, etat), findsOneWidget);
        }
      }
      expect(
        _lien(RoleSeance.enseignant, EtatDemoSalle.cameraInterdite),
        findsNothing,
      );
    });
  });

  group('Chaque lien de secours ouvre la bonne salle', () {
    for (final RoleSeance role in RoleSeance.values) {
      for (final EtatDemoSalle etat in etatsDemoSecours(role)) {
        testWidgets('${role.name} ${etat.name}', (WidgetTester tester) async {
          await _monter(tester);
          await tester.ensureVisible(_lien(role, etat));
          await tester.pump();
          await tester.tap(_lien(role, etat));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          final Uri adresse = _routeur.routeInformationProvider.value.uri;
          expect(adresse.queryParameters['role'], role.name);
          expect(adresse.queryParameters['etat'], etat.name);
          expect(
            find.byKey(ValueKey<String>('${role.name}-${etat.name}')),
            findsOneWidget,
          );
        });
      }
    }
  });

  group('Recette', () {
    for (final (Size taille, double zoom) in <(Size, double)>[
      (const Size(320, 640), 1),
      (const Size(390, 844), 2),
      (const Size(768, 1024), 2),
      (const Size(1440, 900), 2),
    ]) {
      testWidgets('liste ${taille.width.toInt()} zoom $zoom sans debordement', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: taille, echelleTexte: zoom);
        expect(tester.takeException(), isNull);
        // Reflow : aucun lien ne depasse la largeur de la vue.
        for (final RoleSeance role in RoleSeance.values) {
          final Finder lien = _lien(role, EtatDemoSalle.accesRetire);
          expect(tester.getRect(lien).right, lessThanOrEqualTo(taille.width));
        }
      });
    }

    testWidgets('clavier : Tab atteint un lien, Entree l\'ouvre', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      // Tab jusqu'au premier lien de secours de l'eleve (focus visible :
      // la liste defile pour le montrer).
      final Finder cible = _lien(RoleSeance.eleve, EtatDemoSalle.reseauFaible);
      bool atteint = false;
      for (int i = 0; i < 20 && !atteint; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final FocusNode? focus = FocusManager.instance.primaryFocus;
        atteint =
            focus?.context != null &&
            find
                .descendant(
                  of: cible,
                  matching: find.byWidget(focus!.context!.widget),
                )
                .evaluate()
                .isNotEmpty;
      }
      expect(atteint, isTrue);
      final Rect rect = tester.getRect(cible);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        _routeur.routeInformationProvider.value.uri.queryParameters['etat'],
        EtatDemoSalle.reseauFaible.name,
      );
    });

    testWidgets('Reessayer (echec) : la connexion revient', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      _routeur.go(adresseDemoSalle(RoleSeance.eleve, EtatDemoSalle.echec));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Connexion rétablie.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('bloc-echec-connexion')),
        findsNothing,
      );
      // Le retour bref disparait seul.
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Capture : T-S6', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390x844', const Size(390, 844)),
      ('768x1024', const Size(768, 1024)),
      ('1440x900', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'cl7_demo_liste_${nom}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          await _monter(tester, taille: taille, mode: mode);
          debugPrint('PNG ${await capturer(tester, fichier)}');
        });
      }
    }
  });
}
