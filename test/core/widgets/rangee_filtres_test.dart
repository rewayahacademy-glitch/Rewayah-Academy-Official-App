// FILTRES-1 : le composant `RangeeFiltres` seul. Une rangee, des puces de
// meme hauteur, une barre de defilement des qu'elle deborde (et seulement
// alors), un libelle trop long qui passe a la ligne entre ses mots, un mot
// plus large que la rangee jamais coupe, le debut au debut du sens de lecture.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/sens_et_echelle.dart';

Future<void> _monter(
  WidgetTester tester,
  List<String> libelles, {
  int? retenue,
  double largeur = 320,
  double echelle = 2,
  TextDirection sens = TextDirection.ltr,
  Brightness eclairage = Brightness.light,
}) async {
  tester.view.physicalSize = Size(largeur, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, eclairage),
      builder: sensEtEchelle(direction: sens, echelle: echelle),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RangeeFiltres(
                filtres: <Widget>[
                  for (final String l in libelles)
                    FilterPill(
                      libelle: l,
                      compteur: 3,
                      retenue: libelles.indexOf(l) == retenue,
                      onPress: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Rect> _boites(WidgetTester tester) => <Rect>[
  for (final Element e in find.byType(FilterPill).evaluate())
    tester.getRect(find.byWidget(e.widget)),
];

RawScrollbar _barre(WidgetTester tester) => tester.widget<RawScrollbar>(
  find.descendant(
    of: find.byType(RangeeFiltres),
    matching: find.byType(RawScrollbar),
  ),
);

bool _barreVisible(WidgetTester tester) => _barre(tester).thumbVisibility!;

/// La largeur du fondu de bord de la rangee.
const double _fonduBord = AppSpacing.xxl;

/// Verifie l'ouverture d'une rangee de 16 a 304 (gouttiere de 16) : la puce
/// retenue entiere, hors des fondus ; aucune puce coupee au debut de la vue
/// au-dela du fondu (le debut reste lisible).
void _verifierOuverture(WidgetTester tester, int retenue, TextDirection sens) {
  const double debutVue = 16;
  const double finVue = 304;
  final List<Rect> b = _boites(tester);
  final Rect r = b[retenue];
  expect(r.left, greaterThanOrEqualTo(debutVue - 0.5), reason: '$b');
  expect(r.right, lessThanOrEqualTo(finVue + 0.5), reason: '$b');
  for (final Rect p in b) {
    // La part visible d'une puce a cheval sur le debut de la vue.
    final double visible = sens == TextDirection.ltr
        ? (p.left < debutVue - 0.5 ? p.right - debutVue : 0)
        : (p.right > finVue + 0.5 ? finVue - p.left : 0);
    expect(
      visible,
      lessThanOrEqualTo(_fonduBord + 0.5),
      reason: 'une puce coupee au debut de la vue : $b',
    );
  }
}

/// Vrai quand un bord de la rangee s'efface.
bool _fondu(WidgetTester tester) =>
    tester
        .widget<ShaderMask>(
          find.descendant(
            of: find.byType(RangeeFiltres),
            matching: find.byType(ShaderMask),
          ),
        )
        .blendMode ==
    BlendMode.dstIn;

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('tout tient : une rangee, aucune barre de defilement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>['Tous', 'Actif'], largeur: 1440, echelle: 1);
    final List<Rect> b = _boites(tester);
    expect(b[0].top, b[1].top);
    expect(_barreVisible(tester), isFalse);
    // Rien de cache : aucun fondu de bord.
    expect(_fondu(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ca deborde : une rangee, la barre de defilement se voit', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>[
      'Tous',
      'En attente',
      'Actif',
      'Provisoire',
      'Suspendu',
    ]);
    final List<Rect> b = _boites(tester);
    for (final Rect r in b) {
      expect(r.top, b.first.top);
      expect(r.height, b.first.height);
    }
    expect(_barreVisible(tester), isTrue);
    // Des puces cachees apres la fin : le bord de fin s'efface.
    expect(_fondu(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un libelle plus long que la rangee passe a la ligne entre ses '
      'mots ; toutes les puces prennent sa hauteur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>[
      'Toutes les classes de la semaine',
      'Actif',
    ]);
    final List<Rect> b = _boites(tester);
    // Jamais plus large que la rangee (320 - 2 x 16).
    expect(b[0].width, lessThanOrEqualTo(288));
    expect(b[1].height, b[0].height);
    verifierAucunMotCoupe(tester, find.byType(RangeeFiltres));
    expect(tester.takeException(), isNull);
  });

  testWidgets('un mot plus large que la rangee elargit sa puce, sans coupure', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>['Anticonstitutionnellement', 'Actif']);
    expect(_boites(tester)[0].width, greaterThan(288));
    verifierAucunMotCoupe(tester, find.byType(RangeeFiltres));
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL : la rangee commence a droite', (WidgetTester tester) async {
    await _monter(tester, <String>[
      'Tous',
      'En attente',
      'Actif',
      'Provisoire',
    ], sens: TextDirection.rtl);
    final List<Rect> b = _boites(tester);
    expect(b.first.right, 304);
    expect(b[1].right, lessThan(b.first.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('le filtre retenu, loin dans la rangee, se voit a l ouverture', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>[
      'Tous',
      'En attente',
      'Actif',
      'Provisoire',
      'Suspendu',
    ], retenue: 4);
    final Rect r = _boites(tester).last;
    expect(r.left, greaterThanOrEqualTo(16));
    expect(r.right, lessThanOrEqualTo(304));
    expect(tester.takeException(), isNull);
  });

  // FILTRES-1b (2) : la barre de defilement ne se lit pas comme le
  // soulignement d'un onglet actif : piste visible sur toute la largeur,
  // curseur et piste neutres, jamais l'accent.
  testWidgets('la barre de defilement est neutre, avec sa piste', (
    WidgetTester tester,
  ) async {
    for (final Brightness eclairage in Brightness.values) {
      await _monter(
        tester,
        <String>['Tous', 'En attente', 'Actif', 'Provisoire', 'Suspendu'],
        retenue: 0,
        eclairage: eclairage,
      );
      final RawScrollbar barre = _barre(tester);
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(RangeeFiltres)),
      );
      final ColorScheme schema = Theme.of(
        tester.element(find.byType(RangeeFiltres)),
      ).colorScheme;
      expect(barre.trackVisibility, isTrue);
      expect(barre.thumbColor, palette.borderStrong.asBorderSide().color);
      expect(barre.trackColor, palette.borderHairline.asBorderSide().color);
      for (final Color accent in <Color>[
        schema.primary,
        palette.inkAccent.asBorderSide().color,
      ]) {
        expect(barre.thumbColor, isNot(accent));
      }
      // Fine : moins haute que l'ecart qui la separe des puces.
      expect(barre.thickness, lessThan(AppSpacing.md));
      expect(tester.takeException(), isNull);
    }
  });

  // FILTRES-1b (3) : le filtre retenu n'est pas le premier ; a l'ouverture,
  // il se voit entier ET le debut de la vue reste lisible (aucune puce
  // coupee au milieu de son libelle au debut de la rangee). La derniere
  // puce retenue met la rangee en butee : la vue finit alors sur elle et
  // son debut tombe ou il tombe (cas couvert plus haut : elle se voit).
  for (final TextDirection sens in TextDirection.values) {
    for (final int retenue in <int>[1, 2, 3]) {
      testWidgets('ouverture, filtre retenu n$retenue en ${sens.name} : le '
          'debut reste lisible', (WidgetTester tester) async {
        await _monter(
          tester,
          <String>['Toutes', 'Ouvertes', 'Traitees', 'Provisoire', 'Suspendu'],
          retenue: retenue,
          sens: sens,
        );
        _verifierOuverture(tester, retenue, sens);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
