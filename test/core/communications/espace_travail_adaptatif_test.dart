// COM-F : ResponsiveWorkspaceShell (spec sections 20 et 23). Mesure a 390,
// 768 et 1440, seul ET pose dans la vraie coquille (NavShell + PageShell) :
// nombre de panneaux, panneau droit fermable puis reouvrable, etat du contenu
// conserve quand le contexte se ferme ou que les colonnes changent,
// aucune colonne vide (un panneau absent ou ferme rend sa place au contenu),
// une surface a la fois sur telephone, contexte en feuille quand il n'a pas
// de colonne.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

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
  test('seuils tires de la grille unique d AppGabarit', () {
    expect(colonnesPour(390), 1);
    expect(colonnesPour(768), 2);
    expect(colonnesPour(1440), 3);
    expect(
      EspaceTravailAdaptatif.largeurDeuxColonnes,
      AppGabarit.seuilTablette,
    );
    expect(EspaceTravailAdaptatif.largeurTroisColonnes, AppGabarit.seuilEtendu);
    expect(colonnesPour(AppGabarit.seuilTablette - 1), 1);
    expect(colonnesPour(AppGabarit.seuilTablette), 2);
    expect(colonnesPour(AppGabarit.seuilEtendu - 1), 2);
    expect(colonnesPour(AppGabarit.seuilEtendu), 3);
    // Au plus bas de chaque classe, le contenu garde une vraie largeur.
    expect(
      AppGabarit.seuilTablette - EspaceTravailAdaptatif.largeurListe,
      greaterThanOrEqualTo(320),
    );
    expect(
      AppGabarit.seuilEtendu -
          EspaceTravailAdaptatif.largeurListe -
          EspaceTravailAdaptatif.largeurContexte,
      greaterThanOrEqualTo(320),
    );
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

  group('768 nu (surface seule) : maitre-detail', () {
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

  group('dans la vraie coquille (NavShell + PageShell)', () {
    Future<void> monterDansCoquille(WidgetTester tester, Size taille) async {
      fixerVue(tester, taille);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              home: Scaffold(
                body: NavShell(
                  destinations: destinationsPour(
                    role: AppRole.teacher,
                    mode: InterfaceMode.standard,
                  ),
                  indexActif: 0,
                  onAller: (String _) {},
                  child: const PageShell(
                    defilante: false,
                    actionsCoquille: false,
                    child: EspaceTravailAdaptatif(
                      liste: Center(child: Text(_texteListe)),
                      principal: Center(child: Text(_texteContenu)),
                      contexte: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[Text(_texteContexte)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    double recue(WidgetTester tester) =>
        tester.getSize(find.byType(EspaceTravailAdaptatif)).width;

    testWidgets('390 : une surface', (WidgetTester tester) async {
      await monterDansCoquille(tester, const Size(390, 844));
      expect(_panneaux(), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768 (rail + gouttieres) : le maitre-detail tient', (
      WidgetTester tester,
    ) async {
      await monterDansCoquille(tester, const Size(768, 1024));
      // Moins que la fenetre : le rail et les gouttieres sont deja pris.
      expect(recue(tester), lessThan(768));
      expect(colonnesPour(recue(tester)), 2);
      expect(_panneaux(), 2);
      expect(find.text(_texteListe), findsOneWidget);
      expect(find.text(_texteContenu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 (barre laterale + gouttieres) : trois panneaux', (
      WidgetTester tester,
    ) async {
      await monterDansCoquille(tester, const Size(1440, 900));
      expect(recue(tester), lessThan(1440));
      expect(_panneaux(), 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('l etat du contenu survit aux changements de disposition', () {
    Future<void> monterAvecChamp(WidgetTester tester, Size taille) async {
      fixerVue(tester, taille);
      await tester.pumpWidget(
        hoteTheme(
          const EspaceTravailAdaptatif(
            liste: Center(child: Text(_texteListe)),
            principal: Center(child: TextField(key: Key('brouillon'))),
            contexte: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[Text(_texteContexte)],
            ),
          ),
          defilant: false,
        ),
      );
      await tester.pumpAndSettle();
    }

    String brouillon(WidgetTester tester) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('brouillon')),
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;

    testWidgets('fermer puis rouvrir le contexte, puis passer de 1440 a 768 '
        'et a 390 : le brouillon reste', (WidgetTester tester) async {
      await monterAvecChamp(tester, const Size(1440, 900));
      await tester.enterText(
        find.byKey(const Key('brouillon')),
        'Salam alaykoum',
      );
      final State etat = tester.state(find.byType(EditableText));

      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleFermerContexte));
      await tester.pumpAndSettle();
      expect(_panneaux(), 2);
      expect(brouillon(tester), 'Salam alaykoum');

      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      await tester.pumpAndSettle();
      expect(_panneaux(), 3);
      expect(brouillon(tester), 'Salam alaykoum');

      fixerVue(tester, const Size(768, 1024));
      await tester.pumpAndSettle();
      expect(_panneaux(), 2);
      expect(brouillon(tester), 'Salam alaykoum');

      fixerVue(tester, const Size(390, 844));
      await tester.pumpAndSettle();
      expect(_panneaux(), 1);
      expect(brouillon(tester), 'Salam alaykoum');
      // Le meme etat, pas un etat recree avec le meme texte.
      expect(tester.state(find.byType(EditableText)), same(etat));
      expect(tester.takeException(), isNull);
    });
  });
}
