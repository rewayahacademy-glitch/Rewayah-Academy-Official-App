// ONGLETS-1 (revue du directeur, 01/10/2026) : une rangee d'onglets qui
// defile ressemble a des diapositives. `SelecteurSection` est le seul
// composant de changement de section : jusqu'a quatre sections sur telephone
// = controle segmente, tout visible ; cinq et plus = menu deroulant ; en
// ligne sur grand ecran tant que ca tient ; jamais de defilement horizontal.
//
// Les mesures se font avec les vraies polices du depot : avec la police de
// test (carres de 1 em), aucun libelle ne tiendrait.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';

import '../../capture/outil_capture.dart';
import '../../support/hote_theme.dart' show fixerVue;

const List<String> _cinq = <String>[
  'Diagnostics',
  'Progression',
  'Évaluations',
  'Programmes',
  'Qualité',
];
const List<String> _quatre = <String>['Suivi', 'Notes', 'Bilan', 'Plan'];
const List<String> _trois = <String>['Suivi', 'Notes', 'Bilan'];
const List<String> _huit = <String>[
  'Un',
  'Deux',
  'Trois',
  'Quatre',
  'Cinq',
  'Six',
  'Sept',
  'Huit',
];

/// Pose le selecteur dans une page de [largeur] et rend la valeur choisie.
Future<List<int>> _monter(
  WidgetTester tester,
  List<String> libelles, {
  required double largeur,
  int valeur = 0,
  double echelleTexte = 1,
  Brightness luminosite = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) async {
  fixerVue(tester, Size(largeur, 800));
  final List<int> choix = <int>[];
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: SafeArea(
          child: Directionality(
            textDirection: direction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SelecteurSection<int>(
                  libelle: 'Sections de la page',
                  valeur: valeur,
                  sections: <Segment<int>>[
                    for (int i = 0; i < libelles.length; i++)
                      Segment<int>(valeur: i, libelle: libelles[i]),
                  ],
                  onChange: choix.add,
                ),
              ),
            ),
          ),
        ),
      ),
      echelleTexte: echelleTexte,
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
    ),
  );
  await tester.pump();
  return choix;
}

