// MA-2 : navigation eleve a quatre destinations (Accueil, Ma classe, Coran,
// Mon espace) en presentation standard ; MA-NAV-1 (02/10/2026) : trois en Mode
// Accessibilite (le Coran, deja porte par l'Accueil, quitte la barre), sur les
// MEMES routes. Dans ses trois formes (barre 390, rail 768, barre laterale 1440). On ouvre
// la VRAIE coquille sur le vrai routeur et on TAPE chaque destination ; puis
// la demonstration /demo/accessibilite, posee dans la meme `NavShell`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

const List<(Size, Key)> _formes = <(Size, Key)>[
  (Size(390, 844), NavShell.barreBasseKey),
  (Size(768, 1024), NavShell.railKey),
  (Size(1440, 900), NavShell.barreLateraleKey),
];

Finder _dans(Key forme, String libelle) =>
    find.descendant(of: find.byKey(forme), matching: find.text(libelle));

/// Un corpus vide : le Coran s'ouvre sans Supabase.
class _CoranVide implements ServiceCoran {
  @override
  Future<String?> editionCourante() async => 'edition-test';
  @override
  Future<List<Sourate>?> sourates() async => const <Sourate>[];
  @override
  Future<PageCoran?> page(int numero) async =>
      PageCoran(numero: numero, versets: const <VersetCoran>[]);
  @override
  Future<int?> pageDe(int sourate, int verset) async => null;
  @override
  Future<PositionLecture?> position(String profilId) async => null;
  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => true;
  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async => null;
  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => const <VersetCoran>[];
}

/// Monte la VRAIE racine `RewayahApp` (theme lu par le fournisseur du Mode
/// Accessibilite) sur le vrai routeur, sur l'Accueil de l'eleve.
Future<GoRouter> _monterRacine(
  WidgetTester tester,
  InterfaceMode mode,
  Size taille,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      ...surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.student, mode: mode)),
      ),
      portClassesFoyerProvider.overrideWithValue(
        const ClassesFoyerIndisponible(),
      ),
      serviceCoranProvider.overrideWithValue(_CoranVide()),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: TranslationProvider(child: const RewayahApp()),
    ),
  );
  await stabiliser(tester);
  final GoRouter routeur = c.read(routeurProvider)..go(Routes.eleve);
  await stabiliser(tester);
  // Le theme de la racine suit la presentation (AppTheme.pour existant).
  expect(c.read(modeAccessibiliteActifProvider), mode == InterfaceMode.enfant);
  return routeur;
}

void main() {
  test('quatre destinations en standard, trois (essentielles) en guide', () {
    final List<Destination> d = destinationsPour(
      role: AppRole.student,
      mode: InterfaceMode.standard,
    );
    expect(d.map((Destination x) => x.libelle).toList(), <String>[
      t.nav.eleve.accueil,
      t.nav.eleve.maClasse,
      t.nav.eleve.coran,
      t.nav.eleve.monEspace,
    ]);
    expect(d.map((Destination x) => x.chemin).toList(), <String>[
      Routes.eleve,
      Routes.eleveSuivi,
      Routes.eleveCoran,
      Routes.compte,
    ]);
    final List<Destination> g = destinationsPour(
      role: AppRole.student,
      mode: InterfaceMode.enfant,
    );
    expect(g.map((Destination x) => x.libelle).toList(), <String>[
      t.nav.eleve.accueil,
      t.nav.eleve.maClasse,
      t.nav.eleve.monEspace,
    ]);
    // Memes routes que le standard : un sous-ensemble, dans le meme ordre.
    expect(g.map((Destination x) => x.chemin).toList(), <String>[
      Routes.eleve,
      Routes.eleveSuivi,
      Routes.compte,
    ]);
  });

  for (final InterfaceMode mode in InterfaceMode.values) {
    for (final (Size taille, Key forme) in _formes) {
      testWidgets('vraie coquille, ${mode.name}, ${taille.width.toInt()} : '
          'les destinations de la barre se tapent', (WidgetTester tester) async {
        final GoRouter routeur = await _monterRacine(tester, mode, taille);
        expect(find.byKey(forme), findsOneWidget);
        final bool guide = mode == InterfaceMode.enfant;
        // Libelles toujours visibles, a toutes les largeurs.
        for (final String l in <String>[
          t.nav.eleve.accueil,
          t.nav.eleve.maClasse,
          if (!guide) t.nav.eleve.coran,
          t.nav.eleve.monEspace,
        ]) {
          expect(_dans(forme, l), findsOneWidget, reason: l);
        }
        if (guide) {
          // Le Coran n'est plus dans la barre du Mode Accessibilite.
          expect(_dans(forme, t.nav.eleve.coran), findsNothing);
        }
        for (final (String libelle, String chemin, int index)
            in <(String, String, int)>[
              (t.nav.eleve.maClasse, Routes.eleveSuivi, 1),
              if (!guide) (t.nav.eleve.coran, Routes.eleveCoran, 2),
              (t.nav.eleve.monEspace, Routes.compte, guide ? 2 : 3),
              (t.nav.eleve.accueil, Routes.eleve, 0),
            ]) {
          await tester.tap(_dans(forme, libelle));
          await stabiliser(tester);
          expect(lieu(routeur), chemin, reason: libelle);
          expect(
            tester.widget<NavShell>(find.byType(NavShell)).indexActif,
            index,
            reason: libelle,
          );
        }
        if (guide) {
          // Le Coran reste atteignable par le bloc permanent de l'Accueil,
          // sur la meme route.
          routeur.go(Routes.eleveCoran);
          await stabiliser(tester);
          expect(lieu(routeur), Routes.eleveCoran);
          expect(
            tester.widget<NavShell>(find.byType(NavShell)).indexActif,
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('demonstration', () {
    Future<void> monter(
      WidgetTester tester,
      Size taille, {
      MomentDemoAccessibilite moment = MomentDemoAccessibilite.avant,
    }) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: EcranAccessibiliteDemo(
                eleve: EleveDemoAccessibilite.mariam,
                moment: moment,
              ),
            ),
          ),
        ),
      );
      await stabiliser(tester);
    }

    for (final (Size taille, Key forme) in _formes) {
      testWidgets('les destinations de la barre se tapent, ${taille.width.toInt()}', (
        WidgetTester tester,
      ) async {
        await monter(tester, taille);
        expect(find.byKey(forme), findsOneWidget);
        // On arrive sur Ma classe : le vrai Espace Classe.
        expect(find.byType(EspaceGroupePage), findsOneWidget);
        // MA-NAV-1 : la barre de la demonstration est celle du Mode
        // Accessibilite, sans le Coran ; l'index actif est celui de la barre.
        for (final (String libelle, int index) in <(String, int)>[
          (t.nav.eleve.accueil, 0),
          (t.nav.eleve.monEspace, 2),
          (t.nav.eleve.maClasse, 1),
        ]) {
          await tester.tap(_dans(forme, libelle));
          await stabiliser(tester);
          expect(
            tester.widget<NavShell>(find.byType(NavShell)).indexActif,
            index,
            reason: libelle,
          );
        }
        expect(find.byType(EspaceGroupePage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('pendant la seance, aucune navigation d app', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        const Size(390, 844),
        moment: MomentDemoAccessibilite.pendant,
      );
      expect(find.byType(NavShell), findsNothing);
    });
  });
}
