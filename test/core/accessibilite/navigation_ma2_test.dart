// MA-2 : navigation eleve a quatre destinations (Accueil, Ma classe, Apprendre (ex-Coran, lot 5),
// Mon espace) dans les DEUX presentations, standard et Mode Accessibilite,
// dans ses trois formes (barre 390, rail 768, barre laterale 1440). On ouvre
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
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/accessibilite_demo.dart';
import '../../support/demo/demo_accessibilite_page.dart';
import '../../support/harnais.dart';
import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;

const List<(Size, Key)> _formes = <(Size, Key)>[
  (Size(390, 844), NavShell.barreBasseKey),
  (Size(768, 1024), NavShell.railKey),
  (Size(1440, 900), NavShell.barreLateraleKey),
];

Finder _dans(Key forme, String libelle) =>
    find.descendant(of: find.byKey(forme), matching: find.text(libelle));

/// NAV-REFONTE (09/11/2026) : dans la barre flottante standard, seul l'onglet
/// ouvert ecrit son nom ; les autres se trouvent par leur nom lu.
Finder _nomme(Key forme, String libelle) => find.descendant(
  of: find.byKey(forme),
  matching: find.bySemanticsLabel(libelle),
);

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

/// NAV-REFONTE etape 3 (11/11/2026) : sur tablette et ordinateur, Mon espace
/// quitte la liste du panneau et vit a son pied (photo, menu).
bool _auPied(Key forme, String libelle) =>
    libelle == t.nav.eleve.monEspace && forme != NavShell.barreBasseKey;

/// Ouvre Mon espace par le menu du pied du panneau.
Future<void> _ouvrirParLePied(WidgetTester tester, String libelle) async {
  await tester.tap(find.byKey(NavShell.piedCompteKey));
  await stabiliser(tester);
  await tester.tap(find.text(libelle).last);
}

void main() {
  // Les vraies polices : la police de test (carres d'un em) ferait passer la
  // barre guidee en icones seules pour un defaut que l'application n'a pas.
  setUpAll(chargerPolicesDuDepot);

  test('memes quatre destinations, dans l ordre du doc 06', () {
    for (final InterfaceMode mode in InterfaceMode.values) {
      final List<Destination> d = destinationsPour(
        role: AppRole.student,
        mode: mode,
      );
      expect(d.map((Destination x) => x.libelle).toList(), <String>[
        t.nav.eleve.accueil,
        t.nav.eleve.maClasse,
        t.nav.eleve.apprendre,
        t.nav.eleve.monEspace,
      ]);
      expect(d.map((Destination x) => x.chemin).toList(), <String>[
        Routes.eleve,
        Routes.eleveSuivi,
        Routes.eleveApprendre,
        Routes.compte,
      ]);
    }
  });

  for (final InterfaceMode mode in InterfaceMode.values) {
    for (final (Size taille, Key forme) in _formes) {
      testWidgets('vraie coquille, ${mode.name}, ${taille.width.toInt()} : '
          'les 4 destinations se tapent', (WidgetTester tester) async {
        final GoRouter routeur = await _monterRacine(tester, mode, taille);
        expect(find.byKey(forme), findsOneWidget);
        // Libelles visibles a toutes les largeurs, sauf dans la barre
        // flottante standard (NAV-REFONTE, 09/11/2026) : la, chaque nom
        // reste lu par le lecteur d'ecran.
        final bool barreStandard =
            mode == InterfaceMode.standard && forme == NavShell.barreBasseKey;
        for (final String l in <String>[
          t.nav.eleve.accueil,
          t.nav.eleve.maClasse,
          t.nav.eleve.apprendre,
          t.nav.eleve.monEspace,
        ]) {
          expect(
            _auPied(forme, l)
                ? find.byKey(NavShell.piedCompteKey)
                : barreStandard
                ? _nomme(forme, l)
                : _dans(forme, l),
            findsOneWidget,
            reason: l,
          );
        }
        for (final (String libelle, String chemin, int index)
            in <(String, String, int)>[
              (t.nav.eleve.maClasse, Routes.eleveSuivi, 1),
              (t.nav.eleve.apprendre, Routes.eleveApprendre, 2),
              (t.nav.eleve.monEspace, Routes.compte, 3),
              (t.nav.eleve.accueil, Routes.eleve, 0),
            ]) {
          if (_auPied(forme, libelle)) {
            await _ouvrirParLePied(tester, libelle);
          } else {
            await tester.tap(
              barreStandard ? _nomme(forme, libelle) : _dans(forme, libelle),
            );
          }
          await stabiliser(tester);
          expect(lieu(routeur), chemin, reason: libelle);
          expect(
            tester.widget<NavShell>(find.byType(NavShell)).indexActif,
            index,
            reason: libelle,
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
      testWidgets('les 4 destinations se tapent, ${taille.width.toInt()}', (
        WidgetTester tester,
      ) async {
        await monter(tester, taille);
        expect(find.byKey(forme), findsOneWidget);
        // On arrive sur Ma classe : le vrai Espace Classe.
        expect(find.byType(EspaceGroupePage), findsOneWidget);
        for (final (String libelle, int index) in <(String, int)>[
          (t.nav.eleve.accueil, 0),
          (t.nav.eleve.apprendre, 2),
          (t.nav.eleve.monEspace, 3),
          (t.nav.eleve.maClasse, 1),
        ]) {
          if (_auPied(forme, libelle)) {
            await _ouvrirParLePied(tester, libelle);
          } else {
            await tester.tap(_dans(forme, libelle));
          }
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