/// Aucun defilement horizontal dans le selecteur (le defaut du directeur).
void _sansDefilementHorizontal(WidgetTester tester) {
  final Finder defilables = find.descendant(
    of: find.byType(SelecteurSection<int>),
    matching: find.byType(Scrollable),
  );
  for (final Element e in defilables.evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    expect(
      etat.widget.axisDirection == AxisDirection.left ||
          etat.widget.axisDirection == AxisDirection.right,
      isFalse,
      reason: 'une rangee de sections ne defile jamais horizontalement',
    );
  }
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  group('decider (fonction pure)', () {
    test('quatre sections sur telephone : segmente complet', () {
      expect(
        SelecteurSection.decider(
          nombre: 4,
          largeur: 358,
          largeurLibelleMax: 40,
          largeurMotMax: 40,
        ),
        ModeSelecteurSection.segmenteComplet,
      );
    });
    test('cinq sections sur telephone : menu, meme si ca tiendrait', () {
      expect(
        SelecteurSection.decider(
          nombre: 5,
          largeur: 358,
          largeurLibelleMax: 10,
          largeurMotMax: 10,
        ),
        ModeSelecteurSection.menu,
      );
    });
    test('cinq sections qui tiennent sur grand ecran : en ligne', () {
      expect(
        SelecteurSection.decider(
          nombre: 5,
          largeur: 1200,
          largeurLibelleMax: 100,
          largeurMotMax: 100,
        ),
        ModeSelecteurSection.segmenteNaturel,
      );
    });
    test('huit sections : menu, partout', () {
      expect(
        SelecteurSection.decider(
          nombre: 8,
          largeur: 1440,
          largeurLibelleMax: 10,
          largeurMotMax: 10,
        ),
        ModeSelecteurSection.menu,
      );
    });
    test('un mot plus large que sa part : menu', () {
      expect(
        SelecteurSection.decider(
          nombre: 4,
          largeur: 320,
          largeurLibelleMax: 200,
          largeurMotMax: 120,
        ),
        ModeSelecteurSection.menu,
      );
    });
    test('seuil telephone = seuil tablette des jetons', () {
      expect(AppGabarit.seuilTablette, 600);
    });
  });

  group('quatre sections : controle segmente, tout visible', () {
    for (final double largeur in <double>[390, 375]) {
      testWidgets('${largeur.toInt()} px', (WidgetTester tester) async {
        await _monter(tester, _quatre, largeur: largeur);
        expect(find.byType(ControleSegmente<int>), findsOneWidget);
        expect(find.byType(MenuFiltre<int>), findsNothing);
        final List<Rect> cadres = <Rect>[
          for (final String l in _quatre) tester.getRect(find.text(l)),
        ];
        for (final Rect c in cadres) {
          expect(c.left, greaterThanOrEqualTo(0));
          expect(c.right, lessThanOrEqualTo(largeur));
          // Meme rangee : aucun libelle n'est cache plus loin.
          expect(c.center.dy, closeTo(cadres.first.center.dy, 1));
        }
        _sansDefilementHorizontal(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('trois sections courtes tiennent meme a 320 px', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _trois, largeur: 320);
      expect(find.byType(ControleSegmente<int>), findsOneWidget);
      for (final String l in _trois) {
        final Rect c = tester.getRect(find.text(l));
        expect(c.left, greaterThanOrEqualTo(0));
        expect(c.right, lessThanOrEqualTo(320));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'des libelles trop longs pour leur part : menu, jamais coupes',
      (WidgetTester tester) async {
        await _monter(tester, <String>[
          'Fonctionnalités',
          'Conservation',
          'Règles',
        ], largeur: 320);
        expect(find.byType(MenuFiltre<int>), findsOneWidget);
        // Fermee : la section courante seule, jamais coupee ni defilante.
        expect(find.text('Fonctionnalités'), findsOneWidget);
        expect(find.text('Règles'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('toucher une autre section rend sa valeur', (
      WidgetTester tester,
    ) async {
      final List<int> choix = await _monter(tester, _quatre, largeur: 390);
      await tester.tap(find.text('Notes'));
      await tester.pump();
      expect(choix, <int>[1]);
      // La section courante ne rappelle rien.
      await tester.tap(find.text('Suivi'));
      await tester.pump();
      expect(choix, <int>[1]);
    });
  });

  group('cinq sections sur telephone : menu deroulant', () {
    testWidgets('affiche la section courante, liste complete au toucher', (
      WidgetTester tester,
    ) async {
      final List<int> choix = await _monter(
        tester,
        _cinq,
        largeur: 390,
        valeur: 2,
      );
      expect(find.byType(MenuFiltre<int>), findsOneWidget);
      expect(find.byType(ControleSegmente<int>), findsNothing);
      // Fermee : seule la section courante se voit.
      expect(find.text('Évaluations'), findsOneWidget);
      expect(find.text('Diagnostics'), findsNothing);
      // Le bouton prend toute la largeur utile.
      final Rect bouton = tester.getRect(find.byType(MenuFiltre<int>));
      expect(bouton.width, closeTo(390 - 32, 1));

      await tester.tap(find.byType(MenuFiltre<int>));
      await tester.pumpAndSettle();
      for (final String l in _cinq) {
        expect(find.text(l), findsWidgets, reason: '$l absent de la liste');
      }
      await tester.tap(find.text('Qualité'));
      await tester.pumpAndSettle();
      expect(choix, <int>[4]);
      _sansDefilementHorizontal(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 px : le bouton ne deborde pas', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _cinq, largeur: 320);
      final Rect bouton = tester.getRect(find.byType(MenuFiltre<int>));
      expect(bouton.left, greaterThanOrEqualTo(0));
      expect(bouton.right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
    });
  });

  group('grand ecran : les sections restent en ligne si elles tiennent', () {
    testWidgets('1440 px, cinq sections, alignees au debut', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _cinq, largeur: 1440);
      expect(find.byType(ControleSegmente<int>), findsOneWidget);
      expect(find.byType(MenuFiltre<int>), findsNothing);
      final Rect piste = tester.getRect(find.byType(ControleSegmente<int>));
      expect(piste.left, closeTo(16, 1), reason: 'aligne au debut');
      expect(piste.width, lessThan(1440 - 32), reason: 'pas etale');
      final List<Rect> cadres = <Rect>[
        for (final String l in _cinq) tester.getRect(find.text(l)),
      ];
      for (final Rect c in cadres) {
        expect(c.center.dy, closeTo(cadres.first.center.dy, 1));
      }
      _sansDefilementHorizontal(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 px, huit sections : menu, la page est a signaler', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _huit, largeur: 1440);
      expect(find.byType(MenuFiltre<int>), findsOneWidget);
      expect(find.byType(ControleSegmente<int>), findsNothing);
    });
  });

  group('texte agrandi : jamais de debordement, jamais de defilement', () {
    for (final double echelle in <double>[1, 2]) {
      for (final double largeur in <double>[320, 1440]) {
        for (final List<String> libelles in <List<String>>[_quatre, _cinq]) {
          testWidgets('${libelles.length} sections, ${largeur.toInt()} px, '
              'texte x${echelle.toInt()}', (WidgetTester tester) async {
            await _monter(
              tester,
              libelles,
              largeur: largeur,
              echelleTexte: echelle,
            );
            expect(tester.takeException(), isNull);
            final Rect zone = tester.getRect(
              find.byType(SelecteurSection<int>),
            );
            expect(zone.left, greaterThanOrEqualTo(0));
            expect(zone.right, lessThanOrEqualTo(largeur + 1));
            _sansDefilementHorizontal(tester);
          });
        }
      }
    }
  });

  group('themes et sens d ecriture', () {
    testWidgets('sombre : segmente et menu rendus sans exception', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _quatre, largeur: 390, luminosite: Brightness.dark);
      expect(tester.takeException(), isNull);
      await _monter(tester, _cinq, largeur: 390, luminosite: Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL : la premiere section est a droite (segmente)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _quatre,
        largeur: 390,
        direction: TextDirection.rtl,
      );
      final double premiere = tester.getRect(find.text('Suivi')).center.dx;
      final double derniere = tester.getRect(find.text('Bilan')).center.dx;
      expect(premiere, greaterThan(derniere));
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL : grand ecran, piste alignee au debut (a droite)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _cinq, largeur: 1440, direction: TextDirection.rtl);
      final Rect piste = tester.getRect(find.byType(ControleSegmente<int>));
      expect(piste.right, closeTo(1440 - 16, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL : menu sans exception', (WidgetTester tester) async {
      await _monter(tester, _cinq, largeur: 390, direction: TextDirection.rtl);
      expect(find.byType(MenuFiltre<int>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
