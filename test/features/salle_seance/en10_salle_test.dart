// EN-10 : la salle B cote enseignant. Teaching Dock compact raccorde a
// `/salle` (Supports, Micro, Camera, Partager, « Ouvrir les outils
// d'enseignement »), camera jamais allumee seule, selecteur de ressources
// (Recents, Cette Classe, Tous les supports, recherche) qui ne quitte pas la
// salle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/libelles_salle_b.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/selecteur_ressources.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/teaching_dock.dart';

import '../../capture/outil_capture.dart';

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
  await tester.tap(_cle('bouton-supports'));
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
      testWidgets('le dock compact est present sur la salle', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        expect(tester.takeException(), isNull);
        expect(find.byType(SalleSeance), findsOneWidget);
        expect(_cle('bouton-supports'), findsOneWidget);
        expect(_cle('dock-partager'), findsOneWidget);
        expect(_cle('dock-outils'), findsOneWidget);
        expect(find.text(t.salle.micro), findsWidgets);
        expect(find.text(t.salle.camera), findsWidgets);
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(LibellesSalleB.ouvrirOutils)),
          ),
          findsOneWidget,
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
        expect(find.text(LibellesSalleB.cetteClasse), findsOneWidget);
        expect(
          find.text(t.tc.bibliotheque.sections.tousLesSupports),
          findsOneWidget,
        );
        // Recents : les supports ouverts recemment.
        expect(find.text('Fiche de mémorisation'), findsOneWidget);
        expect(find.text('Bibliothèque An-Nour'), findsNothing);
        // Cette Classe.
        await tester.tap(_cle('onglet-cetteClasse'));
        await tester.pump();
        expect(find.text('Bibliothèque An-Nour'), findsOneWidget);
        expect(find.text('Fiche de mémorisation'), findsNothing);
        // Tous les supports.
        await tester.tap(_cle('onglet-tous'));
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
        expect(_cle('bouton-supports'), findsOneWidget);
      });

      testWidgets('ouvrir les outils : le Teaching Dock, salle ouverte', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        await tester.tap(_cle('dock-outils'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(find.byType(TeachingDock), findsOneWidget);
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
}
