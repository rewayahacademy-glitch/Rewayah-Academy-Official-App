// EN-10 : la salle B cote enseignant. Camera jamais allumee seule,
// selecteur de ressources (Recents, Cette Classe, Tous les supports,
// recherche) qui ne quitte pas la salle. TB-4 (CMD-01) : la barre de l'appel
// est Micro, Camera, Quitter ; Supports devient la Bibliotheque des
// Commandes, les outils leur onglet « Outils », Partager n'est pas repris.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/libelles_salle_b.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/selecteur_ressources.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/selecteur_section.dart';

Future<void> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      SalleDemo(
        role: RoleSeance.enseignant,
        etat: EtatDemoSalle.repos,
        onSortir: () {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _ouvrirSelecteur(WidgetTester tester) async {
  // TB-4 : Commandes, puis la Bibliotheque, premiere entree du panneau.
  await tester.tap(find.byKey(DeclencheurCommandes.cle));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byKey(CommandesPedagogiques.cleBibliotheque));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  // Le panneau Supports (CLV-08), puis « Voir toute la bibliotheque »
  // (bureau) ou « Voir tout » (feuille et volet).
  final Finder bureau = find.text(
    t.salle.seance.panneauSupports.voirBibliotheque,
  );
  final Finder voirTout = bureau.evaluate().isNotEmpty
      ? bureau
      : find.text(t.salle.seance.panneauSupports.voirTout).last;
  await tester.ensureVisible(voirTout);
  await tester.tap(voirTout);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  for (final (String nom, Size taille) in <(String, Size)>[
    ('mobile', const Size(390, 844)),
    ('tablette', const Size(768, 1024)),
    ('bureau', const Size(1440, 900)),
  ]) {
    group('EN-10 $nom', () {
      testWidgets('barre de l appel et declencheur Commandes (TB-4)', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        expect(tester.takeException(), isNull);
        expect(find.byType(SalleSeance), findsOneWidget);
        expect(find.byKey(DeclencheurCommandes.cle), findsOneWidget);
        expect(_cle('bouton-supports'), findsNothing);
        expect(_cle('dock-partager'), findsNothing);
        expect(_cle('dock-outils'), findsNothing);
        // EN-12 (17 d) : dock serre, icone seule ; le libelle reste lu.
        expect(
          find.bySemanticsLabel(
            RegExp(
              '${RegExp.escape(t.salle.fermerMicro)}|'
              '${RegExp.escape(t.salle.ouvrirMicro)}',
            ),
          ),
          findsWidgets,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(
              '${RegExp.escape(t.salle.fermerCamera)}|'
              '${RegExp.escape(t.salle.ouvrirCamera)}',
            ),
          ),
          findsWidgets,
        );
        expect(find.text('IndicateurEleve'), findsNothing);
      });

      testWidgets('la camera ne s allume jamais seule', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(t.salle.ouvrirCamera))),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(t.salle.fermerCamera))),
          findsNothing,
        );
        // Ouvrir le selecteur ou les outils n'allume rien.
        await _ouvrirSelecteur(tester);
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(t.salle.fermerCamera))),
          findsNothing,
        );
      });

      testWidgets('selecteur : trois onglets, recherche, la salle reste', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        await _ouvrirSelecteur(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(SelecteurRessources), findsOneWidget);
        expect(find.text(t.tc.bibliotheque.sections.recents), findsOneWidget);
        // Les trois sections sont un seul selecteur (segmente, ou menu quand
        // les libelles ne tiennent pas) : jamais une rangee qui defile. Les
        // deux autres sont atteintes par `choisirSection` plus bas.
        expect(selecteurSection, findsOneWidget);
        // Recents : les supports ouverts recemment.
        expect(find.text('Fiche de mémorisation'), findsOneWidget);
        expect(find.text('Bibliothèque An-Nour'), findsNothing);
        // Cette Classe.
        await choisirSection(tester, LibellesSalleB.cetteClasse);
        await tester.pump();
        expect(find.text('Bibliothèque An-Nour'), findsOneWidget);
        expect(find.text('Fiche de mémorisation'), findsNothing);
        // Tous les supports.
        await choisirSection(
          tester,
          t.tc.bibliotheque.sections.tousLesSupports,
        );
        await tester.pump();
        expect(find.text('Bibliothèque An-Nour'), findsOneWidget);
        expect(find.text('Fiche de mémorisation'), findsOneWidget);
        // Recherche.
        await tester.enterText(_cle('recherche-ressources'), 'exercices');
        await tester.pump();
        expect(find.text('Exercices – Chapitre 1'), findsOneWidget);
        expect(find.text('Fiche de mémorisation'), findsNothing);
        await tester.enterText(_cle('recherche-ressources'), 'zzz');
        await tester.pump();
        expect(
          find.text(t.tc.bibliotheque.aucunResultat.message),
          findsOneWidget,
        );
        // Choisir une ressource : la salle reste ouverte.
        await tester.enterText(_cle('recherche-ressources'), '');
        await tester.pump();
        await tester.tap(_cle('ressource-demo-fiche-memorisation'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(find.byType(SalleSeance), findsOneWidget);
        expect(find.byKey(DeclencheurCommandes.cle), findsOneWidget);
      });

      testWidgets('ouvrir les outils : onglet Outils, salle ouverte', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        await tester.tap(find.byKey(DeclencheurCommandes.cle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(
          find.descendant(
            of: find.byKey(CommandesPedagogiques.cleOnglets),
            matching: find.text(t.salle.seance.commandes.ongletOutils),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(_cle('outil-pointeur'), findsOneWidget);
        expect(find.byType(SalleSeance), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(t.salle.fermerCamera))),
          findsNothing,
        );
      });
    });
  }

  group('Capture : EN-10', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String theme = mode == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('en10 $nom $theme', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              SalleDemo(
                role: RoleSeance.enseignant,
                etat: EtatDemoSalle.repos,
                onSortir: () {},
              ),
              themeMode: mode,
            ),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'en10_salle_${nom}_$theme')}',
          );
          await _ouvrirSelecteur(tester);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'en10_selecteur_${nom}_$theme')}',
          );
        });
      }
    }
  });

  // UX_REVIEW_04 n. 17 d, WCAG 1.4.10 : a 320, chaque disque du dock garde
  // la cible tactile, sans chevauchement ni debordement.
  testWidgets('EN-RC : a 320 x 640, chaque bouton du dock fait au moins 48', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
    final Finder boutons = find.descendant(
      of: _cle('dock-seance'),
      matching: find.byType(BoutonAppel),
    );
    expect(boutons, findsWidgets);
    final List<Rect> cases = <Rect>[
      for (final Element e in boutons.evaluate())
        tester.getRect(find.byWidget(e.widget)),
    ];
    for (final Rect r in cases) {
      expect(r.width, greaterThanOrEqualTo(48));
      expect(r.height, greaterThanOrEqualTo(48));
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    }
    for (int i = 0; i < cases.length; i++) {
      for (int j = i + 1; j < cases.length; j++) {
        expect(cases[i].overlaps(cases[j]), isFalse);
      }
    }
  });

  // UX_REVIEW_04 n. 17 f : une ressource choisie, le focus va au support, pas
  // au bouton Supports.
  testWidgets('EN-RC : une ressource choisie, le focus va au support', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    await _ouvrirSelecteur(tester);
    await tester.tap(_cle('ressource-demo-fiche-memorisation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'support');
  });
}
