// COM-F : ResponsiveWorkspaceShell (spec sections 20 et 23). Mesure a 390,
// 768 et 1440 : nombre de panneaux, panneau droit fermable puis reouvrable,
// aucune colonne vide (un panneau absent ou ferme rend sa place au contenu),
// une surface a la fois sur telephone, contexte en feuille quand il n'a pas
// de colonne.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/communications/espace_travail_adaptatif.dart';

import '../../support/hote_theme.dart';

const String _texteListe = 'Liste des fils';
const String _texteContenu = 'Fil ouvert';
const String _texteContexte = 'Classe An-Nour';

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  bool avecListe = true,
  bool avecContexte = true,
  SurfaceMobile surface = SurfaceMobile.principal,
  VoidCallback? onRetourListe,
  ValueChanged<bool>? onBascule,
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    hoteTheme(
      EspaceTravailAdaptatif(
        liste: avecListe ? const Center(child: Text(_texteListe)) : null,
        principal: const Center(child: Text(_texteContenu)),
        contexte: avecContexte
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[Text(_texteContexte)],
              )
            : null,
        surfaceMobile: surface,
        onRetourListe: onRetourListe,
        onContexteBascule: onBascule,
      ),
      defilant: false,
    ),
  );
  await tester.pumpAndSettle();
}

int _panneaux() => <Key>[
  EspaceTravailAdaptatif.cleListe,
  EspaceTravailAdaptatif.clePrincipal,
  EspaceTravailAdaptatif.cleContexte,
].where((Key k) => find.byKey(k).evaluate().isNotEmpty).length;

double _largeur(WidgetTester tester, Key cle) =>
    tester.getSize(find.byKey(cle)).width;

void main() {
  test('seuils derives des largeurs de panneaux', () {
    expect(colonnesPour(390), 1);
    expect(colonnesPour(768), 2);
    expect(colonnesPour(1440), 3);
    expect(colonnesPour(EspaceTravailAdaptatif.largeurDeuxColonnes - 1), 1);
    expect(colonnesPour(EspaceTravailAdaptatif.largeurTroisColonnes - 1), 2);
  });

  group('390 : une surface a la fois', () {
    testWidgets('le contenu seul, le contexte en feuille', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(390, 844));
      expect(_panneaux(), 1);
      expect(find.text(_texteContenu), findsOneWidget);
      expect(find.text(_texteListe), findsNothing);
      expect(find.text(_texteContexte), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(find.text(_texteContexte), findsOneWidget);
    });

    testWidgets('la liste seule quand elle est la surface demandee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(390, 844), surface: SurfaceMobile.liste);
      expect(_panneaux(), 1);
      expect(find.text(_texteListe), findsOneWidget);
      expect(find.text(_texteContenu), findsNothing);
    });

    testWidgets('retour explicite vers la liste', (WidgetTester tester) async {
      int retours = 0;
      await _monter(
        tester,
        const Size(390, 844),
        onRetourListe: () => retours++,
      );
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleRetourListe));
      expect(retours, 1);
    });

    testWidgets('ni liste ni contexte : aucune barre vide au-dessus', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(390, 844),
        avecListe: false,
        avecContexte: false,
      );
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsNothing,
      );
      expect(find.byKey(EspaceTravailAdaptatif.cleRetourListe), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(EspaceTravailAdaptatif.clePrincipal)).dy,
        tester.getTopLeft(find.byType(EspaceTravailAdaptatif)).dy,
      );
    });
  });

  group('768 : maitre-detail', () {
    testWidgets('liste + contenu, le contexte en feuille', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(768, 1024));
      expect(_panneaux(), 2);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(
        _largeur(tester, EspaceTravailAdaptatif.cleListe),
        EspaceTravailAdaptatif.largeurListe,
      );
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(find.text(_texteContexte), findsOneWidget);
    });

    testWidgets('sans liste : contenu + contexte, aucune colonne vide', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(768, 1024), avecListe: false);
      expect(_panneaux(), 2);
      expect(find.byKey(EspaceTravailAdaptatif.cleListe), findsNothing);
      expect(
        _largeur(tester, EspaceTravailAdaptatif.clePrincipal) +
            _largeur(tester, EspaceTravailAdaptatif.cleContexte),
        768,
      );
    });
  });

  group('1440 : liste, contenu, contexte', () {
    testWidgets('trois panneaux ; le contexte se ferme et se rouvre', (
      WidgetTester tester,
    ) async {
      final List<bool> bascules = <bool>[];
      await _monter(tester, const Size(1440, 900), onBascule: bascules.add);
      expect(_panneaux(), 3);
      expect(find.text(_texteContexte), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleFermerContexte));
      await tester.pumpAndSettle();
      expect(_panneaux(), 2);
      expect(find.text(_texteContexte), findsNothing);
      // Aucune colonne vide : le contenu prend la place du contexte.
      expect(
        _largeur(tester, EspaceTravailAdaptatif.clePrincipal),
        1440 - EspaceTravailAdaptatif.largeurListe,
      );

      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(_panneaux(), 3);
      expect(find.text(_texteContexte), findsOneWidget);
      expect(bascules, <bool>[false, true]);
    });

    testWidgets('sans contexte : deux colonnes, rien de reserve a droite', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(1440, 900), avecContexte: false);
      expect(_panneaux(), 2);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsNothing,
      );
      expect(
        tester.getTopRight(find.byKey(EspaceTravailAdaptatif.clePrincipal)).dx,
        1440,
      );
    });

    testWidgets('sans liste ni contexte : le contenu prend toute la largeur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(1440, 900),
        avecListe: false,
        avecContexte: false,
      );
      expect(_panneaux(), 1);
      expect(_largeur(tester, EspaceTravailAdaptatif.clePrincipal), 1440);
    });
  });
}
